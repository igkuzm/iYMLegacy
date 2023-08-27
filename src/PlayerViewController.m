/**
 * File              : PlayerViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 27.08.2023
 * Last Modified Date: 27.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "PlayerViewController.h"
#include "AppDelegate.h"
#include "CoreGraphics/CoreGraphics.h"
#include "UIKit/UIKit.h"

#define kUseBlockAPIToTrackPlayerStatus     1

@implementation PlayerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
		AppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
		self.player = appDelegate.player;

		self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - self.view.bounds.size.height / 3)];
		self.imageView.backgroundColor = [UIColor greenColor];
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
    
    //_tracks = [Track remoteTracks];
    
    //[self _resetStreamer];
}

#pragma mark - Private

- (void)updateProgressView
{
    //[self.progressSlider setValue:_audioPlayer.progress / _audioPlayer.duration animated:YES];
}

- (void)updateStatusViews
{
    //switch (_audioPlayer.playerState) {
        //case CCAudioPlayerStatePlaying:
        //{
            //_statusLabel.text = @"Playing";
            //[_buttonPlayPause setTitle:@"Pause" forState:UIControlStateNormal];
        //}
            //break;
        //case CCAudioPlayerStateBuffering:
        //{
            //_statusLabel.text = @"Buffering";
        //}
            //break;
            
        //case CCAudioPlayerStatePaused:
        //{
            //_statusLabel.text = @"Paused";
            //[_buttonPlayPause setTitle:@"Play" forState:UIControlStateNormal];
        //}
            //break;
            
        //case CCAudioPlayerStateStopped:
        //{
            //_statusLabel.text = @"Play to End";
            
            //[self _actionNext:nil];
        //}
            //break;
        //default:
            //break;
    //}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"progress"]) {
        [self updateProgressView];
    } else {
        [self updateStatusViews];
    }
}

- (void)_actionSliderProgress:(id)sender
{
    //[_audioPlayer seekToTime:_audioPlayer.duration * _progressSlider.value];
}

- (void)_actionPlayPause:(id)sender
{
    //if (_audioPlayer.isPlaying) {
        //[_audioPlayer pause];
        //[_buttonPlayPause setTitle:@"Play" forState:UIControlStateNormal];
    //} else {
        //[_audioPlayer play];
        //[_buttonPlayPause setTitle:@"Pause" forState:UIControlStateNormal];
    //}
}

- (void)_actionNext:(id)sender
{
    //if (++_currentTrackIndex >= [_tracks count]) {
        //_currentTrackIndex = 0;
    //}
    
    //[self _resetStreamer];
}

- (void)_resetStreamer
{
    //if (_audioPlayer) {
        //[_audioPlayer dispose];
        //if (!kUseBlockAPIToTrackPlayerStatus) {
            //[_audioPlayer removeObserver:self forKeyPath:@"progress"];
            //[_audioPlayer removeObserver:self forKeyPath:@"playerState"];
        //}
        //_audioPlayer = nil;
    //}
    
    //[_progressSlider setValue:0.0 animated:NO];
    
    //if (_tracks.count != 0) {
        //Track *track = [_tracks objectAtIndex:_currentTrackIndex];
        //NSString *title = [NSString stringWithFormat:@"%@ - %@", track.artist, track.title];
        //[_titleLabel setText:title];
        
        //_audioPlayer = [CCAudioPlayer audioPlayerWithContentsOfURL:track.audioFileURL];
        //if (kUseBlockAPIToTrackPlayerStatus) {
            //typeof(self) __weak weakSelf = self;
            //[_audioPlayer trackPlayerProgress:^(NSTimeInterval progress) {
                //DemoViewController *strongSelf = weakSelf;
                //[strongSelf updateProgressView];
            //} playerState:^(CCAudioPlayerState playerState) {
                //DemoViewController *strongSelf = weakSelf;
                //[strongSelf updateStatusViews];
            //}];
        //} else {
            //[_audioPlayer addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew context:NULL];
            //[_audioPlayer addObserver:self forKeyPath:@"playerState" options:NSKeyValueObservingOptionNew context:NULL];
        //}
        //[_audioPlayer play];
    //} else {
        //NSLog(@"No tracks available");
    //}
}

@end
// vim:ft=objc
