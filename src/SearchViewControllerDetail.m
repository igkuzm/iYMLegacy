/**
 * File              : SearchViewControllerDetail.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 29.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "SearchViewControllerDetail.h"
#include "Item.h"
#import "TrackListViewController.h"
#include "UIKit/UIKit.h"
#import "PlayerViewController.h"
#include "Foundation/Foundation.h"
#import "YandexConnect.h"
#import "../cYandexMusic/cYandexMusic.h"
#import "ActionSheet.h"

@implementation SearchViewControllerDetail
- (id)initWithData:(NSArray *)data title:(NSString *)title
{
	if (self = [super init]) {
		// allocate array
		self.data = data;
		self.title = title;
	}
	return self;
}

- (void)viewDidLoad {
	
	// play button
	UIBarButtonItem *playButtonItem = 
		[[UIBarButtonItem alloc]
				initWithBarButtonSystemItem:UIBarButtonSystemItemPlay 
				target:self.appDelegate action:@selector(playButtonPushed:)]; 
	self.navigationItem.rightBarButtonItem = playButtonItem;
}

#pragma mark <TableViewDelegate Meythods>
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	Item *item = [self.data objectAtIndex:indexPath.item];
	UITableViewCell *cell = nil;
	if (item.itemType == ITEM_PLAYLIST ||
			item.itemType == ITEM_PODCAST  ||
			item.itemType == ITEM_ALBUM)
	{
		cell = [self.tableView dequeueReusableCellWithIdentifier:@"dir"];
		if (cell == nil){
			cell = [[UITableViewCell alloc]
			initWithStyle: UITableViewCellStyleSubtitle 
			reuseIdentifier: @"dir"];
		}
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	}
	else{
		cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
		if (cell == nil){
			cell = [[UITableViewCell alloc]
			initWithStyle: UITableViewCellStyleSubtitle 
			reuseIdentifier: @"cell"];
		}
	}
	item.imageView = cell.imageView;
	[cell.textLabel setText:item.title];
	[cell.detailTextLabel setText:item.subtitle];	
	if (item.coverImage)
		[cell.imageView setImage:item.coverImage];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	self.selected = [self.data objectAtIndex:indexPath.item];

	if (self.selected.itemType == ITEM_TRACK || 
			self.selected.itemType == ITEM_PODCAST_EPOSODE)
	{
		NSString *token = [[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
		if (token){
			UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)cell.accessoryView;
			[spinner startAnimating];
		ActionSheet *as = [[ActionSheet alloc]initWithItem:self.selected isDir:NO onDone:^{
				[spinner stopAnimating];
			}];
			[as showInView:tableView];		
		}
	}
	else if (self.selected.itemType == ITEM_PLAYLIST ||
					 self.selected.itemType == ITEM_PODCAST  ||
					 self.selected.itemType == ITEM_ALBUM)
	{
			TrackListViewController *vc = [[TrackListViewController alloc]initWithParent:
																			self.selected];
			[self.navigationController pushViewController:vc animated:true];
	}	// unselect row
	[tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	self.selected = [self.data objectAtIndex:indexPath.item];
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)cell.accessoryView;
	[spinner startAnimating];
	ActionSheet *as = [[ActionSheet alloc]initWithItem:self.selected isDir:YES onDone:^{
		[spinner stopAnimating];
	}];
	[as showInView:tableView];
}


@end
// vim:ft=objc
