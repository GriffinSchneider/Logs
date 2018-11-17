//
//  Utils.m
//  tracker
//
//  Created by Griffin Schneider on 7/28/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "Utils.h"
#import "ChameleonMacros.h"

NSString *formatDuration(NSTimeInterval interval) {
    int sec = (int)interval % 60;
    int min = ((int)interval / 60) % 60;
    int hrs = (int)interval / (60 * 60);
    if (hrs > 0) {
        return [NSString stringWithFormat:@"%d:%02d:%02d", hrs, min, sec];
    } else {
        return [NSString stringWithFormat:@"%02d:%02d", min, sec];
    }
}

@implementation Utils

@end

