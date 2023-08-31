/**
 * File              : SearchViewControllerDetail.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 29.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "Item.h"

@interface SearchViewControllerDetail : UITableViewController
<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIActionSheetDelegate>
@property (strong) AppDelegate *appDelegate;
@property (strong) Item *selected;
@property (strong) NSArray *data;
- (id)initWithData:(NSArray *)data title:(NSString *)title;
@end

// vim:ft=objc
