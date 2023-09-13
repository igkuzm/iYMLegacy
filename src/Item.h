/**
 * File              : Item.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 24.08.2023
 * Last Modified Date: 13.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "Foundation/Foundation.h"
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

#define kToken          @"token"
#define kItemId         @"itemId"
#define kItemType       @"itemType"
#define kTitle          @"title"
#define kSubtitle       @"subtitle"
#define kAlbumTitle     @"albumTitle"
#define kAlbumId        @"albumId"
#define kUID            @"uid"
#define kKind           @"kind"
#define kCoverUri       @"coverUri"
#define kDownloadURL    @"downloadURL"
#define kHasDownloadURL @"hasDownloadURL"
#define kHasFile        @"hasFile"
#define kCoverImage     @"coverImage"
#define kArtImageURL    @"artImageURL"
#define kHasArtImage    @"hasArtImage"

@interface Item : NSObject
<NSURLConnectionDelegate, NSCoding>
@property (strong) NSString *thumbmailsCache;
@property (strong) NSString *imagesCache;
@property (strong) NSString *tracksCache;
@property (strong) NSString *token;
@property (strong) NSString *itemId;
@property ITEM_TYPE itemType;
@property (strong) NSString *title;
@property (strong) NSString *subtitle;
@property (strong) NSString *albumTitle;
@property long albumId;
@property long uid;
@property long kind;
@property (strong) NSURL *coverUri;
@property (strong) NSURL *downloadURL;
@property BOOL hasDownloadURL;
@property BOOL hasFile;
@property (strong) UIImage *coverImage;       // small image 100x100
@property (strong) UIImageView *imageView;    
@property (strong) UIImage *artImage;         // fullsize image
@property (strong) NSURL *artImageURL;        
@property BOOL hasAtrImage;
@property (strong) UIImageView *artImageView; 
@property (strong) AVPlayerItem *playerItem;
@property (strong) NSOperationQueue *prepareDownloadURL;
@property (strong) NSOperationQueue *prepareImage;
@property (strong) NSOperationQueue *downloadFile;
-(id)initWithTrack:(track_t *)track token:(NSString *)token;
-(id)initWithPlaylist:(playlist_t *)playlist token:(NSString *)token;
-(id)initWithAlbum:(album_t *)album token:(NSString *)token;
-(void)prepareDownloadURL:(void (^) (Item *item))onDownloadURLReady;
-(void)prepareImage:(void (^)(Item *item))onImageReady;
-(void)downloadFile:(void (^)(Item *item))onFileReady;
- (void)downloadSmallImage;
@property (copy) void (^onDownloadURLReady)(Item *item);
@property (copy) void (^onImageReady)(Item *item);
@property (copy) void (^onFileReady)(Item *item);
@end


// vim:ft=objc
