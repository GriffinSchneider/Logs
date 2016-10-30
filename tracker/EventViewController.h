//
//  EventViewController.h
//  tracker
//
//  Created by Griffin on 7/4/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Data.h"
#import "EEvent.h"

typedef void (^EventViewControllerDoneBlock)(EEvent *event);

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface EventViewController : UIViewController

- (instancetype)initWithData:(Data *)Data andEvent:(EEvent *)event done:(EventViewControllerDoneBlock)done;

@end
