/**
 * File              : QuickLookController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 28.07.2021
 * Last Modified Date: 25.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "QuickLookController.h"
#include "Foundation/Foundation.h"

@implementation PreviewItem
- (id)initWithURL:(NSURL *)url title:(NSString *)title
{
	if (self = [super init]) {
		self.previewItemURL = url;
		self.previewItemTitle = title;
	}
	return self;
}
		
@end

@implementation QuickLookController
-(QuickLookController *)initQLPreviewControllerWithURL:(NSURL *)url 
														title:(NSString *)title trackId:(NSString *)trackId{
	self = [self init];
	self.currentPreviewItemIndex=0;
	self.title = title;
	self.trackId = trackId;
	self.dataSource = self;
	self.delegate = self;
	self.previewItem = [[PreviewItem alloc]initWithURL:url title:title];
	[self downloadUrl:url];
	return self;
}

- (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = 
			NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = [paths objectAtIndex:0];
    return basePath;
}

-(NSURL *)fileURL{
	NSString *filename = 
			[NSString stringWithFormat:@"%@.mp3", self.trackId];
			//[NSString stringWithFormat:@"%@.mp3", [[NSUUID UUID] UUIDString]];
	NSString *filepath = 
			//[NSTemporaryDirectory() stringByAppendingPathComponent:filename];
			[[self applicationDocumentsDirectory] stringByAppendingPathComponent:filename];
	return [NSURL fileURLWithPath:filepath];
}

-(void)downloadUrl:(NSURL *)url{
	NSURL *fileURL = [self fileURL];
	if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]){ 
		self.previewItem.previewItemURL = fileURL;
		[self reloadData];
	}else {
		NSURLRequest *request = 
				[NSURLRequest requestWithURL:url];
		NSURLConnection *conection = 
				[[NSURLConnection alloc]initWithRequest:request
						delegate:self startImmediately:true];
	}
}

#pragma mark - QLPreview Delegate
- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index{
	return self.previewItem;
}
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller{
	return 1;
}

#pragma mark - NSURLConnectionDelegate Meythods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  self.mutableData = [[NSMutableData alloc]init];
	self.previewItem.previewItemURL = [self fileURL];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  [self.mutableData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[self.mutableData writeToURL:self.previewItem.previewItemURL atomically:true];
	[self reloadData];
}

@end
