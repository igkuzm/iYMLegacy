/**
 * File              : FeedViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 13.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "FeedViewController.h"
#import "TrackListViewController.h"
#import "PlayerViewController.h"
#include "Item.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"
#import "YandexConnect.h"
#import "YandexConnect.h"
#import "ActionSheet.h"
#import "../cYandexMusic/cYandexMusic.h"

@implementation FeedViewController
- (void)viewDidLoad {
	[self setTitle:@"Подборка"];	
	self.appDelegate = [[UIApplication sharedApplication]delegate];
	
	self.syncData = [[NSOperationQueue alloc]init];
	// allocate array
	self.loadedData = [NSMutableArray array];
	self.data = [NSArray array];
	
	// check token
	NSString *token = 
		[[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
	if (!token){
		// start Yandex Connect
		YandexConnect *yc = 
			[[YandexConnect alloc]initWithFrame:[[UIScreen mainScreen] bounds]];
		[self presentViewController:yc 
											 animated:TRUE completion:nil];
	}
	self.token = token;
	
	// search bar
	self.searchBar = 
		[[UISearchBar alloc] initWithFrame:CGRectMake(0,70,320,44)];
	self.tableView.tableHeaderView=self.searchBar;	
	self.searchBar.delegate = self;
	self.searchBar.placeholder = @"Поиск:";

	// refresh control
	self.refreshControl=
		[[UIRefreshControl alloc]init];
	[self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@""]];
	[self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];

	//spinner
	self.spinner = 
		[[UIActivityIndicatorView alloc] 
		initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[self.tableView addSubview:self.spinner];
	self.spinner.tag = 12;

	// play button
	//UIBarButtonItem *playButtonItem = 
		//[[UIBarButtonItem alloc]
				//initWithBarButtonSystemItem:UIBarButtonSystemItemPlay 
				//target:self.appDelegate action:@selector(playButtonPushed:)]; 
	//self.navigationItem.rightBarButtonItem = playButtonItem;

	// load data
	[self reloadData];
}

//hide searchbar by default
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView setContentOffset:CGPointMake(0, 44)];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.tableView setContentOffset:CGPointMake(0, 44) animated:YES];
    [self.searchBar resignFirstResponder];
}

-(void)filterData{
	if (self.searchBar.text && self.searchBar.text.length > 0)
		self.data = [self.loadedData filteredArrayUsingPredicate:
				//[NSPredicate predicateWithFormat:@"self.title contains[c] %@", self.searchBar.text]];
				[NSPredicate predicateWithFormat:@"self.title contains[c] %@ or self.subtitle contains[c] %s", self.searchBar.text, self.searchBar.text]];
	else
		self.data = self.loadedData;
	[self.tableView reloadData];
}

-(void)reloadData{
	NSString *token = 
		[[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
	if (!token)
		return;
	// animate spinner
	CGRect rect = self.view.bounds;
	self.spinner.center = CGPointMake(rect.size.width/2, rect.size.height/2);
	if (!self.refreshControl.refreshing)
		[self.spinner startAnimating];
	
	[self.syncData cancelAllOperations];
	[self.loadedData removeAllObjects];
	[self.tableView reloadData];
	[self.syncData addOperationWithBlock:^{
		c_yandex_music_get_feed(
				[token UTF8String], 
				"100x100", 
				(__bridge void *)self, 
				get_feed);
	}];
}

-(void)refresh:(id)sender{
	[self reloadData];
}

static int get_feed(void *data, playlist_t *playlist,  track_t *track, const char *error)
{ 
	FeedViewController *self = (__bridge FeedViewController *)data;
	if (error){
		NSLog(@"%s", error);
	}

	if (track){
		Item *t = [[Item alloc]initWithTrack:track token:self.token];
		dispatch_sync(dispatch_get_main_queue(), ^{
			// Update your UI
			[self.loadedData addObject:t];
			[self filterData];
			[self.spinner stopAnimating];
			[self.refreshControl endRefreshing];
		});
	}
	if (playlist){
		Item *t = [[Item alloc]initWithPlaylist:playlist token:self.token];
		dispatch_sync(dispatch_get_main_queue(), ^{
			// Update your UI
			[self.loadedData addObject:t];
			[self filterData];
			[self.spinner stopAnimating];
			[self.refreshControl endRefreshing];
		});
	}
	return 0;
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
	if (item.itemType == ITEM_PLAYLIST){
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
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)cell.accessoryView;
		[spinner startAnimating];
		ActionSheet *as = [[ActionSheet alloc]initWithItem:self.selected isDir:NO onDone:^{
			[spinner stopAnimating];
		}];
		//[as showInView:self.view];
		[as showFromTabBar:self.tabBarController.tabBar];
	}
	else if (self.selected.itemType == ITEM_PLAYLIST ||
					 self.selected.itemType == ITEM_PODCAST  ||
					 self.selected.itemType == ITEM_ALBUM)
	{
			TrackListViewController *vc = [[TrackListViewController alloc]initWithParent:
																			self.selected];
			[self.navigationController pushViewController:vc animated:true];
	}
	// unselect row
	[tableView deselectRowAtIndexPath:indexPath animated:true];
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// hide keyboard
	[self.searchBar resignFirstResponder];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	self.selected = [self.data objectAtIndex:indexPath.item];
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)cell.accessoryView;
	[spinner startAnimating];
	ActionSheet *as = [[ActionSheet alloc]initWithItem:self.selected isDir:YES onDone:^{
		[spinner stopAnimating];
	}];
	[as showFromTabBar:self.tabBarController.tabBar];
}


#pragma mark <SEARCHBAR FUNCTIONS>

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
	[self filterData];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
	[self.searchBar resignFirstResponder];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
}
@end
// vim:ft=objc
