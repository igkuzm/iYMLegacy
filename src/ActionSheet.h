/**
 * File              : ActionSheet.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 28.08.2023
 * Last Modified Date: 28.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "Item.h"
@interface ActionSheet : UIActionSheet <UIActionSheetDelegate>
@property (strong) Item *item;
@property (copy) void (^onDone)();
- (id)initWithItem:(Item *)item onDone:(void (^)())onDone;
@end

// vim:ft=objc
