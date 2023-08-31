/**
 * File              : AppDelegate.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 09.08.2023
 * Last Modified Date: 31.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "Foundation/Foundation.h"
#import <UIKit/UIKit.h>
#import "PlayerController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong,nonatomic) NSURL *url;
@property (strong, nonatomic) PlayerController *player;
@property (strong) NSMutableArray *likedTracks;
-(void)playButtonPushed:(id)sender;
-(void)showMessage:(NSString *)msg;

@end

// vim:ft=objc
