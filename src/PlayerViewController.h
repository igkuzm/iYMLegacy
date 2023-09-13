/**
 * File              : PlayerViewController.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 10.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "Item.h"
#import "TextEditViewController.h"
@interface PlayerViewController : UITableViewController
<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIActionSheetDelegate, PlayerControllerDelegate, UIActionSheetDelegate, TextEditViewControllerDelegate>
@property (strong) AppDelegate *appDelegate;
@property (strong) Item  *selected;
@property (strong) Item  *current;
@property (strong, nonatomic) UIBarButtonItem *closeButtonItem;
@property (strong) NSString  *token;
@property (strong) NSArray *data;
@property (strong) NSMutableArray *loadedData;
@property (strong) UISearchBar *searchBar;
@property (strong) UILabel *label;
@property (strong) UILabel *subLabel;
@property (strong) UIBarButtonItem *like;
@property (strong) UIBarButtonItem *space;
@property (strong) UIBarButtonItem *share;
@property BOOL liked;
@property (strong) NSOperationQueue *doLike;
@end

// vim:ft=objc
