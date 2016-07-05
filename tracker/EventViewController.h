//
//  EventViewController.h
//  tracker
//
//  Created by Griffin on 7/4/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Data.h"
#import "Event.h"

typedef void (^EventViewControllerDoneBlock)(Event *event);

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface EventViewController : UIViewController

- (instancetype)initWithData:(Data *)Data andEvent:(Event *)event done:(EventViewControllerDoneBlock)done;

@end
