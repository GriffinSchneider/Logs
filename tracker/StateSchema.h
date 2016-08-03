//
//  StateSchema.h
//  tracker
//
//  Created by Griffin on 8/3/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import <JSONModel/JSONModel.h>

@protocol StateSchema

@end

@interface StateSchema : JSONModel

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *icon;

@end
