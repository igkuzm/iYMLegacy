/**
 * File              : FavoritesViewController.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 23.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
@interface FavoritesViewController : UITableViewController
<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIActionSheetDelegate>
@property (strong) NSArray *data;
@property (strong) NSMutableArray *loadedData;
@property (strong) UISearchBar *searchBar;
@property (strong) UIActivityIndicatorView *spinner;
@end

// vim:ft=objc
