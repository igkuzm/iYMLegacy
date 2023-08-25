/**
 * File              : YandexConnect.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 09.08.2023
 * Last Modified Date: 23.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "YandexConnect.h"
#include "CoreGraphics/CoreGraphics.h"
#include <time.h>
#include "UIKit/UIKit.h"
#include <stdio.h>
#include "Foundation/Foundation.h"
#include "../cYandexMusic/cYandexMusic.h"

@implementation YandexConnect

- (id)initWithFrame:(CGRect)frame {
	if (self = [super init]) {
		self.frame = frame;
		//self.view = [[UIView alloc]initWithFrame:frame];
		[self.view setFrame:frame];
	}
	return self;
}

- (void)viewDidLoad {
		// load webview
		self.webView = [[UIWebView alloc]initWithFrame:self.frame];
		[self.view addSubview:self.webView];
		[self.webView setDelegate:self];
		
		//spinner
		self.spinner = 
		[[UIActivityIndicatorView alloc] 
		initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		[self.view addSubview:self.spinner];
		self.spinner.tag = 12;

		// animate spinner
		CGRect rect = self.view.bounds;
		self.spinner.center = CGPointMake(rect.size.width/2, rect.size.height/2);
		[self.spinner startAnimating];

		char *urlstr = c_yandex_oauth_url();
		if (urlstr){
			NSURL *url = [NSURL URLWithString:[NSString stringWithUTF8String:urlstr]];
			NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
			[self.webView loadRequest:requestObj];
		}
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
		// animate spinner
		CGRect rect = self.view.bounds;
		self.spinner.center = CGPointMake(rect.size.width/2, rect.size.height/2);
		[self.spinner startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[self.spinner stopAnimating];
	// check code
	NSString *html = 
		[webView stringByEvaluatingJavaScriptFromString:(@"document.body.innerHTML")];
	if (html){
		char *token = 
				c_yandex_oauth_token_from_html([html UTF8String]);
		if (token){
			[[NSUserDefaults standardUserDefaults]
					setValue:[NSString stringWithUTF8String:token] 
						forKey:@"token"];
			[self dismissViewControllerAnimated:true completion:nil];
		}
	}
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[self.spinner stopAnimating];
	// ... Code to show reload button
	UIAlertView *alert = 
			[[UIAlertView alloc]initWithTitle:@"error" 
			message:@"Can't connect to Yandex OAuth Server" 
			delegate:self 
			cancelButtonTitle:@"Закрыть" 
			otherButtonTitles:nil];
	[alert show];
}

@end
