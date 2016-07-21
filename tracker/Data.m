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


@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation Data

- (instancetype)init {
    if ((self = [super init])) {
        if (!self.events) {
            self.events = [NSMutableArray<Event> new];
        }
    }
    return self;
}

- (void)addEvent:(Event *)event {
    [self.events addObject:event];
}

- (void)replaceEvent:(Event *)oldEvent withEvent:(Event *)newEvent {
    [self.events replaceObjectAtIndex:[self.events indexOfObject:oldEvent] withObject:newEvent];
}

- (void)removeEvent:(Event *)event {
    [self.events removeObject:event];
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
    [self.events sortUsingSelector:@selector(compare:)];
}

- (NSArray<Event *> *)eventsToday {
    NSInteger idx = [self.events indexOfObjectWithOptions:NSEnumerationReverse passingTest:^BOOL(Event *obj, NSUInteger idx, BOOL *stop) {
        return obj.type == EventTypeEndState && [obj.name isEqualToString:EVENT_SLEEP];
    }];
    if (idx == NSNotFound) idx = -1;
    return [self.events objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(idx + 1, self.events.count - idx - 1)]];
}

- (NSArray<State *> *)allStates {
    NSMutableSet<Event *> *currentlyOn = [NSMutableSet new];
    NSMutableArray<State *> *retVal = [NSMutableArray new];
    [self.events enumerateObjectsUsingBlock:^(Event *e, NSUInteger idx, BOOL *stop) {
        if (e.type != EventTypeStartState && e.type != EventTypeEndState) return;
        
        Event *foundCurrentlyOn = [[currentlyOn objectsPassingTest:^BOOL(Event *ie, BOOL *stop) {
            return [ie.name isEqualToString:e.name];
        }] anyObject];
        
        if (e.type == EventTypeStartState)  {
            if (foundCurrentlyOn) {
                NSLog(@"Weird case. Found an event already on. This event: %@ \nThe one that was already on: %@", e, foundCurrentlyOn);
                return;
            }
            [currentlyOn addObject:e];
        }
        
        if (e.type == EventTypeEndState) {
            if (!foundCurrentlyOn) {
                NSLog(@"Weird case. Found an end to an event that didn't start. This event: %@", e);
                return;
            }
            [currentlyOn removeObject:foundCurrentlyOn];
            
            NSInteger idxToInsert = [retVal indexOfObjectPassingTest:^BOOL(State *obj, NSUInteger idx, BOOL *stop) {
                return [obj.start compare:foundCurrentlyOn.date] == NSOrderedDescending;
            }];
            if (idxToInsert == NSNotFound) idxToInsert = retVal.count;
            
            [retVal insertObject:[[State alloc] initWithName:e.name start:foundCurrentlyOn.date end:e.date events:@[foundCurrentlyOn, e]] atIndex:idxToInsert];
        }
    }];
    return retVal;
}

@end
