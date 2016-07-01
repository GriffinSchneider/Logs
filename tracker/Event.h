//
//  Event.h
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

#define EVENT_SLEEP @"Sleeping"

typedef NS_ENUM(NSInteger, EventType) {
    EventTypeStartState,
    EventTypeEndState,
    EventTypeReading,
    EventTypeOccurrence,
};

@protocol Event

@end

@interface Event : JSONModel <Event>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) EventType type;

@property (nonatomic, strong) NSNumber<Optional> *reading;
@property (nonatomic, strong) NSString<Optional> *noteText;

@end
