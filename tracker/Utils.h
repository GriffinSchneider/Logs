//
//  Utils.h
//  tracker
//
//  Created by Griffin Schneider on 7/28/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NSString *formatDuration(NSTimeInterval interval);
UIColor *colorForState(NSString *stateName);
UIImage *iconForState(NSString *stateName);

@interface Utils : NSObject

@end
