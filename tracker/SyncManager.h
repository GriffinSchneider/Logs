//
//  SyncManager.h
//  tracker
//
//  Created by Griffin Schneider on 7/7/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Data.h"
#import "Schema.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface SyncManager : NSObject

+ (instancetype)i;
- (Data *)data;
- (Schema *)schema;

- (void)loadFromDisk;

@end
