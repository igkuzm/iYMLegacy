/**
 * File              : AudioPlayer.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 28.07.2021
 * Last Modified Date: 27.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>

@interface AudioPlayer : UIViewController
<NSURLConnectionDelegate>
@property (strong,nonatomic) NSMutableData *mutableData;
@property (strong,nonatomic) NSURL *downloadURL;
@property (strong,nonatomic) NSURL *fileURL;
@property (strong,nonatomic) NSURL *imageURL;
@property (strong,nonatomic) UIImage *image;
@property (strong) UIActivityIndicatorView *spinner;
@property (strong) NSOperationQueue *sync;
@property (strong) NSString *trackId;
@property (strong) UIImageView *imageView;
@property (strong) UIButton *buttonPlayPause;
@property (strong) UIButton *buttonNext;
@property (strong) UIButton *buttonPrev;
@property (strong) UISlider *progressSlider;

- (id)initWiithURL:(NSURL *)url title:(NSString *)title trackId:(NSString *)trackId;
@end

// vim:ft=objc
