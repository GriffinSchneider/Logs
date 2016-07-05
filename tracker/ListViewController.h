//
//  ListViewController.h
//  tracker
//
//  Created by Griffin on 7/4/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Schema.h"
#import "Data.h"

typedef void (^ListViewControllerDoneBlock)();

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface ListViewController : UIViewController

- (instancetype)initWithSchema:(Schema *)schema andData:(Data *)data done:(ListViewControllerDoneBlock)done;

@end
