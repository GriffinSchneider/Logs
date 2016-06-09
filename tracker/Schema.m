//
//  Schema.m
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "Schema.h"

@implementation Schema

+ (instancetype)get {
    return [[Schema alloc]
            initWithDictionary: @{
                                  @"states": @[@"outside", @"somehting", @"outside", @"outside", @"outside" ]
                                  }
            error:nil];
}

@end
