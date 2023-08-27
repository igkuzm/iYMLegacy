/**
 * File              : PlayerViewController.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 27.08.2023
 * Last Modified Date: 27.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface PlayerViewController : UIViewController
@property (strong) UIImageView *imageView;

@property (strong) UIButton *buttonPlayPause;
@property (strong) UIButton *buttonNext;
@property (strong) UIButton *buttonPrev;
@property (strong) UISlider *progressSlider;
@property (strong,nonatomic) AVQueuePlayer *player;

@property (strong) NSArray *tracks;
@property NSUInteger currentTrackIndex;

@end
// vim:ft=objc
