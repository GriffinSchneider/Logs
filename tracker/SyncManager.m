//
//  SyncManager.m
//  tracker
//
//  Created by Griffin Schneider on 7/7/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "SyncManager.h"

#import <UIKit/UIKit.h>
#if IS_TODAY_EXTENSION
#import "TrackerToday-Swift.h"
#else
#import "tracker-Swift.h"
#endif

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface SyncManager ()

@property (nonatomic, strong) Data *data;
@property (nonatomic, strong) Schema *schema;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation SyncManager

+ (instancetype)i {
    static dispatch_once_t once;
    
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Paths

- (NSString *)localDataPath {
    NSURL *containerDirectory = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier: @"group.zone.griff.tracker"];
    return [containerDirectory URLByAppendingPathComponent:@"data.json"].path;
}

- (NSString *)localSchemaPath {
    NSURL *containerDirectory = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier: @"group.zone.griff.tracker"];
    return [containerDirectory URLByAppendingPathComponent:@"schema.json"].path;
}


#pragma mark - Real Stuff
- (void)loadFromDisk {
    NSData *schemaData = [NSData dataWithContentsOfFile:self.localSchemaPath];
    NSDictionary *schemaDict = nil;
    if (schemaData) {
        schemaDict = [NSJSONSerialization JSONObjectWithData:schemaData options:0 error:nil];
    }
    self.schema = [[Schema alloc] initWithDictionary:schemaDict error:nil];
    
    NSData *dataData = [NSData dataWithContentsOfFile:self.localDataPath];
    NSDictionary *dataDict = nil;
    if (dataData) {
        dataDict = [NSJSONSerialization JSONObjectWithData:dataData options:0 error:nil];
    }
    if (dataDict) {
        self.data = [[Data alloc] initWithDictionary:dataDict error:nil];
    }
    if (!self.data) {
        self.data = [Data new];
    }
}
@end
