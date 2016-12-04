//
//  State.m
//  tracker
//
//  Created by Griffin Schneider on 7/21/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "State.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation State

- (instancetype)initWithName:(NSString *)name start:(NSDate *)start end:(NSDate *)end events:(NSArray<EEvent *> *)events {
    if ((self = [super init])) {
        _name = name;
        _start = start;
        _end = end;
        _events = events;
    }
    return self;
}

- (NSString *)description {
    NSTimeInterval interval = [self.end timeIntervalSinceDate:self.start];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    return [NSString stringWithFormat: @"<State \"%@\", for %@, %@ to %@>", self.name, [dateFormatter stringFromDate:date], self.start, self.end];
}

@end
