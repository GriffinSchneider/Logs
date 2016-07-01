//
//  Event.m
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "Event.h"

@implementation Event


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
    switch (self.type) {
        case EventTypeStartState:
            return @"StartState";
        case EventTypeEndState:
            return @"EndState";
        case EventTypeReading:
            return @"Reading";
        case EventTypeOccurrence:
            return @"Occurrence";
    }
}

@end
