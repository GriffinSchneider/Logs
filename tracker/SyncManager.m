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


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface SyncManager () <
DBRestClientDelegate
>

@property (nonatomic, strong) Data *data;
@property (nonatomic, strong) Schema *schema;

@property (nonatomic, strong) DBRestClient* restClient;

@property (nonatomic, strong) NSTimer *saveTimer;
@property (nonatomic, strong) NSString *currentlyLoadingFile;
@property (nonatomic, strong) NSString *fileRev;

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
        self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        self.restClient.delegate = self;
    }
    return self;
}


#pragma mark - Toasts

- (void)toast:(NSString *)text {
    [[[UIApplication sharedApplication] keyWindow] hideToastActivity];
    [[[UIApplication sharedApplication] keyWindow] makeToast:text];
}

- (void)showActivity {
    [[[UIApplication sharedApplication] keyWindow] makeToastActivity:CSToastPositionCenter];
}

- (void)hideActivity {
    [[[UIApplication sharedApplication] keyWindow] hideToastActivity];
}


#pragma mark - Paths

- (NSString *)localDataPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"data.json"];
}

- (NSString *)localSchemaPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"schema.json"];
}


#pragma mark - Real Stuff


- (void)loadFromDropbox {
    [self showActivity];
    self.currentlyLoadingFile = self.localSchemaPath;
    [self.restClient loadFile:@"/schema.json" intoPath:self.localSchemaPath];
}

- (void)writeToDropbox {
    [self.saveTimer invalidate];
    self.saveTimer = [NSTimer timerWithTimeInterval:3.0 target:self selector:@selector(saveTimerDone) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.saveTimer forMode:NSRunLoopCommonModes];
}

- (void)saveTimerDone {
    NSLog(@"Writing data:\n%@", PRETTY_PRINT(self.data));
    NSData *nsData = [self.data toJSONData];
    [nsData writeToFile:self.localDataPath atomically:YES];
    [self.restClient uploadFile:@"data.json" toPath:@"/" withParentRev:self.fileRev fromPath:self.localDataPath];
    
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
    self.fileRev = metadata.rev;
    [self.restClient loadFile:metadata.path intoPath:self.localDataPath];
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error {
    [self restClient:nil loadedFile:self.localDataPath];
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)destPath {
    
    void (^block)(NSDictionary *dict);
    
    if ([destPath isEqual:self.localSchemaPath]) {
        self.currentlyLoadingFile = self.localDataPath;
        [self.restClient loadMetadata:@"/data.json"];
        block = ^(NSDictionary *dict) {
            self.schema = [[Schema alloc] initWithDictionary:dict error:nil];
            NSLog(@"Read schema:\n%@", PRETTY_PRINT(self.schema));
            [self toast:@"✅Loaded Schema✅"];
        };
    } else {
        block = ^(NSDictionary *dict) {
            if (dict) {
                self.data = [[Data alloc] initWithDictionary:dict error:nil];
            }
            if (!self.data) {
                self.data = [Data new];
                self.data.events = [NSMutableArray<Event> new];
            }
            NSLog(@"Read data:\n%@", PRETTY_PRINT(self.data));
            [self toast:@"✅Loaded Data✅"];
        };
    }
    NSData *data = [NSData dataWithContentsOfFile:destPath];
    NSDictionary *dict = nil;
    if (data) {
        dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    }
    block(dict);
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
        [self writeToDropbox];
    }
}


- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    self.fileRev = metadata.rev;
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
