//
//  Data.h
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import "Event.h"


BOOL hasEventNamed(NSSet<Event *> *events, NSString *eventName);


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface Data : JSONModel

@property (nonatomic, strong) NSMutableArray<Event> *events;

- (NSSet<Event *> *)activeStates;
- (NSDictionary<NSString *, Event *> *)lastReadings;
- (NSSet<NSString *> *)recentOccurrences;

- (void)sortEvents;

@end
