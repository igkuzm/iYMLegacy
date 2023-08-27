/**
 * File              : AudioPlayer.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 28.07.2021
 * Last Modified Date: 27.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "AudioPlayer.h"
#include "UIKit/UIKit.h"
#include "AppDelegate.h"
#include "AVFoundation/AVFoundation.h"
#include "AVFoundation/AVAudioSession.h"
#include "MediaPlayer/MediaPlayer.h"
#include "Foundation/Foundation.h"
#include "../cYandexMusic/cYandexMusic.h"
#import "Item.h"
#import "CCAudioPlayer.h"

@implementation AudioPlayer

- (id)initWiithURL:(NSURL *)url title:(NSString *)title trackId:(NSString *)trackId
{
	//if (self = [super initWithNibName:@"YPPlayer" bundle:[NSBundle mainBundle]])
	if (self = [super init])
	{
		self.trackId = trackId;
		self.downloadURL = url;
		self.fileURL = [self getFileURL];
		self.imageURL = [self getImageURL];
		self.title = title;
		self.sync = [[NSOperationQueue alloc]init];
		[self setupNotifications];
		//self.imageView = [[UIImageView alloc]initWithFrame:self.view.bounds];
		//[self.view addSubview:self.imageView];
		AppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
    [appDelegate.player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
	}
	return self;
}

- (void)viewDidLoad {
	self.view.backgroundColor = [UIColor darkGrayColor];
	// add close button 
		UIBarButtonItem *doneButtonItem = 
		[[UIBarButtonItem alloc]
				initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
				target:self action:@selector(doneButtonPushed:)]; 
	self.navigationItem.leftBarButtonItem = doneButtonItem;

	[self getUrl:self.downloadURL];
		
	self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - self.view.bounds.size.height / 3)];
	[self.view addSubview:self.imageView];
        
	self.buttonPrev = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.buttonPrev setImage:[UIImage imageNamed:@"player-prev"] forState:UIControlStateNormal];
  [self.buttonPrev setFrame:CGRectMake(0, CGRectGetMaxY([self.imageView frame]) + 20.0, self.view.bounds.size.width/3, 20.0)];
  [self.buttonPrev setTitle:@"Prev" forState:UIControlStateNormal];
    [self.buttonPrev addTarget:self action:@selector(_actionPlayPause:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.buttonPrev];
    
		self.buttonPlayPause = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.buttonPlayPause setFrame:CGRectMake(CGRectGetWidth([self.view bounds])/3 - 40.0 - 60.0, CGRectGetMinY([self.buttonPrev frame]), 60.0, 20.0)];
    [self.buttonPlayPause setFrame:CGRectMake(self.view.bounds.size.width/3, CGRectGetMinY([self.buttonPlayPause frame]), self.view.bounds.size.width/3, 20.0)];
    [self.buttonPlayPause setTitle:@"Play" forState:UIControlStateNormal];
    [self.buttonPlayPause addTarget:self action:@selector(_actionPlayPause:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.buttonPlayPause];
    
    self.buttonNext = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.buttonNext setFrame:CGRectMake(self.view.bounds.size.width - self.view.bounds.size.width/3, CGRectGetMinY([self.buttonPlayPause frame]), self.view.bounds.size.width/3, 20.0)];
    [self.buttonNext setTitle:@"Next" forState:UIControlStateNormal];
    [self.buttonNext addTarget:self action:@selector(_actionNext:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.buttonNext];
    
    self.progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(20.0, CGRectGetMaxY([self.buttonNext frame]) + 20.0, CGRectGetWidth([self.view bounds]) - 20.0 * 2.0, 40.0)];
    self.progressSlider.continuous = NO;
    [self.progressSlider addTarget:self action:@selector(_actionSliderProgress:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.progressSlider];
 
	//spinner
	self.spinner = [[UIActivityIndicatorView alloc] 
					initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	self.spinner.frame = self.view.bounds;
	[self.view addSubview:self.spinner];
	self.spinner.tag = 12;
	[self.spinner startAnimating];

	//load image if exists
	if ([[NSFileManager defaultManager] fileExistsAtPath:self.imageURL.path]){ 
		self.image = [UIImage imageWithContentsOfFile:self.imageURL.path];
		[self.imageView setImage:self.image];	
	}
}

- (void)setupNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruptionNotification:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRouteChangeNotification:) name:AVAudioSessionRouteChangeNotification object:nil];
}


-(void)_actionPlayPause:(id)sender{
	AppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
	[appDelegate.player pause];
}

-(void)doneButtonPushed:(id)sender{
	[self.navigationController dismissViewControllerAnimated:true completion:nil];
}

-(void)showError:(NSString *)msg{
	UIAlertView *alert = 
			[[UIAlertView alloc]initWithTitle:@"error" 
			message:msg 
			delegate:nil 
			cancelButtonTitle:@"Закрыть" 
			otherButtonTitles:nil];
	[alert show];
}

- (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = 
			NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = [paths objectAtIndex:0];
    return basePath;
}

-(NSURL *)getFileURL{
	NSString *filename = 
			[NSString stringWithFormat:@"%@.mp3", self.trackId];
			//[NSString stringWithFormat:@"%@.mp3", [[NSUUID UUID] UUIDString]];
	NSString *filepath = 
			[NSTemporaryDirectory() stringByAppendingPathComponent:filename];
			//[[self applicationDocumentsDirectory] stringByAppendingPathComponent:filename];
	return [NSURL fileURLWithPath:filepath];
}

-(NSURL *)getImageURL{
	NSString *filename = 
			[NSString stringWithFormat:@"%@.png", self.trackId];
	NSString *filepath = 
			[NSTemporaryDirectory() stringByAppendingPathComponent:filename];
	return [NSURL fileURLWithPath:filepath];
}


-(void)getUrl:(NSURL *)url{
	// check file exists
	if ([[NSFileManager defaultManager] fileExistsAtPath:self.fileURL.path]){ 
		[self.spinner stopAnimating];
		[self play];
	}else {
		// download
		NSURLRequest *request = 
				[NSURLRequest requestWithURL:url];
		NSURLConnection *conection = 
				[[NSURLConnection alloc]initWithRequest:request
						delegate:self startImmediately:true];
	}
}

-(void)play{
	AVPlayerItem *item = [AVPlayerItem playerItemWithURL:self.fileURL];
	AppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
	[appDelegate.player replaceCurrentItemWithPlayerItem:item];
	[appDelegate.player play];	

	// now playing
	MPNowPlayingInfoCenter * nowPlaying = [MPNowPlayingInfoCenter defaultCenter];
	if (self.image){
		MPMediaItemArtwork *artwork = [[MPMediaItemArtwork	alloc]initWithImage:self.image];
		nowPlaying.nowPlayingInfo =  
		@{MPMediaItemPropertyTitle:self.title, MPMediaItemPropertyArtist:@"test", 
			MPMediaItemPropertyArtwork:artwork};
	} else {
		nowPlaying.nowPlayingInfo =  
			@{MPMediaItemPropertyTitle:self.title, MPMediaItemPropertyArtist:@"test"}; 
	}
}

static int get_track(void *data, track_t *track, const char *error){
	AudioPlayer *self = (__bridge AudioPlayer *)data;
	if (error){
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self showError:[NSString stringWithUTF8String:error]];
		});
	}
	if (track){
		Item *t = [[Item alloc]initWithTrack:track];
		dispatch_sync(dispatch_get_main_queue(), ^{
				t.imageView = self.imageView;
				if (t.coverImage)
					self.image = t.coverImage;
					[self.imageView setImage:t.coverImage];
				// save image to cache
				[UIImagePNGRepresentation(t.coverImage) writeToURL:self.imageURL atomically:true];
				MPNowPlayingInfoCenter * nowPlaying = [MPNowPlayingInfoCenter defaultCenter];
				MPMediaItemArtwork *artwork = [[MPMediaItemArtwork	alloc]initWithImage:self.image];
				nowPlaying.nowPlayingInfo =  
					@{MPMediaItemPropertyTitle:self.title, MPMediaItemPropertyArtist:@"test", 
						MPMediaItemPropertyArtwork:artwork};
		});
	}
}
#pragma mark - NSURLConnectionDelegate Meythods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  self.mutableData = [[NSMutableData alloc]init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  [self.mutableData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[self.spinner stopAnimating];
	[self.mutableData writeToURL:self.fileURL atomically:true];

  [self play];
	if (![[NSFileManager defaultManager] fileExistsAtPath:self.imageURL.path]){ 
		NSString *token = [[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
		if (token){
			[self.sync addOperationWithBlock:^{
				c_yandex_music_get_track_by_id(
						[token UTF8String], 
						NULL, 
						[self.trackId UTF8String], 
						(__bridge void *)self, 
						get_track);
			}];
		}
	}
}

- (NSTimeInterval)duration
{
    //if (_playerItem) {
        //NSArray *loadedRanges = _playerItem.seekableTimeRanges;
        //if (loadedRanges.count > 0) {
            //CMTimeRange range = [loadedRanges[0] CMTimeRangeValue];
            //return CMTimeGetSeconds((range.duration));
        //} else {
            //return 0.0f;
        //}
    //} else {
        //return 0.0f;
    //}
}
@end
