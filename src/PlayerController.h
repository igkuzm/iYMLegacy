/**
 * File              : PlayerController.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 28.08.2023
 * Last Modified Date: 11.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "Foundation/Foundation.h"
#import "MediaPlayer/MediaPlayer.h"
#import "Item.h"
@protocol PlayerControllerDelegate <NSObject>
-(void)playerControllerStartPlayTrack:(Item *)track;
@end
@interface PlayerController : MPMoviePlayerController
@property (strong,nonatomic) NSMutableArray *playlist;
@property (strong,nonatomic) Item *nowPlaying;
@property NSInteger playing;
@property NSInteger current;
@property BOOL repeat;
@property (strong) id appDelegate;
@property (strong) NSTimer *timer;
@property (strong) NSTimer *downloadPlaylist;
@property (weak) id delegate;
-(void)addToTopAndPlay:(Item *)item onDone:(void (^)())onDone;
-(void)addToLast:(Item *)item;
-(void)addAfterCurrent:(Item *)item;
-(void)playCurrent:(void (^)())onDone;
-(void)next;
-(void)prev;

@end

// vim:ft=objc
