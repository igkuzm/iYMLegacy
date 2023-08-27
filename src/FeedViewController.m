/**
 * File              : FeedViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 27.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "FeedViewController.h"
#import "TrackListViewController.h"
#include "Item.h"
#include "UIKit/UIKit.h"
#import "QuickLookController.h"
#include "Foundation/Foundation.h"
#import "YandexConnect.h"
#import "YandexConnect.h"
#import "../cYandexMusic/cYandexMusic.h"

@implementation FeedViewController
-(void)showError:(NSString *)msg{
	UIAlertView *alert = 
			[[UIAlertView alloc]initWithTitle:@"error" 
			message:msg 
			delegate:nil 
			cancelButtonTitle:@"Закрыть" 
			otherButtonTitles:nil];
	[alert show];
}

static int get_url(void *data, const char *url_str, const char *error){
	FeedViewController *self = (__bridge FeedViewController *)data;
	if (error)
		[self showError:[NSString stringWithUTF8String:error]];
	if (url_str){
		NSURL *url = [NSURL URLWithString:[NSString stringWithUTF8String:url_str]];
		QuickLookController *qc = 
				[[QuickLookController alloc]initQLPreviewControllerWithURL:url 
						title:self.selected.title trackId:self.selected.itemId];
		[self presentViewController:qc 
											 animated:TRUE completion:nil];
		//[self.navigationController pushViewController:qc animated:true];
		return 1;
	}
	return 0;
}

static int get_feed(void *data, playlist_t *playlist,  track_t *track, const char *error)
{ 
	FeedViewController *self = (__bridge FeedViewController *)data;
	if (error)
		[self showError:[NSString stringWithUTF8String:error]];

	if (track){
		Item *t = [[Item alloc]initWithTrack:track];
		dispatch_sync(dispatch_get_main_queue(), ^{
			// Update your UI
			[self.loadedData addObject:t];
			[self filterData];
			[self.spinner stopAnimating];
			[self.refreshControl endRefreshing];
		});
	}
	if (playlist){
		Item *t = [[Item alloc]initWithPlaylist:playlist];
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

static int get_tracks(void *data, track_t *track, const char *error)
{ 
	TrackListViewController *tvc = (__bridge TrackListViewController *)data;
	if (error){
		dispatch_sync(dispatch_get_main_queue(), ^{
				[tvc showError:[NSString stringWithUTF8String:error]];
		});
	}

	if (track){
		Item *t = [[Item alloc]initWithTrack:track];
		dispatch_sync(dispatch_get_main_queue(), ^{
			// Update your UI
			[tvc.loadedData addObject:t];
			[tvc filterData];
			[tvc.spinner stopAnimating];
			[tvc.refreshControl endRefreshing];
		});
	}
	return 0;
}
- (void)viewDidLoad {
	[self setTitle:@"Популярные"];	
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
	
	// search bar
	self.searchBar = 
		[[UISearchBar alloc] initWithFrame:CGRectMake(0,70,320,44)];
	self.tableView.tableHeaderView=self.searchBar;	
	self.searchBar.delegate = self;
	self.searchBar.placeholder = @"Поиск:";

	// editing style
	self.tableView.allowsMultipleSelectionDuringEditing = false;
	
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
				[NSPredicate predicateWithFormat:@"self.title contains[c] %@", self.searchBar.text]];
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
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
	dispatch_async(queue, ^{
		[self.loadedData removeAllObjects];
		c_yandex_music_get_feed([token UTF8String], "100x100", (__bridge void *)self, get_feed);
	});
}

-(void)refresh:(id)sender{
	[self reloadData];
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
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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

	if (self.selected.itemType == ITEM_TRACK){
		NSString *token = [[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
		if (token){
			c_yandex_music_get_download_url(
					[token UTF8String], [self.selected.itemId UTF8String], 
					(__bridge void *)self, get_url);
		}
	}
	else if (self.selected.itemType == ITEM_PLAYLIST){
		NSString *token = [[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
		if (token){	
			TrackListViewController *vc = [[TrackListViewController alloc]initWithTitle:
																			self.selected.title];

			dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
				dispatch_async(queue, ^{
					c_yandex_music_get_playlist_tracks(
							[token UTF8String], "100x100",
							self.selected.uid, self.selected.kind,	
							(__bridge void *)vc, get_tracks);
				});
				[self.navigationController pushViewController:vc animated:true];
		}
	}
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
