//
//  ViewController.m
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "ViewController.h"
#import <DRYUI/DRYUI.h>
#import <BlocksKit/BlocksKit+UIKit.h>

#import "Schema.h"
#import "Data.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface ViewController () <
UICollectionViewDataSource,
UICollectionViewDelegate
>

@property (nonatomic, strong) Schema *schema;
@property (nonatomic, strong) Data *data;

@property (nonatomic, strong) NSMutableArray<UIButton *> *buttons;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation ViewController


- (void)loadView {
    self.view = [UIView new];
    self.buttons = [NSMutableArray array];
    
    self.schema = [Schema get];
    
    self.data = [[Data alloc] initWithDictionary:
                  @{@"events": @[
                            @{
                                @"name": @"outside",
                                @"type": @(EventTypeStartState)
                                }
                            ]
                    } error:nil];
    
    [self saveToFile];
    [self readFromFile];
    
    build_subviews(self.view) {
        _.backgroundColor = [UIColor purpleColor];
        __block UIButton *lastButton = nil;
        [self.schema.states enumerateObjectsUsingBlock:^(NSString *state, NSUInteger idx, BOOL *stop) {
            UIButton *add_subview(button) {
                _.backgroundColor = [UIColor redColor];
                [_ setTitle:state forState:UIControlStateNormal];
                _.make.width.equalTo(superview).multipliedBy(0.45);
                if (idx % 2 == 0) {
                    _.make.left.equalTo(superview).with.offset(10);
                    _.make.top.equalTo(lastButton.mas_bottom ?: superview).with.offset(10);
                } else {
                    _.make.top.equalTo(lastButton);
                    _.make.right.equalTo(superview).with.offset(-10);
                }
            };
            
            [button bk_addEventHandler:^(id _) {
            } forControlEvents:UIControlEventTouchUpInside];
            
            [self.buttons addObject:button];
            lastButton = button;
        }];
    };
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)saveToFile {
    NSData *nsData = [self.data toJSONData];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"DATAR.json"];
    [nsData writeToFile:appFile atomically:YES];
}

- (void)readFromFile {
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    [NSData dataWithContentsOfFile:[documentsDirectory stringByAppendingPathComponent:@"DATAR.json"]];
//    
//    self.data =
//    [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[documentsDirectory stringByAppendingPathComponent:@"DATAR.json"]]
//                                    options:NSJSONReadingMutableLeaves
//                                      error:nil];
}

@end
