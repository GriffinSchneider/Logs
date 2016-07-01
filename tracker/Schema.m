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

+ (instancetype)get {
    return [[Schema alloc]
            initWithDictionary:
            @{@"occurrences": @[
                      @"p",
                      @"c",
                      @"t",
                      @"m",
                      @"w",
                      @"l"
                      ],
              @"states": @[
                      EVENT_SLEEP,
                      @"Showering",
                      @"Walking",
                      @"Onewheeling",
                      @"At Work",
                      @"Eating",
                      @"People",
                      @"Programming",
                      @"Guitar Prac",
                      @"Guitar Rec",
                      @"Juggling",
                      @"Gaming",
                      @"Flying"
                      ],
              @"readings": @[
                      @"Mood",
                      @"Energy",
                      @"Focus",
                      @"Stomach",
                      @"Wheeee"
                      ]
              }
            error:nil];
}

@end
