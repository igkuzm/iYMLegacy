/**
 * File              : SearchViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 13.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "SearchViewController.h"
#import "SearchViewControllerDetail.h"
#include "Item.h"
#import "TrackListViewController.h"
#include "UIKit/UIKit.h"
#import "PlayerViewController.h"
#include "Foundation/Foundation.h"
#import "YandexConnect.h"
#import "../cYandexMusic/cYandexMusic.h"
#import "ActionSheet.h"

@implementation SearchViewController

- (void)viewDidLoad {
	[self setTitle:@"Поиск"];
	
	self.syncData = [[NSOperationQueue alloc]init];

	self.token = 
		[[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
	// allocate array
	self.best = [NSMutableArray array];
	self.tracks = [NSMutableArray array];
	self.podcasts = [NSMutableArray array];
	self.albums = [NSMutableArray array];
	self.playlists = [NSMutableArray array];
	
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

	// play button
	//UIBarButtonItem *playButtonItem = 
		//[[UIBarButtonItem alloc]
				//initWithBarButtonSystemItem:UIBarButtonSystemItemPlay 
				//target:self.appDelegate action:@selector(playButtonPushed:)]; 
	//self.navigationItem.rightBarButtonItem = playButtonItem;

	//spinner
	self.spinner = 
		[[UIActivityIndicatorView alloc] 
		initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[self.tableView addSubview:self.spinner];
	self.spinner.tag = 12;
}

int search_tracks(void *data, playlist_t *playlist, album_t *album, track_t *track, const char *error)
{
	SearchViewController *self = (__bridge SearchViewController *)data;
	if (error){
		NSLog(@"%s", error);
	}

	if (track){
		Item *t = [[Item alloc]initWithTrack:track token:self.token];
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
	if (playlist){
		Item *t = [[Item alloc]initWithPlaylist:playlist token:self.token];
		dispatch_sync(dispatch_get_main_queue(), ^{
			// Update your UI
			[self.playlists addObject:t];
			[self.tableView reloadData];
			[self.spinner stopAnimating];
			[self.refreshControl endRefreshing];
		});
	} 
	if (album){
		Item *t = [[Item alloc]initWithAlbum:album token:self.token];
		dispatch_sync(dispatch_get_main_queue(), ^{
			// Update your UI
			if (t.itemType == ITEM_ALBUM)
				[self.albums addObject:t];
			else if (t.itemType == ITEM_PODCAST)
				[self.podcasts addObject:t];
			[self.tableView reloadData];
			[self.spinner stopAnimating];
			[self.refreshControl endRefreshing];
		});
	}
	return 0;

}

-(void)reloadData{
	// stop all sync
	[self.syncData cancelAllOperations];

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
	[self.albums removeAllObjects];
	
	[self.tableView reloadData];
	
  [self.syncData addOperationWithBlock:^{
		c_yandex_music_search(
				[token UTF8String], 
				[self.searchBar.text UTF8String],
				"100x100",
				(__bridge void*)self, 
				search_tracks);
	}];
}

-(void)refresh:(id)sender{
	[self reloadData];
}

#pragma mark <TableViewDelegate Meythods>
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 5;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0: return @"Лучшее";
		case 1: return (self.tracks.count > 1 )?@"":@"Треки";
		case 2: return (self.albums.count > 1 )?@"":@"Альбомы";
		case 3: return (self.podcasts.count >1)?@"":@"Подкасты";
		case 4: return (self.playlists.count>1)?@"":@"Плейлисты";
	}
	return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case 0: return self.best.count;
		case 1: return (self.tracks.count > 0)?1:0;
		case 2: return (self.albums.count > 0)?1:0;
		case 3: return (self.podcasts.count > 0)?1:0;
		case 4: return (self.playlists.count > 0)?1:0;
		default: return 0;
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	if (indexPath.section == 0){
		NSArray *data = self.best;
		Item *item = [data objectAtIndex:indexPath.item];
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
	} else { // button for detail view
		cell = [self.tableView dequeueReusableCellWithIdentifier:@"detail"];
			if (cell == nil){
				cell = [[UITableViewCell alloc]
				initWithStyle: UITableViewCellStyleSubtitle 
				reuseIdentifier: @"detail"];
			}
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			NSString *label = @"";
			switch (indexPath.section) {
				case 1: label = @"Треки"; break;
				case 2: label = @"Альбомы"; break;
				case 3: label = @"Подкасты"; break;
				case 4: label = @"Плейлисты"; break;
			}

			cell.textLabel.text = label;
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0){
		NSArray *data = self.best;
		self.selected = [data objectAtIndex:indexPath.item];
		
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
				//[as showInView:self.view];		
				[as showFromTabBar:self.tabBarController.tabBar];
			}
		}
		else if (self.selected.itemType == ITEM_PLAYLIST ||
						 self.selected.itemType == ITEM_PODCAST  ||
						 self.selected.itemType == ITEM_ALBUM)
		{
				TrackListViewController *vc = [[TrackListViewController alloc]initWithParent:
																				self.selected];
				[self.navigationController pushViewController:vc animated:true];
		}	
	} else {
		NSArray *data;
		switch (indexPath.section) {
			case 1: data = self.tracks; break;
			case 2: data = self.albums; break;
			case 3: data = self.podcasts; break;
			case 4: data = self.playlists; break;
		}
		NSString *label = @"";
			switch (indexPath.section) {
				case 1: label = @"Треки"; break;
				case 2: label = @"Альбомы"; break;
				case 3: label = @"Подкасты"; break;
				case 4: label = @"Плейлисты"; break;
			}
		SearchViewControllerDetail *vc = [[SearchViewControllerDetail alloc]initWithData:data title:label];
		[self.navigationController pushViewController:vc animated:YES];
	}
	// unselect row
	[tableView deselectRowAtIndexPath:indexPath animated:true];
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// hide keyboard
	[self.searchBar resignFirstResponder];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	self.selected = [self.best objectAtIndex:indexPath.item];
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
