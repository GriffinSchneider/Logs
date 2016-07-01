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
    
    [self readFromFile];
    
    [self buildView];
}

- (void)rebuildView {
    [self.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    [self buildView];
}

- (void)buildView {
    NSSet<NSString *> *activeStates = self.data.activeStates;
    
    build_subviews(self.view) {
        _.backgroundColor = [UIColor purpleColor];
        __block UIButton *lastButton = nil;
        [self.schema.states enumerateObjectsUsingBlock:^(NSString *state, NSUInteger idx, BOOL *stop) {
            UIButton *add_subview(button) {
                if ([activeStates containsObject:state]) {
                    _.backgroundColor = [UIColor greenColor];
                } else {
                    _.backgroundColor = [UIColor redColor];
                }
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
            [button bk_addEventHandler:^(id _) { [self selectedState:state]; } forControlEvents:UIControlEventTouchUpInside];
            [self.buttons addObject:button];
            lastButton = button;
        }];
    };
}

- (void)selectedState:(NSString *)state {
    NSSet<NSString *> *activeStates = self.data.activeStates;
    
    // If we're in sleep state but an event is toggled, we must not be asleep anymore.
    if ([activeStates containsObject:EVENT_SLEEP]) {
        Event *e = [Event new];
        e.name = EVENT_SLEEP;
        e.type = EventTypeEndState;
        e.date = [NSDate date];
        [self.data.events addObject:e];
    }
    
    Event *e = [Event new];
    e.name = state;
    e.type = [activeStates containsObject:state] ? EventTypeEndState : EventTypeStartState;
    e.date = [NSDate date];
    [self.data.events addObject:e];
    [self saveToFile];
    [self rebuildView];
}

- (void)saveToFile {
    NSLog(@"Writing data: %@", [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[self.data toDictionary]
                                                                                              options:NSJSONWritingPrettyPrinted
                                                                                                error:nil]
                                                     encoding:NSUTF8StringEncoding]);
    NSData *nsData = [self.data toJSONData];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"DATAR.json"];
    [nsData writeToFile:appFile atomically:YES];
}

- (void)readFromFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[documentsDirectory stringByAppendingPathComponent:@"DATAR.json"]] options:0 error:nil];
    
    self.data = [[Data alloc] initWithDictionary:dict error:nil];
    
//    if (!self.data) {
//        self.data = [Data new];
//        self.data.events = [NSMutableArray new];
//    }
    
    NSLog(@"Read data: %@", [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[self.data toDictionary]
                                                                                           options:NSJSONWritingPrettyPrinted
                                                                                             error:nil]
                                                  encoding:NSUTF8StringEncoding]);
}

@end
