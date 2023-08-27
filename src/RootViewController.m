/**
 * File              : RootViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 27.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "RootViewController.h"
#include "AppDelegate.h"
#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#import "FeedViewController.h"
#import "FavoritesViewController.h"
#import "SearchViewController.h"
#import "PlayerViewController.h"
#include "AVFoundation/AVAudioSession.h"

@implementation RootViewController
- (void)viewDidLoad {
	
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	 if (audioSession.category != AVAudioSessionCategoryPlayback) {
		UIDevice *device = [UIDevice currentDevice];
	  if ([device respondsToSelector:@selector(isMultitaskingSupported)]) {
			if (device.multitaskingSupported) {
					NSError *setCategoryError = nil;
					[audioSession setCategory:AVAudioSessionCategoryPlayback
					withOptions:AVAudioSessionCategoryOptionAllowBluetooth
					error:&setCategoryError];
					
				NSError *activationError = nil;
				[audioSession setActive:YES error:&activationError];	
			}						        
		}							    
	}

	// init player
	//AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	//NSError *error = nil;
	//[audioSession
		//setCategory:AVAudioSessionCategoryPlayback 
		////withOptions:AVAudioSessionCategoryOptionMixWithOthers|AVAudioSessionCategoryOptionAllowBluetooth
					 //error:&error];
	//if (error)
		//[self showError:error.description];
		////NSLog(@"%@", error.description);
	//else 
		//[audioSession setActive:true error:&error];
	//if (error)
		//[self showError:error.description];
		////NSLog(@"%@", error.description);
	//[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

	AppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
	appDelegate.playlist = [NSMutableArray array];
	appDelegate.player  = [[AVQueuePlayer alloc]initWithItems:appDelegate.playlist];
	[appDelegate.player setAllowsExternalPlayback:true];
	[appDelegate.player setAllowsAirPlayVideo:true];
	
	// feed view
	//FeedViewController *feedvc = 
	PlayerViewController *feedvc = 
		[[PlayerViewController alloc]init];
	UINavigationController *feednc =
		[[UINavigationController alloc]initWithRootViewController:feedvc];
	UITabBarItem *feedtbi = [[UITabBarItem alloc]
			initWithTabBarSystemItem:UITabBarSystemItemMostViewed tag:0];
	[feednc setTabBarItem:feedtbi];

	// search view
	SearchViewController *searchvc = 
		[[SearchViewController alloc]init];
	UINavigationController *searchnc =
		[[UINavigationController alloc]initWithRootViewController:searchvc];
	UITabBarItem *searchtbi = [[UITabBarItem alloc]
			initWithTabBarSystemItem:UITabBarSystemItemSearch tag:1];
	[searchnc setTabBarItem:searchtbi];

	// favorites view
	FavoritesViewController *favvc = 
		[[FavoritesViewController alloc]init];
	UINavigationController *favnc =
		[[UINavigationController alloc]initWithRootViewController:favvc];
	UITabBarItem *favtbi = [[UITabBarItem alloc]
			initWithTabBarSystemItem:UITabBarSystemItemFavorites tag:2];
	[favnc setTabBarItem:favtbi];


	[self setViewControllers:@[feednc, searchnc, favnc] animated:TRUE];
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
@end


// vim:ft=objc
