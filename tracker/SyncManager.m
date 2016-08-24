//
//  SyncManager.m
//  tracker
//
//  Created by Griffin Schneider on 7/7/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "SyncManager.h"

#import <UIKit/UIKit.h>
#import <Toast/UIView+Toast.h>
#import <DropboxSDK/DropboxSDK.h>


#define PRETTY_PRINT(x) \
([[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[(x) toDictionary] \
                                                                options:NSJSONWritingPrettyPrinted \
                                                                  error:nil] \
                       encoding:NSUTF8StringEncoding]) \

#define DATA_REVISION_KEY @"DataRevision"


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface SyncManager () <
DBRestClientDelegate
>

@property (nonatomic, strong) Data *data;
@property (nonatomic, strong) Schema *schema;

@property (nonatomic, strong) DBRestClient* restClient;

@property (nonatomic, strong) NSTimer *saveTimer;
@property (nonatomic, strong) NSString *currentlyLoadingFile;

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

- (instancetype)init {
    if ((self = [super init])) {
        if ([DBSession sharedSession]) {
            self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
            self.restClient.delegate = self;
        }
    }
    return self;
}


#pragma mark - Toasts

- (void)toast:(NSString *)text {
//    [[[UIApplication sharedApplication] keyWindow] hideToastActivity];
//    [[[UIApplication sharedApplication] keyWindow] makeToast:text];
}

- (void)showActivity {
//    [[[UIApplication sharedApplication] keyWindow] makeToastActivity:CSToastPositionCenter];
}

- (void)hideActivity {
//    [[[UIApplication sharedApplication] keyWindow] hideToastActivity];
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


#pragma mark - Revision Tracking

- (NSString *)dataRevision {
    return [[NSUserDefaults standardUserDefaults] objectForKey:DATA_REVISION_KEY];
}

- (void)setDataRevision:(NSString *)dataRevision {
    [[NSUserDefaults standardUserDefaults] setObject:dataRevision forKey:DATA_REVISION_KEY];
}


#pragma mark - Real Stuff


- (void)loadFromDropbox {
    if (!self.restClient) {
        NSAssert(NO, @"Trying to load from Dropbox with no Dropbox client!");
    }
    [self showActivity];
    self.currentlyLoadingFile = self.localSchemaPath;
    [self.restClient loadFile:@"/schema.json" intoPath:self.localSchemaPath];
}

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

- (void)writeToDisk {
    if (!self.data) {
        return;
    }
    NSData *nsData = [self.data toJSONData];
    [nsData writeToFile:self.localDataPath atomically:YES];
}

- (void)writeToDropbox {
    if (!self.restClient) {
        NSAssert(NO, @"Trying to write to Dropbox with no Dropbox client!");
    }
    [self writeToDisk];
    [self.saveTimer invalidate];
    self.saveTimer = [NSTimer timerWithTimeInterval:3.0 target:self selector:@selector(saveImmediately) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.saveTimer forMode:NSRunLoopCommonModes];
}

- (void)saveImmediately {
    [self.saveTimer invalidate];
    self.saveTimer = nil;
    [self writeToDisk];
    [self.restClient uploadFile:@"data.json" toPath:@"/" withParentRev:self.dataRevision fromPath:self.localDataPath];
}

- (void)makeSchemaFile {
    if (!self.schema) {
        self.schema = [Schema new];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.localSchemaPath]) {
        [[NSFileManager defaultManager] createFileAtPath:self.localSchemaPath contents:[self.schema toJSONData] attributes:nil];
    }
    [self.restClient uploadFile:@"schema.json" toPath:@"/" withParentRev:nil fromPath:self.localSchemaPath];
}

#pragma mark - DBRestClientDelegate

- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata {
    self.dataRevision = metadata.rev;
    [self.restClient loadFile:metadata.path intoPath:self.localDataPath];
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error {
    [self restClient:nil loadedFile:self.localDataPath];
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)destPath {
    if ([destPath isEqual:self.localSchemaPath]) {
        [self toast:@"✅Loaded Schema✅"];
        self.currentlyLoadingFile = self.localDataPath;
        [self.restClient loadMetadata:@"/data.json"];
    } else {
        [self toast:@"✅Loaded Data✅"];
        [self loadFromDisk];
    }
    [self hideActivity];
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
    NSLog(@"LOAD FAILED WITH ERROR: %@", error);
    if (error.code == 401) {
        [self toast:@"Authentication Failure."];
        return;
    }
    if ([self.currentlyLoadingFile isEqualToString:self.localSchemaPath]) {
        [self toast:@"❌Loading Schema Failed!❌"];
        [self makeSchemaFile];
    } else {
        [self toast:@"❌Loading Data Failed!❌"];
        [self restClient:nil loadedFile:self.localDataPath];
    }
}


- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    self.dataRevision = metadata.rev;
    if ([srcPath isEqualToString:self.localSchemaPath]) {
        [self toast:@"✅Created Schema File✅"];
        [self loadFromDropbox];
    } else {
        [self toast:@"✅⏫✅"];
    }
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    if ([self.currentlyLoadingFile isEqualToString:self.localSchemaPath]) {
        [self toast:@"❌Failed to Create Schema File!❌"];
    } else {
        [self toast:@"❌Failed to Upload Data!❌"];
    }
}


@end
