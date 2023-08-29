/**
 * File              : Item.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 24.08.2023
 * Last Modified Date: 28.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import <UIKit/UIKit.h>
#import "../cYandexMusic/cYandexMusic.h"
#import <AVFoundation/AVFoundation.h>

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
@property (strong) NSString *token;
@property (strong) NSString *itemId;
@property ITEM_TYPE itemType;
@property (strong) NSString *title;
@property (strong) NSString *subtitle;
@property long uid;
@property long kind;
@property (strong) NSURL *coverUri;
@property (strong) NSURL *downloadURL;
@property BOOL hasDownloadURL;
@property (strong) UIImage *coverImage;       // small image 100x100
@property (strong) UIImageView *imageView;    
@property (strong) UIImage *artImage;         // fullsize image
@property (strong) NSURL *artImageURL;        
@property BOOL hasAtrImage;
@property (strong) UIImageView *artImageView; 
@property (strong) AVPlayerItem *playerItem;
@property (strong) NSOperationQueue *prepareDownloadURL;
@property (strong) NSOperationQueue *prepareImage;
-(id)initWithTrack:(track_t *)track token:(NSString *)token;
-(id)initWithPlaylist:(playlist_t *)playlist token:(NSString *)token;
-(void)prepareDownloadURL:(void (^) (Item *item))onDownloadURLReady;
-(void)prepareImage:(void (^)(Item *item))onImageReady;
@property (copy) void (^onDownloadURLReady)(Item *item);
@property (copy) void (^onImageReady)(Item *item);
@end


// vim:ft=objc
