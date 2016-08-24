//
//  Utils.m
//  tracker
//
//  Created by Griffin Schneider on 7/28/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "Utils.h"
#import "ChameleonMacros.h"
#import "SyncManager.h"

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
        retVal = [colors[colorIndex] darkenByPercentage:0.2];
        colorMap[stateName] = retVal;
    }
    return retVal;
}

UIImage *imageWithSize(NSString *string) {
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:32]}];
    CGSize imageSize = [attributedString size];
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
    [attributedString drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
    UIImage *iconImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return iconImage;
}

static NSMutableDictionary<NSString *, UIImage *> *iconMap;
UIImage *iconForState(NSString *stateName) {
    if (!iconMap) {
        iconMap = [NSMutableDictionary new];
    }
    UIImage *icon = iconMap[stateName];
    if (!icon) {
        NSString *iconString = [[SyncManager i].schema schemaForStateNamed:stateName].icon ?: @"";
        iconMap[stateName] = icon = imageWithSize(iconString);
    }
    return icon;
}


@implementation Utils

@end
