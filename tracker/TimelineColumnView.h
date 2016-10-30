//
//  TimelineColumnView.h
//  tracker
//
//  Created by Griffin Schneider on 7/29/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EEvent.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TimelineColumnView : UIView

- (instancetype)initWithEvents:(NSArray<EEvent *> *)events startTime:(NSDate *)startTime endTime:(NSDate *)endTime;

@end
