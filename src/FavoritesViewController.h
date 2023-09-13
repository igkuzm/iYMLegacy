/**
 * File              : FavoritesViewController.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 13.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "Item.h"
@interface FavoritesViewController : UITableViewController
<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIActionSheetDelegate>
@property BOOL viewIsLoaded;
@property (strong) AppDelegate *appDelegate;
@property (strong) Item *selected;
@property (strong) NSString  *cache;
@property BOOL cacheLoaded;
@property BOOL needRefresh;
@property (strong) NSString  *token;
@property (strong) NSArray *data;
@property (strong) NSMutableArray *loadedData;
@property (strong) UISearchBar *searchBar;
@property (strong) UIActivityIndicatorView *spinner;
@property (strong) NSOperationQueue *syncData;
@property (strong) UIActivityIndicatorView *cellSpinner;
@end

// vim:ft=objc
