/**
 * File              : RecentsViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 29.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "RecentsViewController.h"
#import "PlayerViewController.h"
#include "Item.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"
#import "YandexConnect.h"
#import "../cYandexMusic/cYandexMusic.h"
#import "ActionSheet.h"

@implementation RecentsViewController

- (void)viewDidLoad {
	self.title = @"Недавние";
	self.appDelegate = [[UIApplication sharedApplication]delegate];
	self.loadedData = [NSMutableArray array];
	self.token = [[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
	
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
	UIBarButtonItem *playButtonItem = 
		[[UIBarButtonItem alloc]
				initWithBarButtonSystemItem:UIBarButtonSystemItemPlay 
				target:self.appDelegate action:@selector(playButtonPushed:)]; 
	self.navigationItem.rightBarButtonItem = playButtonItem;

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
	[self filterData];
	[self.refreshControl endRefreshing];
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
	}
	item.imageView = cell.imageView;
	[cell.textLabel setText:item.title];
	[cell.detailTextLabel setText:item.subtitle];	
	if (item.coverImage)
		[cell.imageView setImage:item.coverImage];
	if (self.appDelegate.player.current == indexPath.item)
	{
		[self.appDelegate.player.view removeFromSuperview];
		[self.appDelegate.player setControlStyle:MPMovieControlStyleEmbedded];
		[self.appDelegate.player.view setFrame:cell.contentView.frame];
		[self.appDelegate.player setScalingMode:MPMovieScalingModeAspectFill];
		[cell.contentView addSubview:self.appDelegate.player.view];
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	__block UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	cell.accessoryView = spinner; 
	[spinner startAnimating];

	self.appDelegate.player.current = indexPath.item;
	[self.appDelegate.player playCurrent:^{
		[spinner stopAnimating];
		[spinner removeFromSuperview];
		[cell setAccessoryView:nil];
		[self refresh:nil];
	}];
	//self.selected = [self.data objectAtIndex:indexPath.item];
	//UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		//UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)cell.accessoryView;
		//[spinner startAnimating];
		//ActionSheet *as = [[ActionSheet alloc]initWithItem:self.selected onDone:^{
			//[spinner stopAnimating];
		//}];
		//[as showInView:tableView];
		
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
