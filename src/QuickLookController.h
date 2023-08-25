/**
 * File              : QuickLookController.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 28.07.2021
 * Last Modified Date: 25.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#include "Foundation/Foundation.h"
#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>

@interface PreviewItem : NSObject <QLPreviewItem>
@property (strong) NSURL *previewItemURL;
@property (strong) NSString *previewItemTitle;
@end

@interface QuickLookController : QLPreviewController <QLPreviewControllerDataSource, QLPreviewControllerDelegate, NSURLConnectionDelegate>
@property (strong,nonatomic) NSMutableData *mutableData;
@property (strong) PreviewItem *previewItem;
@property (strong) NSString *trackId;
-(QuickLookController *)initQLPreviewControllerWithURL:(NSURL *)url 
																								 title:(NSString *)title trackId:(NSString *)trackId;
@end

// vim:ft=objc
