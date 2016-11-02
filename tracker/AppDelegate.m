//
//  AppDelegate.m
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "AppDelegate.h"
#import <DropboxSDK/DropboxSDK.h>
#import <Toast/UIView+Toast.h>
#import "SyncManager.h"
#import "DropboxSessionManager.h"
#import "tracker-Swift.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [CSToastManager setQueueEnabled:NO];
    
    [[DropboxSessionManager i] setupSession];
    
    self.window = [UIWindow new];
    self.window.rootViewController = [[SwiftViewController alloc] init];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [[DropboxSessionManager i] handleOpenURL:url];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
