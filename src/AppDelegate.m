/**
 * File              : AppDelegate.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 09.08.2023
 * Last Modified Date: 27.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "AppDelegate.h"
#import <UIKit/UIResponder.h>
#include "stdbool.h"
#include "AVFoundation/AVFoundation.h"
#include "AVFoundation/AVAudioSession.h"
#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#include "RootViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	// Override point for customization after application launch.
	
	[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
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
					if (self.player.rate != 0 && self.player.error == nil)
						[self.player pause];
					else if (self.player.rate == 0 && self.player.error == nil)
						[self.player play];
					break;
			case UIEventSubtypeRemoteControlNextTrack:
					// Next track action
					break;
			case UIEventSubtypeRemoteControlPreviousTrack:
					// Previous track action
					break;
			case UIEventSubtypeRemoteControlStop:
					// Stop action
					break;
			default:
					// catch all action
					break;
		}
	}
}

@end
// vim:ft=objc

