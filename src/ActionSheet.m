/**
 * File              : ActionSheet.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 28.08.2023
 * Last Modified Date: 28.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "ActionSheet.h"
#include "UIKit/UIKit.h"
#import "AppDelegate.h"

@implementation ActionSheet
- (id)initWithItem:(Item *)item onDone:(void (^)())onDone
{
	if (self = [super 
			initWithTitle:item.title 
					 delegate:self 
					 cancelButtonTitle:@"отмена" 
					 destructiveButtonTitle:nil 
					 otherButtonTitles:
													@"играть", 
													@"играть следующей",
												  @"добавить в плэйлист",	nil]) 
	{
		self.item = item;
		self.onDone = onDone;
	}
	return self;
}

#pragma mark <ACTION SHEET DELEGATE>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	AppDelegate *a = [[UIApplication sharedApplication]delegate];
	switch (buttonIndex){
		case 0: 
			{
				[a.player addToTopAndPlay:self.item onDone:self.onDone];
				break;
			}
		case 1:
			{
				[a.player addAfterCurrent:self.item];
				if (self.onDone)
					self.onDone();
				break;
			}
		case 2:
			{
				[a.player addToLast:self.item];
				if (self.onDone)
					self.onDone();
				break;
			}
		
		default: break;
	}
}
@end

// vim:ft=objc
