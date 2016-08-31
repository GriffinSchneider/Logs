//
//  State.h
//  tracker
//
//  Created by Griffin Schneider on 7/21/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EEvent.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface State : NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSDate *start;
@property (nonatomic, strong, readonly) NSDate *end;
@property (nonatomic, strong, readonly) NSArray<EEvent *> *events;

- (instancetype)initWithName:(NSString *)name start:(NSDate *)start end:(NSDate *)end events:(NSArray<EEvent *> *)events;

@end
