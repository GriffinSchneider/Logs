//
//  Data.h
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import "Event.h"

@interface Data : JSONModel

@property (nonatomic, strong) NSMutableArray<Event> *events;

- (NSSet<NSString *> *)activeStates;
- (NSDictionary<NSString *, Event *> *)lastReadings;
- (NSSet<NSString *> *)recentOccurrences;

@end
