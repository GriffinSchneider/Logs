//
//  Utils.m
//  tracker
//
//  Created by Griffin Schneider on 7/28/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "Utils.h"
#import <ChameleonFramework/Chameleon.h>

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

static NSUInteger colorIndex = 0;
static NSArray<UIColor *> *colors;
static NSMutableDictionary<NSString *, UIColor *> *colorMap;
UIColor *colorForState(NSString *stateName) {
    if (!colors) {
        colors = @[FlatBlueDark, FlatRedDark, FlatGreenDark, FlatBlueDark,
                   FlatMagentaDark, FlatOrangeDark, FlatPinkDark,
                   FlatPurpleDark, FlatRedDark, FlatSkyBlueDark,
                   FlatWatermelonDark, FlatYellowDark];
        colorMap = [NSMutableDictionary new];
    }
    
    UIColor *retVal = colorMap[stateName];
    if (!retVal) {
        colorIndex = (colorIndex + 1) % colors.count;
        retVal = colors[colorIndex];
        colorMap[stateName] = retVal;
    }
    return retVal;
}


@implementation Utils

@end
