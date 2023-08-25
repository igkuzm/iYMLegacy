/**
 * File              : SearchViewController.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 25.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "Item.h"

@interface SearchViewController : UITableViewController
<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIActionSheetDelegate>
@property (strong) Item *selected;
@property BOOL additional;
@property (strong) NSMutableArray *best;
@property (strong) NSMutableArray *tracks;
@property (strong) NSMutableArray *podcasts;
@property (strong) NSMutableArray *playlists;
@property (strong) UISearchBar *searchBar;
@property (strong) UIActivityIndicatorView *spinner;
@property (strong) NSOperationQueue *sync;
@end

// vim:ft=objc
