/**
 * File              : FavoritesViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 23.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "FavoritesViewController.h"
#include "Foundation/Foundation.h"
#import "YandexConnect.h"
#import "../cYandexMusic/cYandexMusic.h"
@interface Track : NSObject
@property (strong) NSString *title;
@property (strong) NSURL *coverUri;
@end
@implementation Track
@end

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

int get_feed(void *data, track_t *track, const char *error)
{
	FavoritesViewController *self = data;
	if (error)
		[self showError:[NSString stringWithUTF8String:error]];

	if (track){
		Track *t = [[Track alloc]init];
		if (track->title)
			[t setTitle:[NSString stringWithUTF8String:track->title]];
		if (track->coverUri)
			[t setCoverUri:[NSURL URLWithString:[NSString stringWithUTF8String:track->coverUri]]];
		[self.loadedData addObject:t];
		[self filterData];
		//c_yandex_music_track_free(track);
	}

	return 0;
}

- (void)viewDidLoad {
	
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
	// add buttons
	UIBarButtonItem *addButtonItem = 
		[[UIBarButtonItem alloc]
				initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
				target:self action:@selector(addButtonPushed:)]; 
	self.navigationItem.rightBarButtonItem = addButtonItem;
	
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

	// allocate array
	self.loadedData = [NSMutableArray array];

	// load data
	[self reloadData];

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
	// animate spinner
	CGRect rect = self.view.bounds;
	self.spinner.center = CGPointMake(rect.size.width/2, rect.size.height/2);
	if (!self.refreshControl.refreshing)
		[self.spinner startAnimating];

	dispatch_async(dispatch_get_main_queue(), ^{
		[self.loadedData removeAllObjects];
		c_yandex_music_get_feed([token UTF8String], self, get_feed);
		[self.spinner stopAnimating];
		[self.refreshControl endRefreshing];
	});
}

-(void)refresh:(id)sender{
	[self reloadData];
}

-(void)addButtonPushed:(id)selector{
	//FilePickerController *fc;
	//if (self.file)
		//fc = 
			//[[FilePickerController alloc]initWithPath:@"/" ydDir:self.file.path new:true];
	//else 
		//fc = 
			//[[FilePickerController alloc]initWithPath:@"/" ydDir:@"disk:" new:true];
	//UINavigationController *nc =
		//[[UINavigationController alloc]initWithRootViewController:fc];
	//[self presentViewController:nc 
			//animated:TRUE completion:nil];
}

#pragma mark - TableViewDelegate Meythods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	Track *track = [self.data objectAtIndex:indexPath.item];
	//YDFile *file = [self.data objectAtIndex:indexPath.item];
	UITableViewCell *cell = nil;
	cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (cell == nil){
		cell = [[UITableViewCell alloc]
		initWithStyle: UITableViewCellStyleDefault 
		reuseIdentifier: @"cell"];
		//cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		//cell.imageView.image = [UIImage imageNamed:@"Directory"];
	}
	//cell.detailTextLabel.text = [NSString stringWithFormat:@"%d Mb", self.selected.size/1024];
	
	[cell.textLabel setText:track.title];
	return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	//self.selected = [self.data objectAtIndex:indexPath.item];
	// open menu
	//UIActionSheet *as = 
			//[[UIActionSheet alloc]
				//initWithTitle:self.selected.name 
				//delegate:self 
				//cancelButtonTitle:@"Отмена" 
				//destructiveButtonTitle:@"Удалить" 
				//otherButtonTitles:@"Загрузить ZIP", @"Поделиться", nil];
	//[as showInView:tableView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	//self.selected = [self.data objectAtIndex:indexPath.item];
	//if ([self.selected.type isEqual:@"dir"]){
		//// open directory in new controller
		//RootViewController *vc = [[RootViewController alloc]initWithFile:self.selected];
		//[self.navigationController pushViewController:vc animated:true];
		//// unselect row
		//[tableView deselectRowAtIndexPath:indexPath animated:true];
		//return;
	//}
	//// open menu
	//UIActionSheet *as = 
			//[[UIActionSheet alloc]
				//initWithTitle:self.selected.name 
				//delegate:self 
				//cancelButtonTitle:@"Отмена" 
				//destructiveButtonTitle:@"Удалить" 
				//otherButtonTitles:@"Открыть/Загрузить", @"Поделиться", nil];
	//[as showInView:tableView];
	//// unselect row
	//[tableView deselectRowAtIndexPath:indexPath animated:true];
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// hide keyboard
	[self.searchBar resignFirstResponder];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	//YDFile *file = [self.data objectAtIndex:indexPath.item];
	return true;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	//self.selected = nil;
	//if (editingStyle == UITableViewCellEditingStyleDelete){
		//self.selected = [self.data objectAtIndex:indexPath.item];
			//UIAlertView *alert = 
				//[[UIAlertView alloc]initWithTitle:@"Удалить файл?" 
				//message:self.selected.name 
				//delegate:self 
				//cancelButtonTitle:@"Отмена" 
				//otherButtonTitles:@"Удалить", nil];
			//[alert show];
	//}
}

#pragma mark <SEARCHBAR FUNCTIONS>

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
	[self filterData];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
}

#pragma mark <ALERT DELEGATE FUNCTIONS>
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	//if (buttonIndex == 1){
		//NSString *token = 
				//[[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
		
		//char *error = NULL;
		//int res = c_yandex_disk_rm([token UTF8String], [self.selected.path UTF8String], &error);
		//if (error){
			//NSLog(@"%s", error);
			//UIAlertView *alert = 
				//[[UIAlertView alloc]initWithTitle:@"error" 
				//message:[NSString stringWithUTF8String:error] 
				//delegate:self 
				//cancelButtonTitle:@"Закрыть" 
				//otherButtonTitles:nil];
			//[alert show];
			//free(error);
			//return;
		//}
		//[self.loadedData removeObject:self.selected];
		//[self filterData];
	//}
}
#pragma mark <ACTION SHEET DELEGATE>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	//if (buttonIndex == 0){
		//// delete
			//UIAlertView *alert = 
				//[[UIAlertView alloc]initWithTitle:@"Удалить файл?" 
				//message:self.selected.name 
				//delegate:self 
				//cancelButtonTitle:@"Отмена" 
				//otherButtonTitles:@"Удалить", nil];
			//[alert show];

	//} else if (buttonIndex == 1 || buttonIndex == 2){
		//NSString *token = 
			//[[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
		//char *error = NULL;
		//char *fileurl = c_yandex_disk_file_url([token UTF8String], 
				//[self.selected.path UTF8String], &error);
		//if (error){
			//NSLog(@"%s", error);
			//UIAlertView *alert = 
				//[[UIAlertView alloc]initWithTitle:@"error" 
				//message:[NSString stringWithUTF8String:error] 
				//delegate:nil 
				//cancelButtonTitle:@"Закрыть" 
				//otherButtonTitles:nil];
			//[alert show];
			//free(error);
		//}
		//if (buttonIndex == 1){
			//// open
			//if (fileurl){
				//NSURL *url = [NSURL URLWithString:[NSString stringWithUTF8String:fileurl]];
				//free(fileurl);
				//[[UIApplication sharedApplication]openURL:url];
			//}
		//} else {
			//// make link
			//if (fileurl){
				//char *error = NULL;
				//c_yandex_disk_publish([token UTF8String], [self.selected.path UTF8String], &error);
				//if (error){
					//NSLog(@"%s", error);
					//UIAlertView *alert = 
							//[[UIAlertView alloc]initWithTitle:@"error" 
							//message:[NSString stringWithUTF8String:error] 
							//delegate:nil 
							//cancelButtonTitle:@"Закрыть" 
							//otherButtonTitles:nil];
					//[alert show];
					//free(error);
					//error = NULL;
				//}
				//c_yd_file_t f;
				//c_yandex_disk_file_info([token UTF8String], [self.selected.path UTF8String], &f, &error);
				//if (error){
					//NSLog(@"%s", error);
					//UIAlertView *alert = 
							//[[UIAlertView alloc]initWithTitle:@"error" 
							//message:[NSString stringWithUTF8String:error] 
							//delegate:nil 
							//cancelButtonTitle:@"Закрыть" 
							//otherButtonTitles:nil];
					//[alert show];
					//free(error);
					//error = NULL;
				//}
				//if (strlen(f.public_url)>0){
					//NSString *str = [NSString stringWithUTF8String:f.public_url];
					//NSURL *url = [NSURL URLWithString:str];
					//// copy to clipboard
					//[UIPasteboard generalPasteboard].URL = url;
					//[UIPasteboard generalPasteboard].string = str;
					////show massage
					//UIAlertView *alert = 
							//[[UIAlertView alloc]initWithTitle:@"Сылка скопирована в буфер" 
							//message:str 
							//delegate:nil 
							//cancelButtonTitle:@"Ок" 
							//otherButtonTitles:nil];
					//[alert show];
				//}
			//}
		//}
	//}
}
@end
// vim:ft=objc
