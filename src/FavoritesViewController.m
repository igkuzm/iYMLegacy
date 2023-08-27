/**
 * File              : FavoritesViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 27.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "FavoritesViewController.h"
#import "TrackListViewController.h"
#include "Item.h"
#include "UIKit/UIKit.h"
#import <AVFoundation/AVFoundation.h>
#import "QuickLookController.h"
#import "AudioPlayer.h"
#include "Foundation/Foundation.h"
#import "YandexConnect.h"
#import "YandexConnect.h"
#import "../cYandexMusic/cYandexMusic.h"

@implementation FavoritesViewController
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
	FavoritesViewController *self = (__bridge FavoritesViewController *)data;
	if (error)
		[self showError:[NSString stringWithUTF8String:error]];
	if (url_str){
		NSURL *url = [NSURL URLWithString:[NSString stringWithUTF8String:url_str]];
		dispatch_sync(dispatch_get_main_queue(), ^{
				[self.cellSpinner stopAnimating];
				AudioPlayer *ap = [[AudioPlayer alloc]
				initWiithURL:url title:self.selected.title trackId:self.selected.itemId];
				UINavigationController *nc = [[UINavigationController alloc]initWithRootViewController:ap];
				[self presentViewController:nc animated:TRUE completion:nil];
		});

		return 1;
	}
	return 0;
}

static int get_favorites(void *data, track_t *track, const char *error)
{ 
	FavoritesViewController *self = (__bridge FavoritesViewController *)data;
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
	return 0;
}

- (void)viewDidLoad {
	[self setTitle:@"Избранное"];	
	
	self.URLsync = [[NSOperationQueue alloc]init];
	// allocate array
	self.loadedData = [NSMutableArray array];
	self.data = [NSArray array];
	
	// check token
	NSString *token = 
		[[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
	// get uid
	NSInteger uid = 
		[[NSUserDefaults standardUserDefaults]integerForKey:@"uid"];
	if (!uid){
		if (token)
			uid = c_yandex_music_get_uid([token UTF8String]);
		if (uid)
			[[NSUserDefaults standardUserDefaults]setInteger:uid forKey:@"uid"];
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

	NSInteger uid = 
		[[NSUserDefaults standardUserDefaults]integerForKey:@"uid"];
	if (!uid)
		return;
		
	// animate spinner
	CGRect rect = self.view.bounds;
	self.spinner.center = CGPointMake(rect.size.width/2, rect.size.height/2);
	if (!self.refreshControl.refreshing)
		[self.spinner startAnimating];
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
	dispatch_async(queue, ^{
		[self.loadedData removeAllObjects];
		c_yandex_music_get_favorites(
				[token UTF8String], "100x100", uid, (__bridge void *)self, get_favorites);
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
	cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (cell == nil){
		cell = [[UITableViewCell alloc]
		initWithStyle: UITableViewCellStyleSubtitle 
		reuseIdentifier: @"cell"];
		cell.accessoryView = 
			[[UIActivityIndicatorView alloc] 
			initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
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
	[self.URLsync cancelAllOperations];
	
	NSString *token = [[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
	if (token){
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		UIActivityIndicatorView *spinner = 
			(UIActivityIndicatorView*)cell.accessoryView;
		[spinner startAnimating];
		self.cellSpinner = spinner;
		[self.URLsync addOperationWithBlock:^{
				c_yandex_music_get_download_url(
						[token UTF8String], [self.selected.itemId UTF8String], 
						(__bridge void *)self, get_url);
		}];
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
