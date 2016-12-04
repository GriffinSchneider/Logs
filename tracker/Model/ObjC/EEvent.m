//
//  Event.m
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "EEvent.h"

NSString *EventType_toString(EventType t) {
    switch (t) {
        case EventTypeStartState:
            return @"StartState";
        case EventTypeEndState:
            return @"EndState";
        case EventTypeReading:
            return @"Reading";
        case EventTypeOccurrence:
            return @"Occurrence";
    }
};

@implementation EEvent

- (NSComparisonResult)compare:(EEvent *)otherObject {
    return [self.date compare:otherObject.date];
}

- (void)setTypeWithNSString:(NSString*)string {
    if ([string isEqual:@"StartState"]) {
        self.type = EventTypeStartState;
    } else if ([string isEqual:@"EndState"]) {
        self.type = EventTypeEndState;
    } else if ([string isEqual:@"Reading"]) {
        self.type = EventTypeReading;
    } else if ([string isEqual:@"Occurrence"]) {
        self.type = EventTypeOccurrence;
    }
}

- (NSString *)JSONObjectForType {
    return EventType_toString(self.type);
}

@end