//
//  AppDelegate.m
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import <DropboxSDK/DropboxSDK.h>
#import <Toast/UIView+Toast.h>
#import "SyncManager.h"

@interface AppDelegate () <DBSessionDelegate, DBNetworkRequestDelegate>

@property (nonatomic, strong) NSString *relinkUserId;

@end

@implementation AppDelegate

#define SS(x) #x
#define S(x) SS(x)

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [CSToastManager setQueueEnabled:NO];
    
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
    
    self.window = [UIWindow new];
    [self.window makeKeyAndVisible];
    self.window.rootViewController = [ViewController new];
    
    if ([[DBSession sharedSession] isLinked]) {
        [[SyncManager i] loadFromDropbox];
    }
    
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if (![[DBSession sharedSession] isLinked]) {
            NSAssert(NO, @"something went wrong with dropbox.");
        }
        return YES;
    }
    NSAssert(NO, @"something went wrong with dropbox.");
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [[SyncManager i] saveImmediately];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[SyncManager i] loadFromDropbox];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark -
#pragma mark DBSessionDelegate methods

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId {
    self.relinkUserId = userId;
    [[[UIAlertView alloc]
      initWithTitle:@"Dropbox Session Ended" message:@"Do you want to relink?" delegate:self
      cancelButtonTitle:@"Cancel" otherButtonTitles:@"Relink", nil]
     show];
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {
    if (index != alertView.cancelButtonIndex) {
        [[DBSession sharedSession] linkUserId:self.relinkUserId fromController:self.window.rootViewController];
    }
    self.relinkUserId = nil;
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

@end
