//
//  TimelineViewController.h
//  tracker
//
//  Created by Griffin Schneider on 7/21/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^TimelineViewControllerDoneBlock)(void);

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TimelineViewController : UIViewController

- (instancetype)initWithDone:(TimelineViewControllerDoneBlock)done;

@end
