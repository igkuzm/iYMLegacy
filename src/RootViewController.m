/**
 * File              : RootViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 25.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "RootViewController.h"
#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#import "FeedViewController.h"
#import "FavoritesViewController.h"
#import "SearchViewController.h"

@implementation RootViewController
- (void)viewDidLoad {
	
	// feed view
	FeedViewController *feedvc = 
		[[FeedViewController alloc]init];
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

@end


// vim:ft=objc
