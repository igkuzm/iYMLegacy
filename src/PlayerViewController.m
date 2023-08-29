/**
 * File              : PlayerViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 27.08.2023
 * Last Modified Date: 29.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "PlayerViewController.h"
#include "MediaPlayer/MediaPlayer.h"
#include "UIKit/UIKit.h"
#include "AppDelegate.h"
@implementation PlayerViewController
- (void)viewDidLoad
{
	AppDelegate *delegate = [[UIApplication sharedApplication]delegate];
	self.player = delegate.player;

	[self setWantsFullScreenLayout:YES];
	//[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];

	// done buttons
	UIBarButtonItem *doneButtonItem = 
		[[UIBarButtonItem alloc]
				initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
				target:self action:@selector(doneButtonPushed:)]; 
	self.navigationItem.leftBarButtonItem = doneButtonItem;

	self.player.view.frame = self.view.frame;
	[self.player setFullscreen:NO animated:YES];
	[self.player setScalingMode:MPMovieScalingModeAspectFit];
	[self.player setControlStyle:MPMovieControlStyleFullscreen];
	[self.player.view setUserInteractionEnabled:YES];
	self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:self.player.view];
}

-(void)doneButtonPushed:(id)sender{
	[self.navigationController dismissViewControllerAnimated:true completion:nil];
}
@end
// vim:ft=objc
