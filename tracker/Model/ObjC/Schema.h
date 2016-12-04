//
//  Schema.h
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "StateSchema.h"

@interface Schema : JSONModel

@property (nonatomic, strong) NSArray<NSString *> *occurrences;
@property (nonatomic, strong) NSArray<StateSchema> *states;
@property (nonatomic, strong) NSArray<NSString *> *readings;

- (StateSchema *)schemaForStateNamed:(NSString *)stateName;

@end
