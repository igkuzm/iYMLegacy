/**
 * File              : YandexConnect.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 09.08.2023
 * Last Modified Date: 22.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "YandexConnect.h"
#include "CoreGraphics/CoreGraphics.h"
#include <time.h>
#include "UIKit/UIKit.h"
#include <stdio.h>
#include "Foundation/Foundation.h"
#include "../cYandexMusic/cYandexOAuth.h"

#define CLIENTID "343888adb2334202bbc879fc3596dc49"
#define CLIENTSECRET "1b94898ca415477ab295fcccf17468ee"

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

		char *error = NULL;
		char *urlstr = c_yandex_oauth_code_on_page(CLIENTID);
		if (urlstr){
			NSURL *url = [NSURL URLWithString:[NSString stringWithUTF8String:urlstr]];
			NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
			[self.webView loadRequest:requestObj];
		} else {
			NSLog(@"Can't get Yandex Disk URL");
			UIAlertView *alert = 
				[[UIAlertView alloc]initWithTitle:@"error" 
				message:@"Can't get Yandex Disk URL" 
			  delegate:self 
				cancelButtonTitle:@"Закрыть" 
				otherButtonTitles:nil];

			[alert show];
		}
}

int save_token(void *data, const char *token, int expires, const char *refresh, const char *error){
	YandexConnect *self = data;
	if (error){
		NSLog(@"%s", error);
	}
	if (token){
		NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
		[def setValue:[NSString stringWithUTF8String:token] forKey:@"token"];
		[def setValue:[NSDate dateWithTimeIntervalSince1970:expires] forKey:@"expires"];
		[def setValue:[NSString stringWithUTF8String:token] forKey:@"refresh"];
		[self dismissViewControllerAnimated:true completion:nil];
	}
	return 0;
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
		char *error = NULL;
		char *code = 
			c_yandex_oauth_code_from_html([html UTF8String]);
		if (code){
			c_yandex_oauth_get_token(
					code, 
					CLIENTID, 
					CLIENTSECRET, 
					[[[UIDevice currentDevice]name]UTF8String], 
					self,
					save_token);
		}
	}
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
		[self.spinner stopAnimating];
    // ... Code to show reload button
		UIAlertView *alert = 
				[[UIAlertView alloc]initWithTitle:@"error" 
				message:@"Can't connect to Yandex Disk" 
			  delegate:self 
				cancelButtonTitle:@"Закрыть" 
				otherButtonTitles:nil];
		[alert show];
}

@end
