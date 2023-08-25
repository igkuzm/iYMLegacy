/**
 * File              : Item.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 24.08.2023
 * Last Modified Date: 25.08.2023
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
-(id)initWithTrack:(struct track *)track{
	if (self = [self init]){
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
			[self downloadImage];
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

-(id)initWithPlaylist:(playlist_t *)playlist{
	if (self = [self init]){
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
			[self downloadImage];
		}
	}

	return self;
}

- (void)downloadImage{
		NSData *data = [NSData dataWithContentsOfURL:self.coverUri];
		self.coverImage = [UIImage imageWithData:data];
			[self.imageView setImage:self.coverImage];
}
@end



// vim:ft=objc
