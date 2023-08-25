/**
 * File              : Item.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 24.08.2023
 * Last Modified Date: 25.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import <UIKit/UIKit.h>
#import "../cYandexMusic/cYandexMusic.h"

typedef enum {
	ITEM_TRACK,
	ITEM_PODCAST,
	ITEM_PODCAST_EPOSODE,
	ITEM_PLAYLIST,
	ITEM_ALBUM,	
	ITEM_ARTIST,	
	ITEM_CLIP,	
} ITEM_TYPE;

@interface Item : NSObject
<NSURLConnectionDelegate>
@property (strong) NSString *itemId;
@property ITEM_TYPE itemType;
@property (strong) NSString *title;
@property (strong) NSString *subtitle;
@property long uid;
@property long kind;
@property (strong) NSURL *coverUri;
@property (strong) NSURL *downloadURL;
@property (strong) UIImage *coverImage;
@property (strong) UIImageView *imageView;
-(id)initWithTrack:(track_t *)track;
-(id)initWithPlaylist:(playlist_t *)playlist;
@end


// vim:ft=objc
