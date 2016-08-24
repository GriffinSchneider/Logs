//
//  DropboxSessionManager.m
//  tracker
//
//  Created by Griffin on 8/24/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "DropboxSessionManager.h"
#import <DropboxSDK/DropboxSDK.h>
#import "SyncManager.h"


#define SS(x) #x
#define S(x) SS(x)


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface DropboxSessionManager () <DBSessionDelegate, DBNetworkRequestDelegate>

@property (nonatomic, strong) NSString *relinkUserId;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation DropboxSessionManager

+ (instancetype)i {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)setupSession {
    
    NSString* appKey = @S(DROPBOX_APP_KEY);
    NSString *appSecret = @S(DROPBOX_SECRET);
    NSString *root = kDBRootAppFolder;
    
    NSString* errorMsg = nil;
    if ([appKey rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
        errorMsg = @"Make sure you set the app key correctly in DBRouletteAppDelegate.m";
    } else if ([appSecret rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
        errorMsg = @"Make sure you set the app secret correctly in DBRouletteAppDelegate.m";
    } else if ([root length] == 0) {
        errorMsg = @"Set your root to use either App Folder of full Dropbox";
    } else {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        NSData *plistData = [NSData dataWithContentsOfFile:plistPath];
        NSDictionary *loadedPlist = [NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:0 format:NULL errorDescription:NULL];
        NSString *scheme = [[[[loadedPlist objectForKey:@"CFBundleURLTypes"] objectAtIndex:0] objectForKey:@"CFBundleURLSchemes"] objectAtIndex:0];
        if ([scheme isEqual:@"db-APP_KEY"]) {
            errorMsg = @"Set your URL scheme correctly in DBRoulette-Info.plist";
        }
    }
    
    if (errorMsg != nil) {
        [[[UIAlertView alloc]
          initWithTitle:@"Error Configuring Dropbox" message:errorMsg
          delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
         show];
    }
    
    DBSession* session = [[DBSession alloc] initWithAppKey:appKey appSecret:appSecret root:root];
    session.delegate = self; // DBSessionDelegate methods allow you to handle re-authenticating
    [DBSession setSharedSession:session];
    
    [DBRequest setNetworkRequestDelegate:self];
}

- (BOOL)handleOpenURL:(NSURL *)url {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if (![[DBSession sharedSession] isLinked]) {
            NSAssert(NO, @"something went wrong with dropbox.");
        }
        return YES;
    }
    NSAssert(NO, @"something went wrong with dropbox.");
    return NO;
}


#pragma mark -
#pragma mark DBSessionDelegate methods

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId {
    self.relinkUserId = userId;
    [[SyncManager i] hideActivity];
    [[[UIAlertView alloc]
      initWithTitle:@"Dropbox Session Ended" message:@"Do you want to relink?" delegate:self
      cancelButtonTitle:@"Cancel" otherButtonTitles:@"Relink", nil]
     show];
}


#pragma mark -
#pragma mark DBNetworkRequestDelegate methods

static int outstandingRequests;

- (void)networkRequestStarted {
    outstandingRequests++;
    if (outstandingRequests == 1) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
}

- (void)networkRequestStopped {
    outstandingRequests--;
    if (outstandingRequests == 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}


#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {
    if (index != alertView.cancelButtonIndex) {
        [[DBSession sharedSession] linkUserId:self.relinkUserId fromController:[UIApplication sharedApplication].keyWindow.rootViewController];
    }
    self.relinkUserId = nil;
}



@end
