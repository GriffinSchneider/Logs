//
//  Event.h
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

#define EVENT_SLEEP @"Sleep"

typedef NS_ENUM(NSInteger, EventType) {
    EventTypeStartState,
    EventTypeEndState
};

@protocol Event

@end

@interface Event : JSONModel <Event>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) EventType type;

@end
