/**
 * File              : RootViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 22.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "RootViewController.h"
#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#import "FavoritesViewController.h"

@implementation RootViewController
- (void)viewDidLoad {
	
	FavoritesViewController *fvc = 
		[[FavoritesViewController alloc]init];
	UINavigationController *fnc =
		[[UINavigationController alloc]initWithRootViewController:fvc];
	UITabBarItem *ftbi = [[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemTopRated tag:0];
	[fnc setTabBarItem:ftbi];

	[self setViewControllers:@[fnc] animated:TRUE];
}

@end


// vim:ft=objc
