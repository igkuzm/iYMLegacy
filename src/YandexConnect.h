/**
 * File              : YandexConnect.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 09.08.2023
 * Last Modified Date: 22.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import <UIKit/UIKit.h>

@interface YandexConnect : UIViewController <UIWebViewDelegate>
{
}
@property (strong) UIWebView *webView;
@property CGRect frame;
@property (strong) UIActivityIndicatorView *spinner;
- (id)initWithFrame:(CGRect)frame;

@end
// vim:ft=objc
