/**
 * File              : PlayerController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 28.08.2023
 * Last Modified Date: 12.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "PlayerController.h"
#include "stdbool.h"
#include "MediaPlayer/MediaPlayer.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"
#include "AVFoundation/AVAudioSession.h"
#include "../cYandexMusic/cYandexMusic.h"
#import "AppDelegate.h"

@implementation PlayerController
- (id)init
{
	if (self = [super init]) {
		self.appDelegate = [[UIApplication sharedApplication]delegate];
		self.playlist = [NSMutableArray array];		
		self.current = -1;
		self.repeat = false;
		[self setUseApplicationAudioSession:FALSE];
		[self setupPlayBackAudioSession];
		//[self setMovieSourceType:MPMovieSourceTypeStreaming];

	[[NSNotificationCenter defaultCenter] 
		addObserver:self selector:@selector(willEnterFullscreen:) 
					 name:MPMoviePlayerWillEnterFullscreenNotification object:nil];
	[[NSNotificationCenter defaultCenter] 
		addObserver:self selector:@selector(willExitFullscreen:) 
					 name:MPMoviePlayerWillExitFullscreenNotification object:nil];
	[[NSNotificationCenter defaultCenter] 
		addObserver:self selector:@selector(enteredFullscreen:) 
					 name:MPMoviePlayerDidEnterFullscreenNotification object:nil];
	[[NSNotificationCenter defaultCenter] 
		addObserver:self selector:@selector(exitedFullscreen:) 
					 name:MPMoviePlayerDidExitFullscreenNotification object:nil];
	[[NSNotificationCenter defaultCenter] 
		addObserver:self selector:@selector(playbackFinished:) 
					 name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
	[[NSNotificationCenter defaultCenter] 
		addObserver:self selector:@selector(loadStateChanged:) 
					 name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] 
		addObserver:self selector:@selector(nowPlayingChanged:) 
					 name:MPMoviePlayerNowPlayingMovieDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] 
		addObserver:self selector:@selector(playbackStateChanged:) 
					 name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
		// add timer
		self.timer = [NSTimer scheduledTimerWithTimeInterval:10 
				target:self selector:@selector(timer:) 
					userInfo:nil repeats:YES];

	}
	return self;
}

void post_error(void *data, const char *error){
	AppDelegate *appDelegate = (__bridge AppDelegate *)data;
	if (error){
		NSLog(@"%s", error);
		//dispatch_sync(dispatch_get_main_queue(), ^{
			//[appDelegate showMessage:[NSString stringWithUTF8String:error] title:@"error"];
		//});
	}
}

-(void)timer:(id)sender{
	// do timer funct
	if (!self.nowPlaying)
		return;

	if (self.playbackState == MPMoviePlaybackStatePlaying){
		NSInteger uid = 
				[[NSUserDefaults standardUserDefaults]integerForKey:@"uid"];
		if (!uid){
			if (self.nowPlaying.token)
				uid = c_yandex_music_get_uid([self.nowPlaying.token UTF8String]);
			if (uid)
				[[NSUserDefaults standardUserDefaults]setInteger:uid forKey:@"uid"];
		}

		if (!uid)
			return;

		[[[NSOperationQueue alloc]init] addOperationWithBlock:^{
			c_yandex_music_post_current(
					[self.nowPlaying.token UTF8String], 
					NULL,
					[self.nowPlaying.itemId UTF8String], 
					self.duration,
					self.playableDuration,
					uid,
					(__bridge void *)self.appDelegate, post_error);
		}];
	}
}

-(void)playItem:(Item *)item{
	[self setContentURL:item.downloadURL];
	[self prepareToPlay];
	[self play];
	[self setPlayInfo:item];
	
	[self setNowPlaying:item];
	[self setPlaying:self.current];
	if (self.delegate)
		[self.delegate playerControllerStartPlayTrack:item];

	// download current and next items after 10 sec
	if (self.downloadPlaylist){
		// stop timer
		[self.downloadPlaylist fire];
	}
	// start after 10 sec
	self.downloadPlaylist = 
		[NSTimer scheduledTimerWithTimeInterval:10 
			target:self selector:@selector(downloadCurrentAndNext:) 
			userInfo:nil repeats:NO];
}

-(void)downloadNext:(int)i{
	// download next item
	if (
			self.playlist.count > self.current + i &&
			i < 10)
	{
		Item *item = [self.playlist objectAtIndex:self.current + i];
		if (item){
			[item downloadFile:^(Item *item){
				// do when downloaded
				// prepare image
				[item prepareImage:^(Item *item){
					// on done
					[self downloadNext:i+1];
				}];
			}];
		}
	}
}

-(void)downloadCurrentAndNext:(id)sender{
	// download current
	Item *item = [self.playlist objectAtIndex:self.current];
	if (item){
		[item downloadFile:^(Item *item){
			// do when downloaded
			[self downloadNext:1];
		}];
	}
}

-(void)preparePlayItem:(Item *)item onDone:(void (^)())onDone{
	if (!item.hasFile && !item.hasDownloadURL){
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
	if (self.playlist.count > self.current){
		Item *item = [self.playlist objectAtIndex:self.current];
		if (item)
			[self preparePlayItem:item onDone:onDone];
	}
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
	if (self.current >= self.playlist.count && self.repeat)
		self.current = 0;
	if (self.current < self.playlist.count)
		[self playCurrent:NULL];
}

-(void)prev{
	self.current--;
	if (self.current < 0)
		self.current = 0;
	[self playCurrent:NULL];
}

-(void)setPlayInfoWithArt:(Item *)item{
	if (item.artImage){
		MPNowPlayingInfoCenter * nowPlaying = [MPNowPlayingInfoCenter defaultCenter];
			MPMediaItemArtwork *artwork = [[MPMediaItemArtwork	alloc]initWithImage:item.artImage];
			nowPlaying.nowPlayingInfo =  
			@{MPMediaItemPropertyTitle:item.title,
				MPMediaItemPropertyArtist:item.subtitle, 
				MPMediaItemPropertyAlbumTitle:item.albumTitle,
				MPMediaItemPropertyArtwork:artwork};
	}
}

-(void)setPlayInfo:(Item *)item{
	MPNowPlayingInfoCenter * nowPlaying = [MPNowPlayingInfoCenter defaultCenter];
	if (item.hasAtrImage){
			[self setPlayInfoWithArt:item];
	} else {
		nowPlaying.nowPlayingInfo =  
				@{MPMediaItemPropertyTitle:
							item.title, 
							MPMediaItemPropertyArtist:item.subtitle,
					MPMediaItemPropertyAlbumTitle:item.albumTitle};
		[item prepareImage:^(Item *item){
			[self setPlayInfoWithArt:item];
		 }];
	}
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

- (void)loadStateChanged:(NSNotification*)notification {
	switch (self.loadState) {
		case MPMovieLoadStateUnknown: break;
		case MPMovieLoadStateStalled: break;
		case MPMovieLoadStatePlayable: break;
		case MPMovieLoadStatePlaythroughOK: break;
	
		default: break;
	}
}
- (void)nowPlayingChanged:(NSNotification*)notification {
}
- (void)playbackStateChanged:(NSNotification*)notification {
}

@end


// vim:ft=objc
