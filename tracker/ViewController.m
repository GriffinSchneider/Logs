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
@interface ViewController ()

@property (nonatomic, strong) Schema *schema;
@property (nonatomic, strong) Data *data;

@property (nonatomic, strong) NSMutableArray<UIButton *> *buttons;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation ViewController


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    return self;
}

- (void)loadView {
    self.edgesForExtendedLayout = UIRectEdgeNone;
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

- (UIView *)buildGridWithLastView:(UIView *)lastVieww titles:(NSArray<NSString *> *)titles buttonBlock:(void (^)(UIButton *b, NSString *title))buttonBlock {
    __block UIView *lastView = lastVieww;
    build_subviews(self.view) {
        [titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
            UIButton *add_subview(button) {
                [_ setTitle:title forState:UIControlStateNormal];
                _.make.width.equalTo(superview).multipliedBy(0.45);
                if (idx % 2 == 0) {
                    _.make.left.equalTo(superview).with.offset(10);
                    _.make.top.equalTo(lastView.mas_bottom ?: superview).with.offset(10);
                } else {
                    _.make.top.equalTo(lastView);
                    _.make.right.equalTo(superview).with.offset(-10);
                }
            };
            buttonBlock(button, title);
            [self.buttons addObject:button];
            lastView = button;
        }];
    }
    return lastView;
}

- (void)buildView {
    NSDictionary<NSString *, Event *> *lastReadings = self.data.lastReadings;
    NSSet<NSString *> *activeStates = self.data.activeStates;
    NSSet<NSString *> *recentOccurrences = self.data.recentOccurrences;
    
    build_subviews(self.view) {
        _.backgroundColor = [UIColor purpleColor];
        __block UIView *add_subview(lastView) {
            _.make.top.equalTo(_.superview).with.offset(20);
        };
        lastView = [self buildGridWithLastView:lastView titles:self.schema.occurrences buttonBlock:^(UIButton *b, NSString *title) {
            if ([recentOccurrences containsObject:title]) {
                b.backgroundColor = [UIColor greenColor];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    b.backgroundColor = [UIColor orangeColor];
                });
            } else {
                b.backgroundColor = [UIColor orangeColor];
            }
            [b bk_addEventHandler:^(id _) {
                [self selectedOccurrence:title];
            } forControlEvents:UIControlEventTouchUpInside];
        }];
        UIView *add_subview(spacer) {
            _.make.height.equalTo(@0);
            _.make.top.equalTo(lastView.mas_bottom).with.offset(20);
        };
        lastView = spacer;
        lastView = [self buildGridWithLastView:lastView titles:self.schema.states buttonBlock:^(UIButton *b, NSString *title) {
            if ([activeStates containsObject:title]) {
                b.backgroundColor = [UIColor greenColor];
            } else {
                b.backgroundColor = [UIColor redColor];
            }
            [b bk_addEventHandler:^(id _) {
                [self selectedState:title];
            } forControlEvents:UIControlEventTouchUpInside];
        }];
        UIView *add_subview(spacer2) {
            _.make.height.equalTo(@0);
            _.make.top.equalTo(lastView.mas_bottom).with.offset(20);
        };
        lastView = spacer2;
        [self.schema.readings enumerateObjectsUsingBlock:^(NSString *reading, NSUInteger idx, BOOL *stop) {
            UISlider *add_subview(slider) {
                _.value = [lastReadings[reading].reading floatValue];
                _.make.left.equalTo(superview).with.offset(10);
                _.make.top.equalTo(lastView.mas_bottom).with.offset(15);
                if (idx > 0) { _.make.width.equalTo(lastView); }
            };
            UIButton *add_subview(button) {
                [_ setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                
                if ([[NSDate date] timeIntervalSinceDate:lastReadings[reading].date] < 1) {
                    _.backgroundColor = [UIColor greenColor];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        _.backgroundColor = [UIColor blueColor];
                    });
                } else {
                    _.backgroundColor = [UIColor blueColor];
                }
                
                _.make.top.and.bottom.equalTo(slider);
                _.make.right.equalTo(superview).with.offset(-10);
                _.make.left.equalTo(slider.mas_right).with.offset(10);
            };
            [self sliderChanged:slider forReading:reading withButton:button];
            [button bk_addEventHandler:^(id _) { [self madeReading:reading withSlider:slider]; } forControlEvents:UIControlEventTouchUpInside];
            [slider bk_addEventHandler:^(id _) { [self sliderChanged:slider forReading:reading withButton:button]; } forControlEvents:UIControlEventAllEvents];
            lastView = slider;
        }];
    };
}

- (void)addEvent:(Event *)e {
    NSSet<NSString *> *activeStates = self.data.activeStates;
    // If we're in sleep state but an event is toggled, we must not be asleep anymore.
    if ([activeStates containsObject:EVENT_SLEEP]) {
        Event *e = [Event new];
        e.type = EventTypeEndState;
        e.name = EVENT_SLEEP;
        e.date = [NSDate date];
        [self.data.events addObject:e];
    }
    [self.data.events addObject:e];
    [self saveToFile];
    [self rebuildView];
}

- (void)selectedOccurrence:(NSString *)occurrence {
    Event *e = [Event new];
    e.type = EventTypeOccurrence;
    e.name = occurrence;
    e.date = [NSDate date];
    [self addEvent:e];
}

- (void)selectedState:(NSString *)state {
    NSSet<NSString *> *activeStates = self.data.activeStates;
    Event *e = [Event new];
    e.type = [activeStates containsObject:state] ? EventTypeEndState : EventTypeStartState;
    e.name = state;
    e.date = [NSDate date];
    [self addEvent:e];
}

- (void)sliderChanged:(UISlider *)slider forReading:(NSString *)reading withButton:(UIButton *)button {
    [button setTitle:[NSString stringWithFormat:@"%@: %d", reading, (int)round(floorf(slider.value*10))] forState:UIControlStateNormal];
}

- (void)madeReading:(NSString *)reading withSlider:(UISlider *)slider {
    Event *e = [Event new];
    e.type = EventTypeReading;
    e.name = reading;
    e.date = [NSDate date];
    e.reading = [NSNumber numberWithFloat:slider.value];
    [self addEvent:e];
}

- (void)saveToFile {
    NSLog(@"Writing data:\n%@", [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[self.data toDictionary]
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
    NSData *data = [NSData dataWithContentsOfFile:[documentsDirectory stringByAppendingPathComponent:@"DATAR.json"]];
    
    NSDictionary *dict = nil;
    if (data) {
        dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    }
    if (dict) {
        self.data = [[Data alloc] initWithDictionary:dict error:nil];
    }
    if (!self.data) {
        self.data = [Data new];
        self.data.events = [NSMutableArray<Event> new];
    }
    
    NSLog(@"Read data:\n%@", [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[self.data toDictionary]
                                                                                           options:NSJSONWritingPrettyPrinted
                                                                                             error:nil]
                                                  encoding:NSUTF8StringEncoding]);
}

@end
