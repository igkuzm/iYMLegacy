/**
 * File              : TrackListViewController.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 25.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "Item.h"
@interface TrackListViewController : UITableViewController
<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIActionSheetDelegate>
@property (strong) Item *selected;
@property (strong) NSArray *data;
@property (strong) NSMutableArray *loadedData;
@property (strong) UISearchBar *searchBar;
@property (strong) UIActivityIndicatorView *spinner;
- (id)initWithTitle:(NSString *)title;
-(void)showError:(NSString *)msg;
-(void)filterData;
@end

// vim:ft=objc
