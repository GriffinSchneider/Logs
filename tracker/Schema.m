//
//  Schema.m
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "Schema.h"
#import "Event.h"

@implementation Schema

- (instancetype)init {
    if (self = [super init]) {
        self.occurrences = [NSArray new];
        self.states = [NSArray<StateSchema> new];
        self.readings = [NSArray new];
    }
    return self;
}

- (StateSchema *)schemaForStateNamed:(NSString *)stateName {
    for (StateSchema *schema in self.states) {
        if ([schema.name isEqualToString:stateName]) {
            return schema;
        }
    }
    return nil;
}

@end
