/**
 * File              : PlayerController.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 28.08.2023
 * Last Modified Date: 29.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "Foundation/Foundation.h"
#import "MediaPlayer/MediaPlayer.h"
#import "Item.h"
@interface PlayerController : MPMoviePlayerController
@property (strong,nonatomic) NSMutableArray *playlist;
@property NSInteger current;
@property BOOL repeat;
-(void)addToTopAndPlay:(Item *)item onDone:(void (^)())onDone;
-(void)addToLast:(Item *)item;
-(void)addAfterCurrent:(Item *)item;
-(void)playCurrent:(void (^)())onDone;
-(void)next;
-(void)prev;

@end

// vim:ft=objc
