//
//  DropboxSessionManager.h
//  tracker
//
//  Created by Griffin on 8/24/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface DropboxSessionManager : NSObject

+ (instancetype)i;

- (void)setupSession;
- (BOOL)handleOpenURL:(NSURL *)url;

@end
