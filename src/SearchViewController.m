/**
 * File              : SearchViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 25.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "SearchViewController.h"
#include "Item.h"
#import "TrackListViewController.h"
#include "UIKit/UIKit.h"
#import "QuickLookController.h"
#include "Foundation/Foundation.h"
#import "YandexConnect.h"
#import "../cYandexMusic/cYandexMusic.h"

@implementation SearchViewController
-(void)showError:(NSString *)msg{
	UIAlertView *alert = 
			[[UIAlertView alloc]initWithTitle:@"error" 
			message:msg 
			delegate:nil 
			cancelButtonTitle:@"Закрыть" 
			otherButtonTitles:nil];
	[alert show];
}

- (void)viewDidLoad {
	[self setTitle:@"Поиск"];
	
	self.sync = [[NSOperationQueue alloc]init];

	// allocate array
	self.best = [NSMutableArray array];
	self.tracks = [NSMutableArray array];
	self.podcasts = [NSMutableArray array];
	self.playlists = [NSMutableArray array];
	
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
}

int search_tracks(void *data, playlist_t *playlist, track_t *track, const char *error)
{
	SearchViewController *self = (__bridge SearchViewController *)data;
	if (error)
		[self showError:[NSString stringWithUTF8String:error]];

	if (track){
		Item *t = [[Item alloc]initWithTrack:track];
		dispatch_sync(dispatch_get_main_queue(), ^{
			// Update your UI
				if (!self.additional){
					[self.best addObject:t];
					self.additional = true;
				} else {
					if (t.itemType == ITEM_TRACK)
						[self.tracks addObject:t];
					else if (t.itemType == ITEM_PODCAST_EPOSODE)
						[self.podcasts addObject:t];
				}
			[self.tableView reloadData];
			[self.spinner stopAnimating];
			[self.refreshControl endRefreshing];
		});
	}
	else if (playlist){
		Item *t = [[Item alloc]initWithPlaylist:playlist];
		dispatch_sync(dispatch_get_main_queue(), ^{
			// Update your UI
			[self.playlists addObject:t];
			[self.tableView reloadData];
			[self.spinner stopAnimating];
			[self.refreshControl endRefreshing];
		});
	}
	return 0;

}

static int get_url(void *data, const char *url_str, const char *error){
	SearchViewController *self = (__bridge SearchViewController *)data;
	if (error)
		[self showError:[NSString stringWithUTF8String:error]];
	if (url_str){
		NSURL *url = [NSURL URLWithString:[NSString stringWithUTF8String:url_str]];
		QuickLookController *qc = 
				[[QuickLookController alloc]initQLPreviewControllerWithURL:url 
						title:self.selected.title trackId:self.selected.itemId];
		[self presentViewController:qc 
											 animated:TRUE completion:nil];
		return 1;
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
-(void)reloadData{
	// stop all sync
	[self.sync cancelAllOperations];

	if (!self.searchBar.text || self.searchBar.text.length < 1){
		[self.refreshControl endRefreshing];
		return;
	}
	NSString *token = 
		[[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
	if (!token)
		return;
	// animate spinner
	CGRect rect = self.view.bounds;
	self.spinner.center = CGPointMake(rect.size.width/2, rect.size.height/2);
	if (!self.refreshControl.refreshing)
		[self.spinner startAnimating];
	
	self.additional = false;
	
	[self.best removeAllObjects];
	[self.tracks removeAllObjects];
	[self.podcasts removeAllObjects];
	[self.playlists removeAllObjects];
	
	[self.tableView reloadData];
	
	//dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
	//dispatch_async(queue, ^{
  [self.sync addOperationWithBlock:^{
		c_yandex_music_search(
				[token UTF8String], 
				[self.searchBar.text UTF8String],
				"100x100",
				(__bridge void*)self, 
				search_tracks);
	}];
	//});
}

-(void)refresh:(id)sender{
	[self reloadData];
}

#pragma mark <TableViewDelegate Meythods>
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0: return @"Лучшее";
		case 1: return @"Треки";
		case 2: return @"Подкасты";
		case 3: return @"Плейлисты";
	}
	return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case 0: return self.best.count;
		case 1: return self.tracks.count;
		case 2: return self.podcasts.count;
		case 3: return self.playlists.count;
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSArray *data;
	switch (indexPath.section) {
		case 0: data = self.best; break;
		case 1: data = self.tracks; break;
		case 2: data = self.podcasts; break;
		case 3: data = self.playlists; break;
	}
	Item *item = [data objectAtIndex:indexPath.item];
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
	NSArray *data;
	switch (indexPath.section) {
		case 0: data = self.best; break;
		case 1: data = self.tracks; break;
		case 2: data = self.podcasts; break;
	}
	self.selected = [data objectAtIndex:indexPath.item];

	if (self.selected.itemType == ITEM_TRACK || self.selected.itemType == ITEM_PODCAST_EPOSODE){
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
	}	// unselect row
	[tableView deselectRowAtIndexPath:indexPath animated:true];
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// hide keyboard
	[self.searchBar resignFirstResponder];
}

#pragma mark <SEARCHBAR FUNCTIONS>

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
	[searchBar resignFirstResponder];
	[self reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
}
@end
// vim:ft=objc
