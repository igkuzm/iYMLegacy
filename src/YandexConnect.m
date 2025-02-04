/**
 * File              : YandexConnect.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 09.08.2023
 * Last Modified Date: 23.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "YandexConnect.h"
#include "AppDelegate.h"
#include "CoreGraphics/CoreGraphics.h"
#include <time.h>
#include "UIKit/UIKit.h"
#include <stdio.h>
#include "Foundation/Foundation.h"
#include "../cYandexDisk/cYandexOAuth.h"

#define CLIENTID "23cabbbdc6cd418abb4b39c32c41195d"
#define CLIENTSECRET "53bc75238f0c4d08a118e51fe9203300"

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

		//char *urlstr = c_yandex_oauth_code_on_page(CLIENTID);
		//if (urlstr){
			//NSURL *url = [NSURL URLWithString:[NSString stringWithUTF8String:urlstr]];
			//NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
			//[self.webView loadRequest:requestObj];
		//}

		c_yandex_oauth_code_from_user(
				CLIENTID, 
			  UIDevice.currentDevice.name.UTF8String, 
				self, 
				code_callback);
}


static int token_callback(
			void * user_data,
			const char * access_token,
			int expires_in,
			const char * refresh_token,
			const char * error
			)
{
	YandexConnect *self = user_data;
	AppDelegate *appDelegate = 
		UIApplication.sharedApplication.delegate;
	
	if (error){
		dispatch_sync(dispatch_get_main_queue(), ^{
			[appDelegate showMessage:
				[NSString stringWithUTF8String:error]];
		});
		return 0;
	}
	
	dispatch_sync(dispatch_get_main_queue(), ^{
		[[NSUserDefaults standardUserDefaults]
					setValue:[NSString stringWithUTF8String:access_token] 
							forKey:@"token"];
		[appDelegate showMessage:@"connected!"];
		[self dismissViewControllerAnimated:true completion:nil];
	});

	return 0;
}

static int code_callback(
			void * user_data,
			const char * device_code,
			const char * user_code,
			const char * verification_url,
			int interval,
			int expires_in,
			const char * error
			)
{
	YandexConnect *self = user_data;
	AppDelegate *appDelegate = 
		UIApplication.sharedApplication.delegate;

	if (error){
		[appDelegate showMessage:
			[NSString stringWithUTF8String:error]];
		return 0;
	}

	[appDelegate showMessage:
		[NSString stringWithFormat:
			@"open %s \nand enter code: %s",
				verification_url, user_code]];
	
	[[[NSOperationQueue alloc]init] addOperationWithBlock:^{
		c_yandex_oauth_get_token_from_user(
				device_code, 
				CLIENTID, 
				CLIENTSECRET, 
				interval, 
				expires_in, 
				self, 
				token_callback);
	}];

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
	//NSString *html = 
		//[webView stringByEvaluatingJavaScriptFromString:(@"document.body.innerHTML")];
	//if (html){
		//char *token = 
				//c_yandex_oauth_token_from_html([html UTF8String]);
		//if (token){
			//[[NSUserDefaults standardUserDefaults]
					//setValue:[NSString stringWithUTF8String:token] 
						//forKey:@"token"];
			//[self dismissViewControllerAnimated:true completion:nil];
		//}
	//}
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
