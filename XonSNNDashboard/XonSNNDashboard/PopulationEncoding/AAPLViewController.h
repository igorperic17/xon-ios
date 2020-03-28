/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for our our cross-platform view controller
*/


// #if defined(TARGET_IOS) || defined(TARGET_TVOS)
@import UIKit;
#define PlatformViewController UIViewController
/*
#else
@import AppKit;
#define Pl tformViewController NSViewController
#endif
*/

@import MetalKit;

#import <XonSNNCore/XonSNNCore.h>

// Our view controller
@interface AAPLViewController : PlatformViewController

@end
