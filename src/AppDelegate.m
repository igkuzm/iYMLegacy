/**
 * File              : AppDelegate.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 09.08.2023
 * Last Modified Date: 29.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "AppDelegate.h"
#import <UIKit/UIResponder.h>
#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#include "RootViewController.h"
#import "PlayerController.h"
#import "PlaylistViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	// Override point for customization after application launch.
	
	[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
	self.player = [[PlayerController alloc]init];

	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];	
	RootViewController *vc = 
			[[RootViewController alloc]init];
	[self.window setRootViewController:vc];
	[self.window makeKeyAndVisible];	
	
	return true;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
	if (event.type == UIEventTypeRemoteControl) {
		switch (event.subtype) {
			case UIEventSubtypeRemoteControlTogglePlayPause:
					// Pause or play action
					if (self.player.currentPlaybackRate != 0)
						[self.player pause];
					else
						[self.player play];
					break;
			case UIEventSubtypeRemoteControlNextTrack:
					// Next track action
					[self.player next];
					break;
			case UIEventSubtypeRemoteControlPreviousTrack:
					// Previous track action
					[self.player prev];
					break;
			case UIEventSubtypeRemoteControlStop:
					// Stop action
					[self.player stop];
					break;
			default:
					// catch all action
					break;
		}
	}
}

-(void)playButtonPushed:(id)sender{
	PlayListViewController *vc = [[PlayListViewController alloc]init];
	UINavigationController *nc = [[UINavigationController alloc]initWithRootViewController:vc];
	[self.window.rootViewController presentViewController:nc animated:TRUE completion:nil];
}


@end
// vim:ft=objc

