/**
 * File              : Item.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 24.08.2023
 * Last Modified Date: 13.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "Item.h"
#include "UIKit/UIKit.h"
#include "stdbool.h"
#include "AVFoundation/AVFoundation.h"
#include "Foundation/Foundation.h"
#include <string.h>
#import "../cYandexMusic/cYandexMusic.h"

@implementation Item
- (id)init
{
	if (self = [super init]) {
		self.coverImage = NULL;
		[self setItemId:@"undefined"];
		self.subtitle = @"";
		self.albumTitle = @"";
		self.hasAtrImage = NO;
		self.hasDownloadURL = false;
		self.hasFile = false;
		self.albumId = 0;
		self.prepareDownloadURL = [[NSOperationQueue alloc]init];
		self.downloadFile = [[NSOperationQueue alloc]init];
		self.prepareImage = [[NSOperationQueue alloc]init];
		NSFileManager *fm = NSFileManager.defaultManager;
		self.thumbmailsCache = 
				[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) 
						objectAtIndex:0] stringByAppendingPathComponent:@"thumbnails"];
		[fm createDirectoryAtPath:self.thumbmailsCache attributes:nil];
		self.imagesCache = 
				[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) 
						objectAtIndex:0] stringByAppendingPathComponent:@"images"];
		[fm createDirectoryAtPath:self.imagesCache attributes:nil];
		self.tracksCache = 
				[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) 
						objectAtIndex:0] stringByAppendingPathComponent:@"tracks"];
		[fm createDirectoryAtPath:self.tracksCache attributes:nil];
	}
	return self;
}
-(id)initWithTrack:(struct track *)track token:(NSString *)token{
	if (self = [self init]){
		self.token = token;
		if (track->realId)
			[self setItemId:
				[NSString stringWithUTF8String:track->realId]];
		else
			[self setItemId:
				[NSString stringWithUTF8String:track->id]];

		if (track->type)
		{
			if (strcmp(track->type, "track") == 0)
				self.itemType = ITEM_TRACK;
			else if (strcmp(track->type, "podcast-episode") == 0)
				self.itemType = ITEM_PODCAST_EPOSODE;
			else if (strcmp(track->type, "podcast") == 0)
				self.itemType = ITEM_PODCAST;
			else if (strcmp(track->type, "album") == 0)
				self.itemType = ITEM_ALBUM;
		}
		if (track->title)
			[self setTitle:[NSString stringWithUTF8String:track->title]];
		if (track->coverUri){
			self.coverUri = [NSURL URLWithString:[NSString stringWithUTF8String:track->coverUri]];
			// Update your UI
			[self downloadSmallImage];
		}
		if (track->artists){
			int i;
			char artists[BUFSIZ] = "";
			for (i=0;i<track->n_artists;i++){
				artist_t artist = track->artists[i];
				char *name = artist.name;
				if (name){
					strcat(artists, name);
					if (i != track->n_artists - 1)
						strcat(artists, ", ");
				}
			}
			self.subtitle = [NSString stringWithUTF8String:artists];
		}
		if (track->albums){
			if (track->albums[0].title){
				self.albumTitle = [NSString stringWithUTF8String:track->albums[0].title];
			}
				self.albumId = track->albums[0].id;
		}
	}

	return self;
}

-(id)initWithPlaylist:(playlist_t *)playlist token:(NSString *)token{
	if (self = [self init]){
		self.token = token;
		self.itemType = ITEM_PLAYLIST;
		self.uid   = playlist->uid;
		self.kind  = playlist->kind;	
		self.itemId = [NSString stringWithFormat:@"%ld_%ld", self.uid, self.kind];
		if (playlist->title)
			self.title = [NSString stringWithUTF8String:playlist->title]; 
		if (playlist->description)
			self.subtitle = [NSString stringWithUTF8String:playlist->description]; 
		if (playlist->ogImage){
			self.coverUri = [NSURL URLWithString:[NSString stringWithUTF8String:playlist->ogImage]];
			// Update your UI
			[self downloadSmallImage];
		}
	}

	return self;
}

-(id)initWithAlbum:(album_t *)album token:(NSString *)token{
	if (self = [self init]){
		[self setItemId:
			[NSString stringWithUTF8String:album->realId]];
		self.token = token;
		self.itemType = ITEM_ALBUM;
		self.subtitle = @"";
		if (strcmp(album->type, "podcast") == 0)
			self.itemType = ITEM_PODCAST;
		if (album->title)
			self.title = [NSString stringWithUTF8String:album->title]; 
		if (album->artists){
			int i;
			char artists[BUFSIZ] = "";
			for (i=0;i<album->n_artists;i++){
				artist_t artist = album->artists[i];
				char *name = artist.name;
				if (name){
					strcat(artists, name);
					if (i != album->n_artists - 1)
						strcat(artists, ", ");
				}
			}
			self.subtitle = [NSString stringWithUTF8String:artists];
		}

		if (album->coverUri){
			self.coverUri = [NSURL URLWithString:[NSString stringWithUTF8String:album->coverUri]];
			// Update your UI
			[self downloadSmallImage];
		}
	}

	return self;
}

- (void)downloadSmallImage{
		NSString *filepath = [self.thumbmailsCache 
				stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", self.itemId]];
		// check if file exists
		if ([[NSFileManager defaultManager] fileExistsAtPath:filepath]){
			dispatch_sync(dispatch_get_main_queue(), ^{
				self.coverImage = [UIImage imageWithContentsOfFile:filepath];
				if (self.imageView)
					[self.imageView setImage:self.coverImage];
			});
		} else {
			NSOperationQueue *operation = [[NSOperationQueue alloc]init];
			[operation addOperationWithBlock:^{
				NSData *data = [NSData dataWithContentsOfURL:self.coverUri];
				[data writeToFile:filepath atomically:YES];
				dispatch_sync(dispatch_get_main_queue(), ^{
					self.coverImage = [UIImage imageWithData:data];
					if (self.imageView)
						[self.imageView setImage:self.coverImage];
				});
			}];
		}
}

static int get_track_with_image(void *data, track_t *track, const char *error){
	Item *self = (__bridge Item *)data;
	if (error){
		NSLog(@"%s", error);
		return 0;
	}
	if (track){
			NSURL *url = [NSURL URLWithString:[NSString stringWithUTF8String:track->coverUri]]; 
			NSData *data = [NSData dataWithContentsOfURL:url];
			// save image to cache
			[data writeToFile:self.artImageURL.path atomically:true];
		dispatch_sync(dispatch_get_main_queue(), ^{
				self.artImage = [UIImage imageWithData:data];
				self.hasAtrImage = YES;
				if (self.onImageReady)
					self.onImageReady(self);
		});
	}
	return 0;
}

static int get_file_url(void *data, const char *url_str, const char *error){
	Item *self = (__bridge Item *)data;
	if (error){
		NSLog(@"%s", error);
		return 0;
	}
	if (url_str){
		NSURL *url = [NSURL URLWithString:[NSString stringWithUTF8String:url_str]];
		self.downloadURL = url;
		dispatch_sync(dispatch_get_main_queue(), ^{
			self.hasDownloadURL = YES;
			if (self.onDownloadURLReady)
				self.onDownloadURLReady(self);	
		});
		return 1;
	}
	return 0;
}

-(void)prepareDownloadURL:(void (^) (Item *item))onDownloadURLReady{
	self.onDownloadURLReady = onDownloadURLReady;
	
	// prepare file
	NSString *filepath = [self.tracksCache stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3", self.itemId]];
	NSURL *url = [NSURL fileURLWithPath:filepath]; 
	// check if file exists
	if ([[NSFileManager defaultManager] fileExistsAtPath:filepath]){
		self.downloadURL = url;
		[self setHasFile:YES];
		[self setHasDownloadURL:YES];
		//self.playerItem = [AVPlayerItem playerItemWithURL:self.fileURL];
		if (onDownloadURLReady)
			onDownloadURLReady(self);
	} else {
		// dowload file
		[self.downloadFile cancelAllOperations];
		[self.prepareDownloadURL cancelAllOperations];
		[self.prepareDownloadURL addOperationWithBlock:^{
				c_yandex_music_get_download_url(
						[self.token UTF8String], [self.itemId UTF8String], 
						(__bridge void *)self, get_file_url);
		}];
	}
}

-(void)downloadFile:(void (^) (Item *item))onFileReady{
	self.onFileReady = onFileReady;
	
	// prepare file
	NSString *filepath = [self.tracksCache stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3", self.itemId]];
	NSURL *url = [NSURL fileURLWithPath:filepath]; 
	// check if file exists
	if ([[NSFileManager defaultManager] fileExistsAtPath:filepath]){
		self.downloadURL = url;
		[self setHasFile:YES];
		[self setHasDownloadURL:YES];
		//self.playerItem = [AVPlayerItem playerItemWithURL:self.fileURL];
		if (onFileReady)
			onFileReady(self);
	} else {
		// get dowload url
		[self prepareDownloadURL:^(Item *item){
			[self.downloadFile cancelAllOperations];
			[self.downloadFile addOperationWithBlock:^{
				NSData *data = [NSData dataWithContentsOfURL:item.downloadURL];
				[data writeToURL:url atomically:YES];
				dispatch_sync(dispatch_get_main_queue(), ^{
					self.hasFile = YES;
					self.hasDownloadURL = YES;
					self.downloadURL = url;
					if (onFileReady)
						onFileReady(self);	
				});
			}];
		}];
	}
}

-(void)prepareImage:(void (^)(Item *item))onImageReady{
	self.onImageReady = onImageReady;
	
	// prepare file
	NSString *filepath = [self.imagesCache stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", self.itemId]];
	self.artImageURL = [NSURL fileURLWithPath:filepath]; 
	// check if file exists
	if ([[NSFileManager defaultManager] fileExistsAtPath:filepath]){
		self.artImage = [UIImage imageWithContentsOfFile:self.artImageURL.path];
		if (self.onImageReady)
			self.onImageReady(self);
	} else {
		// download image
		[self.prepareImage cancelAllOperations];
		[self.prepareImage addOperationWithBlock:^{
			c_yandex_music_get_track_by_id(
					[self.token UTF8String], 
					NULL, 
					[self.itemId UTF8String], 
					(__bridge void *)self, 
					get_track_with_image);
		}];
	}
}

#pragma mark <NSCoding Protocol>
- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.token forKey:kToken];
	[aCoder encodeObject:self.itemId forKey:kItemId];
	[aCoder encodeInteger:self.itemType forKey:kItemType];
	[aCoder encodeObject:self.title forKey:kTitle];
	[aCoder encodeObject:self.subtitle forKey:kSubtitle];
	[aCoder encodeObject:self.albumTitle forKey:kAlbumTitle];
	[aCoder encodeInteger:self.albumId forKey:kAlbumId];
	[aCoder encodeInteger:self.uid forKey:kUID];
	[aCoder encodeInteger:self.kind forKey:kKind];
	[aCoder encodeObject:self.coverUri forKey:kCoverUri];
	[aCoder encodeObject:self.downloadURL forKey:kDownloadURL];
	[aCoder encodeBool:self.hasDownloadURL forKey:kHasDownloadURL];
	[aCoder encodeBool:self.hasFile forKey:kHasFile];
	[aCoder encodeObject:self.coverImage forKey:kCoverImage];
	[aCoder encodeObject:self.artImageURL forKey:kArtImageURL];
	[aCoder encodeBool:self.hasAtrImage forKey:kHasArtImage];
}

- (id)initWithToken:(NSString *)token
							itemId:(NSString *)itemId
						itemType:(NSInteger)itemType
							 title:(NSString *)title
						subtitle:(NSString *)subtitle
					albumTitle:(NSString *)albumTitle
						 albumId:(NSInteger)albumId
								 uid:(NSInteger)uid
								kind:(NSInteger)kind
						coverUri:(NSURL *)coverUri
				 downloadURL:(NSURL *)downloadURL
			hasDownloadURL:(BOOL)hasDownloadURL
						 hasFile:(BOOL)hasFile
					coverImage:(UIImage *)coverImage
				 artImageURL:(NSURL *)artImageURL
				 hasArtImage:(BOOL)hasArtImage
{
	if (self = [super init]) {
		self.token = token;
		self.itemId = itemId;
		self.itemType = itemType;
		self.title = title;
		self.subtitle = subtitle;
		self.albumTitle = albumTitle;
		self.albumId = albumId;
		self.uid = uid;
		self.kind = kind;
		self.coverUri = coverUri;
		self.downloadURL = downloadURL;
		self.hasDownloadURL = hasDownloadURL;
		self.hasFile = hasFile;
		self.coverImage = coverImage;
		self.artImageURL = artImageURL;
		self.hasAtrImage = hasArtImage;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	return [self 
		initWithToken: [aDecoder decodeObjectForKey:kToken]
					 itemId: [aDecoder decodeObjectForKey:kItemId]
				 itemType: [aDecoder decodeIntegerForKey:kItemType]
						title: [aDecoder decodeObjectForKey:kTitle]
				 subtitle: [aDecoder decodeObjectForKey:kSubtitle]
			 albumTitle: [aDecoder decodeObjectForKey:kAlbumTitle]
					albumId: [aDecoder decodeIntegerForKey:kAlbumId]
							uid: [aDecoder decodeIntegerForKey:kUID]
						 kind: [aDecoder decodeIntegerForKey:kKind]
				 coverUri: [aDecoder decodeObjectForKey:kCoverUri]
			downloadURL: [aDecoder decodeObjectForKey:kDownloadURL]
	 hasDownloadURL: [aDecoder decodeBoolForKey:kHasDownloadURL]
					hasFile: [aDecoder decodeBoolForKey:kHasFile]
			 coverImage: [aDecoder decodeObjectForKey:kCoverImage]
			artImageURL: [aDecoder decodeObjectForKey:kArtImageURL]
			hasArtImage: [aDecoder decodeBoolForKey:kHasArtImage]
	];
}

@end
// vim:ft=objc
