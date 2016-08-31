//
//  Data.m
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "Data.h"

BOOL doStatesOverlap(State *s1, State *s2) {
    return [s1.start compare:s2.end] != NSOrderedDescending && [s2.start compare:s1.end] != NSOrderedDescending;
}

Event *eventNamed(NSSet<Event *> *events, NSString *eventName) {
    return [[events filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"name = %@", eventName]] anyObject];
}

void sortedInsert(State *state, NSMutableArray<State *> *states) {
    NSInteger idxToInsert = [states indexOfObjectPassingTest:^BOOL(State *obj, NSUInteger idx, BOOL *stop) {
        return [obj.start compare:state.start] == NSOrderedDescending;
    }];
    if (idxToInsert == NSNotFound) idxToInsert = states.count;
    
    [states insertObject:state atIndex:idxToInsert];
}

NSArray <State *> *statesFromEvents(NSArray<Event *> *events) {
    NSMutableSet<Event *> *currentlyOn = [NSMutableSet new];
    NSMutableArray<State *> *retVal = [NSMutableArray new];
    
    [events enumerateObjectsUsingBlock:^(Event *e, NSUInteger idx, BOOL *stop) {
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
            sortedInsert([[State alloc] initWithName:e.name start:foundCurrentlyOn.date end:e.date events:@[foundCurrentlyOn, e]], retVal);
        }
    }];
    
    [currentlyOn enumerateObjectsUsingBlock:^(Event *e, BOOL *stop) {
        sortedInsert([[State alloc] initWithName:e.name start:e.date end:nil events:@[e]], retVal);
    }];
    
    return retVal;
}


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

- (NSArray<Event *> *)activeStates {
    NSMutableArray<Event *> *retVal = [NSMutableArray new];
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

- (NSArray<Event *> *)eventsForDay:(NSDate *)date {
    NSCalendar *cal = [NSCalendar currentCalendar];
    
    NSInteger wakeupIndex = [self.events indexOfObjectWithOptions:NSEnumerationReverse passingTest:^BOOL(Event *obj, NSUInteger idx, BOOL *stop) {
        return
        obj.type == EventTypeEndState &&
        [obj.name isEqualToString:EVENT_SLEEP] &&
        [cal isDate:obj.date inSameDayAsDate:date];
    }];
    
    if (wakeupIndex == NSNotFound) {
        return @[];
    }
    
    NSInteger firstSleepIndex = [self.events indexOfObjectAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, wakeupIndex)] options:NSEnumerationReverse passingTest:^BOOL(Event *obj, NSUInteger idx, BOOL *stop) {
        return obj.type == EventTypeStartState && [obj.name isEqualToString:EVENT_SLEEP];
    }];
    
    if (firstSleepIndex == NSNotFound) {
        NSAssert(NO, @"I'm confused");
    }
    
    NSInteger secondSleepIndex = [self.events indexOfObjectAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(wakeupIndex, self.events.count - wakeupIndex - 1)] options:0 passingTest:^BOOL(Event *obj, NSUInteger idx, BOOL *stop) {
        return obj.type == EventTypeStartState && [obj.name isEqualToString:EVENT_SLEEP];
    }];
    if (secondSleepIndex == NSNotFound) {
        secondSleepIndex = self.events.count - 1;
    }
    NSInteger nextDayWakeupIndex = [self.events indexOfObjectAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(secondSleepIndex, self.events.count - secondSleepIndex - 1)] options:0 passingTest:^BOOL(Event *obj, NSUInteger idx, BOOL *stop) {
        return obj.type == EventTypeEndState && [obj.name isEqualToString:EVENT_SLEEP];
    }];
    
    NSMutableArray<Event *> *retVal = [NSMutableArray new];
    
    [retVal addObject:self.events[firstSleepIndex]];
    [retVal addObjectsFromArray:[self.events objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(wakeupIndex, secondSleepIndex - wakeupIndex + 1)]]];
    if (nextDayWakeupIndex != NSNotFound ) {
        [retVal addObject:self.events[nextDayWakeupIndex]];
    }
    
    return retVal;
}

@end
