//
//  Data.m
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "Data.h"


Event *eventNamed(NSSet<Event *> *events, NSString *eventName) {
    return [[events filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"name = %@", eventName]] anyObject];
};


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface Data()

@property (nonatomic, strong) NSMutableArray<Event> *_events;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation Data

- (instancetype)init {
    if ((self = [super init])) {
        if (!self._events) {
            self._events = [NSMutableArray<Event> new];
        }
    }
    return self;
}


- (NSArray<Event *> *)events {
    return self._events;
}

- (void)addEvent:(Event *)event {
    [self._events addObject:event];
}

- (void)replaceEvent:(Event *)oldEvent withEvent:(Event *)newEvent {
    [self._events replaceObjectAtIndex:[self._events indexOfObject:oldEvent] withObject:newEvent];
}

- (void)removeEvent:(Event *)event {
    [self._events removeObject:event];
}

- (NSSet<Event *> *)activeStates {
    NSMutableSet<Event *> *retVal = [NSMutableSet new];
    NSMutableSet<NSString *> *endedStates = [NSMutableSet new];
    [self.events enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(Event * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.type == EventTypeEndState) {
            [endedStates addObject:obj.name];
        } else if (obj.type == EventTypeStartState) {
            if (![endedStates containsObject:obj.name]) {
                [retVal addObject:obj];
            }
        }
        if ([obj.name isEqual:EVENT_SLEEP]) {
            *stop = YES;
            return;
        }
    }];
    return retVal;
}

- (NSDictionary<NSString *, Event *> *)lastReadings {
    NSMutableDictionary<NSString *, Event *> *retVal = [NSMutableDictionary new];
    [self.events enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(Event * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.type == EventTypeReading) {
            if (![retVal objectForKey:obj.name]) {
                [retVal setObject:obj forKey:obj.name];
            }
        }
        if ([obj.name isEqual:EVENT_SLEEP]) {
            *stop = YES;
            return;
        }
    }];
    return retVal;
}

- (NSSet<NSString *> *)recentOccurrences {
    NSMutableSet<NSString *> *retVal = [NSMutableSet new];
    [self.events enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(Event * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[NSDate date] timeIntervalSinceDate:obj.date] > 1) {
            *stop = YES;
            return;
        }
        [retVal addObject:obj.name];
    }];
    return retVal;
}

- (void)sortEvents {
    [self._events sortUsingSelector:@selector(compare:)];
}

@end
