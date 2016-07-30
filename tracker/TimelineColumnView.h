//
//  TimelineColumnView.h
//  tracker
//
//  Created by Griffin Schneider on 7/29/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Event.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TimelineColumnView : UIView

- (instancetype)initWithEvents:(NSArray<Event *> *)events startTime:(NSDate *)startTime;

@end
