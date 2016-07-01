//
//  Schema.m
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "Schema.h"
#import "Event.h"

@implementation Schema

+ (instancetype)get {
    return [[Schema alloc]
            initWithDictionary: @{
                                  @"states": @[EVENT_SLEEP, @"Outside", @"Somehting", @"Another Thing" ]
                                  }
            error:nil];
}

@end
