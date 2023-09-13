/**
 * File              : FavoritesViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 13.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "FavoritesViewController.h"
#include "AppDelegate.h"
#import "TrackListViewController.h"
#include "Item.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"
#import "YandexConnect.h"
#import "YandexConnect.h"
#import "../cYandexMusic/cYandexMusic.h"
#import "PlayerViewController.h"
#import "ActionSheet.h"

@implementation FavoritesViewController

- (id)init
{
	if (self = [super init]) {
		self.appDelegate = [[UIApplication sharedApplication]delegate];
	
		self.syncData = [[NSOperationQueue alloc]init];
		// allocate array
		self.loadedData = self.appDelegate.likedTracks;
		self.data = [NSArray array];

		// cache
		self.cache = 
				[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) 
						objectAtIndex:0] stringByAppendingPathComponent:@"favorites.plist"];
		self.cacheLoaded = NO;
		self.needRefresh = NO;

		// check token
		NSString *token = 
			[[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
		self.token = token;
		// get uid
		NSInteger uid = 
			[[NSUserDefaults standardUserDefaults]integerForKey:@"uid"];
		if (!uid){
			if (token)
				uid = c_yandex_music_get_uid([token UTF8String]);
			if (uid)
				[[NSUserDefaults standardUserDefaults]setInteger:uid forKey:@"uid"];
		}
		
		[self setViewIsLoaded:NO];
		[self reloadData];
	}
	return self;
}

- (void)viewDidLoad {
	[self setTitle:@"Избранное"];	
	
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

	[self setViewIsLoaded:YES];
}

static int get_favorites(void *data, track_t *track, const char *error)
{ 
	FavoritesViewController *self = (__bridge FavoritesViewController *)data;
	if (error){
		NSLog(@"%s", error);
	}

	if (track){
		Item *t = [[Item alloc]initWithTrack:track token:self.token];
		[self.loadedData addObject:t];
		if ((self.viewIsLoaded && !self.cacheLoaded) || self.needRefresh){
			dispatch_sync(dispatch_get_main_queue(), ^{
				// Update your UI
					[self filterData];
					[self.spinner stopAnimating];
					[self.refreshControl endRefreshing];
			});
		}
	}
	return 0;
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
	// stop all sync
	[self.syncData cancelAllOperations];
	
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

	[self.loadedData removeAllObjects];
	[self.tableView reloadData];
	
	//load data from cache
	//if (!self.cacheLoaded){
		//NSData *codedData = [NSData dataWithContentsOfFile:self.cache];
		//if (codedData){
			//NSKeyedUnarchiver *unarchiver = 
					//[[NSKeyedUnarchiver alloc]initForReadingWithData:codedData];
			//NSArray *array = 
				//[unarchiver decodeObjectForKey:@"favorites"]; 
			//[unarchiver finishDecoding];
			//if (array){
				//for (Item *item in array){
					//[self.loadedData addObject:item];
				//}
				//[self filterData];
				//[self.spinner stopAnimating];
				//[self.refreshControl endRefreshing];
				//self.cacheLoaded = YES;
			//}
		//}
	//}

	[self.syncData addOperationWithBlock:^{
		c_yandex_music_get_favorites(
				[token UTF8String], 
				"100x100", uid, 
				(__bridge void *)self, 
				get_favorites);
		//NSMutableData *data = [NSMutableData data];
		//NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
		//[archiver encodeObject:self.loadedData forKey:@"favorites"];
		//[archiver finishEncoding];
		//[data writeToFile:self.cache atomically:YES];
		//self.needRefresh = NO;
	}];	
}

-(void)refresh:(id)sender{
	self.needRefresh = YES;
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
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)cell.accessoryView;
		[spinner startAnimating];
		ActionSheet *as = [[ActionSheet alloc]initWithItem:self.selected isDir:NO onDone:^{
			[spinner stopAnimating];
		}];
		//[as showInView:self.view];
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
