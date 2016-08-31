//
//  Data.h
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import "EEvent.h"
#import "State.h"

BOOL doStatesOverlap(State *s1, State *s2);

EEvent *eventNamed(NSSet<EEvent *> *events, NSString *eventName);
NSArray <State *> *statesFromEvents(NSArray<EEvent *> *events);


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface Data : JSONModel

@property (nonatomic, strong) NSMutableArray<EEvent> *events;

- (void)addEvent:(EEvent *)event;
- (void)replaceEvent:(EEvent *)oldEvent withEvent:(EEvent *)newEvent;
- (void)removeEvent:(EEvent *)event;
- (void)sortEvents;

- (NSArray<EEvent *> *)activeStates;
- (NSDictionary<NSString *, EEvent *> *)lastReadings;
- (NSSet<NSString *> *)recentOccurrences;

- (NSArray<EEvent *> *)eventsForDay:(NSDate *)date;

@end
