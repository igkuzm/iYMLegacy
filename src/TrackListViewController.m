/**
 * File              : TrackListViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 12.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "TrackListViewController.h"
#import "PlayerViewController.h"
#include "Item.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"
#import "YandexConnect.h"
#import "../cYandexMusic/cYandexMusic.h"
#import "ActionSheet.h"

@implementation TrackListViewController
- (id)initWithParent:(Item *)item
{
	if (self = [super init]) {
		self.title = item.title;
		self.loadedData = [NSMutableArray array];
		self.appDelegate = [[UIApplication sharedApplication]delegate];
		self.parent = item;
	}
	return self;
}

- (void)viewDidLoad {
	self.appDelegate = [[UIApplication sharedApplication]delegate];
	// allocate array
	self.data = [NSArray array];
	self.syncData = [[NSOperationQueue alloc]init];
		
	self.token = [[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
	if (!self.token){
		NSLog(@"No token!");
		return;
	}
	
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
	[self.syncData cancelAllOperations];
	[self.loadedData removeAllObjects];
	// animate spinner
	CGRect rect = self.view.bounds;
	self.spinner.center = CGPointMake(rect.size.width/2, rect.size.height/2);
	if (!self.refreshControl.refreshing)
		[self.spinner startAnimating];

	if (self.parent.itemType == ITEM_PLAYLIST)
	{
		[self.syncData addOperationWithBlock:^{
			c_yandex_music_get_playlist_tracks(
					[self.token UTF8String], "100x100",
					self.parent.uid, self.parent.kind,	
					(__bridge void *)self, get_tracks);
		}];
	}
	else if (self.parent.itemType == ITEM_PODCAST ||
					 self.parent.itemType == ITEM_ALBUM)
	{
		[self.syncData addOperationWithBlock:^{
			c_yandex_music_get_album_tracks(
					[self.token UTF8String], "100x100",
					[self.parent.itemId intValue],	
					(__bridge void *)self, get_tracks);
		}];
	}

	[self filterData];
	[self.refreshControl endRefreshing];
}

-(void)refresh:(id)sender{
	[self reloadData];
}

static int get_tracks(void *data, track_t *track, const char *error)
{ 
	TrackListViewController *self = (__bridge TrackListViewController *)data;
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
	cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (cell == nil){
		cell = [[UITableViewCell alloc]
		initWithStyle: UITableViewCellStyleSubtitle 
		reuseIdentifier: @"cell"];
	}
	cell.accessoryView = 
			[[UIActivityIndicatorView alloc] 
			initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	item.imageView = cell.imageView;
	[cell.textLabel setText:item.title];
	[cell.detailTextLabel setText:item.subtitle];	
	if (item.coverImage)
		[cell.imageView setImage:item.coverImage];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	self.selected = [self.data objectAtIndex:indexPath.item];
		
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)cell.accessoryView;
		[spinner startAnimating];
		ActionSheet *as = [[ActionSheet alloc]initWithItem:self.selected isDir:NO onDone:^{
			[spinner stopAnimating];
		}];
		//[as showInView:tableView];
		[as showFromTabBar:self.tabBarController.tabBar];
		
		// unselect row
	[tableView deselectRowAtIndexPath:indexPath animated:true];
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// hide keyboard
	[self.searchBar resignFirstResponder];
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
