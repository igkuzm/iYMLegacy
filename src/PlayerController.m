/**
 * File              : PlayerController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 28.08.2023
 * Last Modified Date: 29.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "PlayerController.h"
#include "stdbool.h"
#include "MediaPlayer/MediaPlayer.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"
#include "AVFoundation/AVAudioSession.h"
#include "../cYandexMusic/cYandexMusic.h"

@implementation PlayerController
- (id)init
{
	if (self = [super init]) {
		self.playlist = [NSMutableArray array];		
		self.current = -1;
		self.repeat = false;
		[self setUseApplicationAudioSession:FALSE];
		[self setupPlayBackAudioSession];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterFullscreen:) name:MPMoviePlayerWillEnterFullscreenNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willExitFullscreen:) name:MPMoviePlayerWillExitFullscreenNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enteredFullscreen:) name:MPMoviePlayerDidEnterFullscreenNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exitedFullscreen:) name:MPMoviePlayerDidExitFullscreenNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];

	}
	return self;
}
-(void)playItem:(Item *)item{
	[self setContentURL:item.downloadURL];
	[self prepareToPlay];
	[self play];
	[self setPlayInfo:item];

	[[[NSOperationQueue alloc]init] addOperationWithBlock:^{
		c_yandex_music_post_current(
				[item.token UTF8String], 
				[item.itemId UTF8String], 
				NULL, NULL);
	}];
}
-(void)preparePlayItem:(Item *)item onDone:(void (^)())onDone{
	if (!item.hasDownloadURL){
		[item.prepareDownloadURL cancelAllOperations];
		[item prepareDownloadURL:^(Item *item){
			[self playItem:item];
			if (onDone)
				onDone();
		}];
	}else {
		[self playItem:item];
		if (onDone)
			onDone();
	}
}

-(void)playCurrent:(void (^)())onDone{
	Item *item = [self.playlist objectAtIndex:self.current];
	if (item)
		[self preparePlayItem:item onDone:onDone];
}

-(void)addToLast:(Item *)item {
	[self.playlist addObject:item];
}

-(void)addAfterCurrent:(Item *)item{
	[self.playlist insertObject:item atIndex:self.current + 1];
}

-(void)addToTopAndPlay:(Item *)item onDone:(void (^)())onDone{
	if (self.current < 0)
		self.current = 0;
	[self.playlist insertObject:item atIndex:self.current];
	[self playCurrent:onDone];
}

-(void)next{
	self.current++;
	if (self.current >= self.playlist.count)
		self.current = 0;
	if (self.current != 0 || self.repeat)
		[self playCurrent:NULL];
}

-(void)prev{
	self.current--;
	if (self.current < 0)
		self.current = 0;
	[self playCurrent:NULL];
}

-(void)setPlayInfoWithArt:(Item *)item{
	MPNowPlayingInfoCenter * nowPlaying = [MPNowPlayingInfoCenter defaultCenter];
		MPMediaItemArtwork *artwork = [[MPMediaItemArtwork	alloc]initWithImage:item.artImage];
		nowPlaying.nowPlayingInfo =  
		@{MPMediaItemPropertyTitle:item.title,
			MPMediaItemPropertyArtist:item.subtitle, 
			MPMediaItemPropertyArtwork:artwork};
}

-(void)setPlayInfo:(Item *)item{
	MPNowPlayingInfoCenter * nowPlaying = [MPNowPlayingInfoCenter defaultCenter];
	//if (item.hasAtrImage){
			//[self setPlayInfoWithArt:item];
	//} else {
		nowPlaying.nowPlayingInfo =  
				@{MPMediaItemPropertyTitle:
							item.title, 
							MPMediaItemPropertyArtist:item.subtitle};
		//[item prepareImage:^(Item *item){
			//[self setPlayInfoWithArt:item];
		//}];
	//}
}

#pragma mark <AudioSession Setup>
- (void)setupPlayBackAudioSession
{
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	if (audioSession.category != AVAudioSessionCategoryPlayback) {
		UIDevice *device = [UIDevice currentDevice];
		if ([device respondsToSelector:@selector(isMultitaskingSupported)]) {
			if (device.multitaskingSupported) {										                
				
				NSError *setCategoryError = nil;
				[audioSession setCategory:AVAudioSessionCategoryPlayback
											withOptions:AVAudioSessionCategoryOptionAllowBluetooth
											error:&setCategoryError];
				if (setCategoryError)
					NSLog(@"%@", setCategoryError.description);
				
				NSError *activationError = nil;
				[audioSession setActive:YES error:&activationError];
				if (activationError)
					NSLog(@"%@", activationError.description);
			}
		}									    
	}				
}
 - (void)willEnterFullscreen:(NSNotification*)notification {
	NSLog(@"willEnterFullscreen");
	[self setControlStyle:MPMovieControlStyleFullscreen];
}

- (void)enteredFullscreen:(NSNotification*)notification {
	NSLog(@"enteredFullscreen");
}

- (void)willExitFullscreen:(NSNotification*)notification {
	NSLog(@"willExitFullscreen");
}

- (void)exitedFullscreen:(NSNotification*)notification {
	NSLog(@"exitedFullscreen");
}

- (void)playbackFinished:(NSNotification*)notification {
NSNumber* reason = [[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
	switch ([reason intValue]) {
			case MPMovieFinishReasonPlaybackEnded:
					// play next
					[self next];
					NSLog(@"playbackFinished. Reason: Playback Ended");
							break;
			case MPMovieFinishReasonPlaybackError:
					NSLog(@"playbackFinished. Reason: Playback Error");
							break;
			case MPMovieFinishReasonUserExited:
					NSLog(@"playbackFinished. Reason: User Exited");
							break;
			default:
					break;
	}
	//[self.movieController setFullscreen:NO animated:YES];
}


@end


// vim:ft=objc
