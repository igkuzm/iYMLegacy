/**
 * File              : PlayerViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 31.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "PlayerViewController.h"
#import "PlayerViewController.h"
#include "Item.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"
#import "YandexConnect.h"
#import "../cYandexMusic/cYandexMusic.h"
#import "ActionSheet.h"

@implementation PlayerViewController

- (void)viewDidLoad {
	self.title = @"Плеер";
	self.appDelegate = [[UIApplication sharedApplication]delegate];
	self.loadedData = self.appDelegate.player.playlist;
	self.token = [[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
	self.liked = false;
	self.doLike = [[NSOperationQueue alloc]init];
	
	// ToolBar	
	self.navigationController.toolbarHidden = NO;
	self.like = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"info.circle.fill"] style:UIBarButtonItemStylePlain target:self action:@selector(likeIsPushed:)];
	self.space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];	
	self.share = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareIsPushed:)];
	[self setToolbarItems:@[self.like, self.space, self.share] animated:NO];

	// close button
	//self.closeButtonItem = 
		//[[UIBarButtonItem alloc]
			//initWithTitle:@"Закрыть" style:UIBarButtonItemStyleDone target:self action:@selector(closeButtonPushed:)];
	//self.navigationItem.leftBarButtonItem = self.closeButtonItem;

	// edit button
	self.navigationItem.rightBarButtonItem = self.editButtonItem;

	// refresh control
	self.refreshControl=
		[[UIRefreshControl alloc]init];
	[self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@""]];
	[self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];

	// search bar
	self.searchBar = 
		[[UISearchBar alloc] initWithFrame:CGRectMake(0,70,320,44)];
	self.tableView.tableHeaderView=self.searchBar;	
	self.searchBar.delegate = self;
	self.searchBar.placeholder = @"Поиск:";

	// editing style
	self.tableView.allowsMultipleSelectionDuringEditing = false;
	
	// load data
	//[self reloadData];
}

-(void)closeButtonPushed:(id)sender{
	[self.navigationController dismissViewControllerAnimated:true completion:nil];
}

-(void)editing:(BOOL)editing{
	[self setEditing:editing];
	if (self.editing)
		[self.navigationItem setHidesBackButton:YES animated:YES];
	else
		[self.navigationItem setHidesBackButton:NO animated:YES];
}

//hide searchbar by default
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
		[self reloadData];
    [self.tableView setContentOffset:CGPointMake(0, 44)];

		// check track is liked
		[self.appDelegate.player setDelegate:self];
		if (self.appDelegate.player.current >=0){
			self.current = [self.appDelegate.player.playlist objectAtIndex:self.appDelegate.player.current]; 
			if (self.current)
				[self checkTrackIsLiked:self.current];
		}
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

-(void)checkTrackIsLiked:(Item *)track{
	self.liked = NO;
	for (Item *item in self.appDelegate.likedTracks){
		if ([item.itemId isEqual:track.itemId]){
			self.liked = YES;
			break;
		}
	}

	if (self.liked){
		[self.like setImage:[UIImage imageNamed:@"heart_fill"]];	
		[self setToolbarItems:@[self.like, self.space, self.share] animated:NO];
	} 
	else{
		[self.like setImage:[UIImage imageNamed:@"heart"]];	
		[self setToolbarItems:@[self.like, self.space, self.share] animated:NO];
	}
}

void like_callback(void *data, const char *error){
	PlayerViewController *self = (__bridge PlayerViewController *)data;
	if (error){
		NSLog(@"%s", error);
		//[self.appDelegate showMessage:@"error" title:[NSString stringWithUTF8String:error]];
		//return;
	}
	
	self.liked = !self.liked;
}

-(void)shareIsPushed:(id)sender{
	UIActionSheet *as = [[UIActionSheet alloc]	
			initWithTitle:@"Плейлист" 
					 delegate:self 
					 cancelButtonTitle:@"отмена" 
					 destructiveButtonTitle:nil 
					 otherButtonTitles:
													@"сохранить плейлист", nil];
	[as showInView:self.tableView];
}

-(void)likeIsPushed:(id)sender{
	if (self.appDelegate.player.current < 0)
		return;
	if (!self.token)
		return;
	
	NSInteger uid = 
			[[NSUserDefaults standardUserDefaults]integerForKey:@"uid"];
		if (!uid)
			return;

		if (self.liked){
			[self.like setImage:[UIImage imageNamed:@"heart"]];	
			[self setToolbarItems:@[self.like, self.space, self.share] animated:NO];
			[self.doLike cancelAllOperations];
			[self.doLike addOperationWithBlock:^{
					c_yandex_music_set_unlike_current(
							[self.token UTF8String], 
							uid, [self.current.itemId UTF8String], 
							(__bridge void *)self, like_callback);
			}];
		}
		else {
			[self.doLike cancelAllOperations];
			[self.doLike addOperationWithBlock:^{
			[self.like setImage:[UIImage imageNamed:@"heart_fill"]];	
			[self setToolbarItems:@[self.like, self.space, self.share] animated:NO];
					c_yandex_music_set_like_current(
							[self.token UTF8String], 
							uid, [self.current.itemId UTF8String], 
							(__bridge void *)self, like_callback);
			}];
		} 
}

#pragma mark <PlayerControllerDelegate Meythods>
-(void)playerControllerStartPlayTrack:(Item *)track{
	self.current = track;
	[self checkTrackIsLiked:track];
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
	if (self.appDelegate.player.current == indexPath.item)
	{
		cell = [self.tableView dequeueReusableCellWithIdentifier:@"player"];
		if (cell == nil){
			cell = [[UITableViewCell alloc]
			initWithStyle: UITableViewCellStyleSubtitle 
			reuseIdentifier: @"player"];
		}
		[self.appDelegate.player.view removeFromSuperview];
		[self.appDelegate.player setControlStyle:MPMovieControlStyleEmbedded];
		[self.appDelegate.player.view setFrame:cell.contentView.frame];
		[self.appDelegate.player setScalingMode:MPMovieScalingModeAspectFill];
		[cell.contentView addSubview:self.appDelegate.player.view];
	} else {
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return true;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete){
		self.selected = [self.data objectAtIndex:indexPath.item];
			UIAlertView *alert = 
				[[UIAlertView alloc]initWithTitle:@"Удалить трек из листа?" 
				message:self.selected.title 
				delegate:self 
				cancelButtonTitle:@"Отмена" 
				otherButtonTitles:@"Удалить", nil];
			[alert show];
	}
}

#pragma mark <ACTION SHEET DELEGATE>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	AppDelegate *a = [[UIApplication sharedApplication]delegate];
	switch (buttonIndex){
		case 0: 
			{
				//TextEditViewController *vc = [[TextEditViewController alloc]init];
				//vc.delegate = self;
				//vc.title = @"Название";
				//[self.navigationController pushViewController:vc animated:YES];
				break;
			}
	
		default:
			{
				break;
			} 
	}
}
static void on_error(void *data, const char *error){
	PlayerViewController *self = (__bridge PlayerViewController *)data;
	if (error){
		NSLog(@"%s", error);
		//[self.appDelegate showMessage:[NSString stringWithUTF8String:error]];	
	}
}

-(void)textEditViewControllerSaveText:(NSString *)text{
	// create new playlist
	if (!self.token)
		return;
	NSInteger uid = 
			[[NSUserDefaults standardUserDefaults]integerForKey:@"uid"];
		if (!uid)
			return;
	
	playlist_t *p = c_yandex_music_create_playlist(
			[self.token UTF8String], uid, [text UTF8String], 
			(__bridge void *)self, on_error);

	if (p){
		// get all tracks
		int count = self.appDelegate.player.playlist.count;
		long track_ids[count];
		long album_ids[count];
		int i = 0;
		for (Item *item in self.appDelegate.player.playlist){
			track_ids[i] = [item.itemId intValue];	
			album_ids[i] = item.albumId;	
			i++;
		}
		c_yandex_music_playlist_add_tracks(
				[self.token UTF8String], uid, p->kind, 
				track_ids, album_ids, count, 
				(__bridge void *)self, on_error);
	}
}
#pragma mark <ALERT DELEGATE FUNCTIONS>
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1){
		[self.loadedData removeObject:self.selected];
		[self filterData];
	}
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
