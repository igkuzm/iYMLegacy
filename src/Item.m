/**
 * File              : Item.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 24.08.2023
 * Last Modified Date: 27.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "Item.h"
#include "Foundation/Foundation.h"
#include <string.h>
#import "../cYandexMusic/cYandexMusic.h"

@implementation Item
- (id)init
{
	if (self = [super init]) {
		self.coverImage = NULL;
		[self setItemId:@"undefined"];
		self.subtitle = [[NSString alloc]initWithString:@""];
	}
	return self;
}
-(id)initWithTrack:(struct track *)track token:(NSString *)token{
	if (self = [self init]){
		self.token = token;
		if (track->realId)
			[self setItemId:
				[NSString stringWithUTF8String:track->realId]];
		if (track->type)
		{
			if (strcmp(track->type, "track") == 0)
				self.itemType = ITEM_TRACK;
			else if (strcmp(track->type, "podcast_episode") == 0)
				self.itemType = ITEM_PODCAST_EPOSODE;
			else if (strcmp(track->type, "podcast") == 0)
				self.itemType = ITEM_PODCAST;
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
	}

	return self;
}

-(id)initWithPlaylist:(playlist_t *)playlist token:(NSString *)token{
	if (self = [self init]){
		self.token = token;
		self.itemType = ITEM_PLAYLIST;
		self.uid   = playlist->uid;
		self.kind  = playlist->kind;	
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

- (void)downloadSmallImage{
		NSString *filepath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@small.png", self.itemId]];
		NSURL *fileurl = [NSURL fileURLWithPath:filepath]; 
		// check if file exists
		if ([[NSFileManager defaultManager] fileExistsAtPath:self.fileURL.path]){
				self.coverImage = [UIImage imageWithContentsOfFile:self.artImageURL.path];
				if (self.imageView)
					[self.imageView setImage:self.coverImage];
		} else {
			NSOperationQueue *operation = [[NSOperationQueue alloc]init];
			[operation addOperationWithBlock:^{
				NSData *data = [NSData dataWithContentsOfURL:self.coverUri];
				self.coverImage = [UIImage imageWithData:data];
				if (self.imageView)
					[self.imageView setImage:self.coverImage];
			}];
		}
}

static int get_track_with_image(void *data, track_t *track, const char *error){
	Item *self = (__bridge Item *)data;
	if (error)
		return 0;
	if (track){
		Item *t = [[Item alloc]initWithTrack:track token:self.token];
		self.artImage = t.coverImage;
		dispatch_sync(dispatch_get_main_queue(), ^{
				// save image to cache
				[UIImagePNGRepresentation(self.artImage) writeToURL:self.artImageURL atomically:true];
				if (self.onImageReady)
					self.onImageReady(self);
		});
	}
}

static int get_file_url(void *data, const char *url_str, const char *error){
	Item *self = (__bridge Item *)data;
	if (error)
		return 0;
	if (url_str){
		NSURL *url = [NSURL URLWithString:[NSString stringWithUTF8String:url_str]];
		NSData *data = [NSData dataWithContentsOfURL:url];
		[data writeToURL:self.fileURL atomically:true];
		dispatch_sync(dispatch_get_main_queue(), ^{
			if (self.onFileReady)
				self.onFileReady(self);	
			// prepare image
			NSString *filepath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", self.itemId]];
			self.artImageURL = [NSURL fileURLWithPath:filepath]; 
			// check if file exists
			if ([[NSFileManager defaultManager] fileExistsAtPath:self.fileURL.path]){
				self.artImage = [UIImage imageWithContentsOfFile:self.artImageURL.path];
				if (self.onImageReady)
					self.onImageReady(self);
			} else {
				// download image
				self.prepareImage = [[NSOperationQueue alloc]init];
				[self.prepareImage addOperationWithBlock:^{
					c_yandex_music_get_track_by_id(
							[self.token UTF8String], 
							NULL, 
							[self.itemId UTF8String], 
							(__bridge void *)self, 
							get_track_with_image);
				}];
			}
		});
		return 1;
	}
	return 0;
}

-(void)prepareFile:(void (^) (Item *item))onFileReady andImage:(void (^)(Item *item))onImageReady{
	self.onFileReady = onFileReady;
	self.onImageReady = onImageReady;
	
	// prepare file
	NSString *filepath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3", self.itemId]];
	self.fileURL = [NSURL fileURLWithPath:filepath]; 
	// check if file exists
	if ([[NSFileManager defaultManager] fileExistsAtPath:self.fileURL.path]){
		if (onFileReady)
			onFileReady(self);
	} else {
		// dowload file
		self.prepareFile = [[NSOperationQueue alloc]init];
		[self.prepareFile addOperationWithBlock:^{
				c_yandex_music_get_download_url(
						[self.token UTF8String], [self.itemId UTF8String], 
						(__bridge void *)self, get_file_url);
		}];
	}
}

@end
// vim:ft=objc
