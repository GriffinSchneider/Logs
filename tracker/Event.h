//
//  Event.h
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

typedef NS_ENUM(NSInteger, EventType) {
    EventTypeStartState,
    EventTypeEndState
};

@interface Event : JSONModel

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) EventType type;

@end
