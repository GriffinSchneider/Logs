//
//  Data.m
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "Data.h"

@implementation Data

- (NSSet<NSString *> *)activeStates {
    NSMutableSet<NSString *> *retVal = [NSMutableSet new];
    NSMutableSet<NSString *> *endedStates = [NSMutableSet new];
    [self.events enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(Event * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.type == EventTypeEndState) {
            [endedStates addObject:obj.name];
        } else if (obj.type == EventTypeStartState) {
            if (![endedStates containsObject:obj.name]) {
                [retVal addObject:obj.name];
            }
        }
        if ([obj.name isEqual:EVENT_SLEEP]) {
            *stop = YES;
            return;
        }
    }];
    return retVal;
}

@end