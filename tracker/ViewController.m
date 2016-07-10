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
#import <ChameleonFramework/Chameleon.h>
#import <DropboxSDK/DropboxSDK.h>
#import "UIButton+ANDYHighlighted.h"
#import <Toast/UIView+Toast.h>

#import "Schema.h"
#import "Data.h"
#import "ListViewController.h"
#import "SyncManager.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface ViewController () <DBRestClientDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString *, UIButton *> *occurrenceButtons;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIButton *> *stateButtons;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UISlider *> *readingSliders;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIButton *> *readingButtons;

@property (nonatomic, strong) NSTimer *updateTimer;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation ViewController


- (instancetype)init {
    if ((self = [super init])) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.occurrenceButtons = [NSMutableDictionary new];
        self.stateButtons = [NSMutableDictionary new];
        self.readingSliders = [NSMutableDictionary new];
        self.readingButtons = [NSMutableDictionary new];
        [[UINavigationBar appearance] setBarTintColor:FlatGrayDark];
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)loadView {
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view = [UIView new];
    
    [RACObserve([SyncManager i], data) subscribeNext:^(id x) {
        [self rebuildView];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateViews];
    [self.updateTimer invalidate];
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateStateButtons) userInfo:nil repeats:YES];
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
                [_ setTitleColor:FlatWhiteDark forState:UIControlStateNormal];
                [_ setTitle:title forState:UIControlStateNormal];
                _.layer.cornerRadius = 5;
                _.adjustsImageWhenHighlighted = YES;
                buttonBlock(_, title);
                _.highlightedBackgroundColor = [_.backgroundColor darkenByPercentage:0.2];
                if (lastView) {
                    _.make.width.equalTo(lastView);
                }
                if (idx % 2 == 0) {
                    _.make.left.equalTo(superview).with.offset(10);
                    _.make.top.equalTo(lastView.mas_bottom ?: superview).with.offset(10);
                } else {
                    _.make.top.equalTo(lastView);
                    _.make.left.equalTo(lastView.mas_right).with.offset(10);
                    _.make.right.equalTo(superview).with.offset(-10);
                }
            };
            lastView = button;
        }];
    }
    return lastView;
}

- (UIView *)buildRowWithLastView:(UIView *)lastVieww titles:(NSArray<NSString *> *)titles buttonBlock:(void (^)(UIButton *b, NSString *title))buttonBlock {
    __block UIView *lastView = lastVieww;
    build_subviews(self.view) {
        [titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
            UIButton *add_subview(button) {
                [_ setTitleColor:FlatWhiteDark forState:UIControlStateNormal];
                [_ setTitle:title forState:UIControlStateNormal];
                _.layer.cornerRadius = 5;
                _.adjustsImageWhenHighlighted = YES;
                _.make.top.equalTo(lastView);
                buttonBlock(_, title);
                _.highlightedBackgroundColor = [_.backgroundColor darkenByPercentage:0.2];
                if (idx == 0) {
                    _.make.left.equalTo(superview).with.offset(10);
                } else {
                    _.make.width.equalTo(lastView);
                    _.make.left.equalTo(lastView.mas_right).with.offset(10);
                }
                if (idx == titles.count-1) {
                    _.make.right.equalTo(superview).with.offset(-10);
                }
            };
            lastView = button;
        }];
    }
    return lastView;
}

- (void)buildView {
    __block UIScrollView *scrollView;
    build_subviews(self.view) {
        add_subview(scrollView) {
            _.make.edges.equalTo(superview);
        };
    };
    
    build_subviews(scrollView) {
        _.backgroundColor = FlatNavyBlueDark;
        __block UIView *add_subview(lastView) {
            _.make.top.equalTo(_.superview).with.offset(30);
        };
        lastView = [self buildRowWithLastView:lastView titles:@[@"Edit", @"Reload", @"Save"] buttonBlock:^(UIButton *b, NSString *title) {
            b.backgroundColor = FlatPlum;
            [b bk_addEventHandler:^(UIButton *sender) {
                if ([sender.currentTitle isEqualToString:@"Edit"]) {
                    ListViewController *lvc = [[ListViewController alloc] initWithDone:^{
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }];
                    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:lvc] animated:YES completion:^{}];
                }
                if ([sender.currentTitle isEqualToString:@"Reload"]) {
                    [[SyncManager i] loadFromDropbox];
                }
                if ([sender.currentTitle isEqualToString:@"Save"]) {
                    [[SyncManager i] saveImmediately];
                }
            } forControlEvents:UIControlEventTouchUpInside];
        }];
        UIView *add_subview(spacer) {
            _.make.height.equalTo(@0);
            _.make.top.equalTo(lastView.mas_bottom).with.offset(10);
        };
        lastView = spacer;
        lastView = [self buildGridWithLastView:lastView titles:[SyncManager i].schema.occurrences buttonBlock:^(UIButton *b, NSString *title) {
            b.backgroundColor = FlatOrangeDark;
            self.occurrenceButtons[title] = b;
            [b bk_addEventHandler:^(id _) {
                [self selectedOccurrence:title];
            } forControlEvents:UIControlEventTouchUpInside];
        }];
        UIView *add_subview(spacer2) {
            _.make.height.equalTo(@0);
            _.make.top.equalTo(lastView.mas_bottom).with.offset(10);
        };
        lastView = spacer2;
        lastView = [self buildGridWithLastView:lastView titles:[SyncManager i].schema.states buttonBlock:^(UIButton *b, NSString *title) {
            self.stateButtons[title] = b;
            [b bk_addEventHandler:^(id _) {
                [self selectedState:title];
            } forControlEvents:UIControlEventTouchUpInside];
        }];
        UIView *add_subview(spacer3) {
            _.make.height.equalTo(@0);
            _.make.top.equalTo(lastView.mas_bottom).with.offset(10);
        };
        lastView = spacer3;
        [[SyncManager i].schema.readings enumerateObjectsUsingBlock:^(NSString *reading, NSUInteger idx, BOOL *stop) {
            UISlider *add_subview(slider) {
                _.thumbTintColor = FlatGreenDark;
                _.minimumTrackTintColor = FlatGreenDark;
                _.maximumTrackTintColor = FlatRedDark;
                self.readingSliders[reading] = _;
                _.make.left.equalTo(superview).with.offset(10);
                _.make.top.equalTo(lastView.mas_bottom).with.offset(15);
                if (idx > 0) { _.make.width.equalTo(lastView); }
            };
            UIButton *add_subview(button) {
                [_ setTitleColor:FlatWhiteDark forState:UIControlStateNormal];
                _.backgroundColor = FlatBlueDark;
                _.layer.cornerRadius = 5;
                self.readingButtons[reading] = _;
                _.make.top.and.bottom.equalTo(slider);
                _.make.right.equalTo(superview.superview).with.offset(-10);
                _.make.left.equalTo(slider.mas_right).with.offset(10);
            };
            [button bk_addEventHandler:^(id _) { [self madeReading:reading withSlider:slider]; } forControlEvents:UIControlEventTouchUpInside];
            [slider bk_addEventHandler:^(id _) { [self sliderChanged:slider forReading:reading withButton:button]; } forControlEvents:UIControlEventAllEvents];
            lastView = slider;
        }];
        [lastView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(scrollView.mas_bottom).with.offset(-15);
        }];
    };
    
    [self updateViews];
}

- (void)updateViews {
    [self updateStateButtons];
    NSDictionary<NSString *, Event *> *lastReadings = [SyncManager i].data.lastReadings;
    [self.readingSliders enumerateKeysAndObjectsUsingBlock:^(NSString *eventName, UISlider *slider, BOOL *stop) {
        slider.value = lastReadings[eventName].reading.floatValue;
        [self sliderChanged:slider forReading:eventName withButton:self.readingButtons[eventName]];
    }];
}

- (void)updateStateButtons {
    NSSet<Event *> *activeStates = [SyncManager i].data.activeStates;
    [self.stateButtons enumerateKeysAndObjectsUsingBlock:^(NSString *eventName, UIButton *b, BOOL *stop) {
        Event *e = eventNamed(activeStates, eventName);
        if (e) {
            b.backgroundColor = FlatGreenDark;
            NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:e.date];
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
            NSDateFormatter *dateFormatter = [NSDateFormatter new];
            [dateFormatter setDateFormat:@"HH:mm:ss"];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
            [b setTitle:[NSString stringWithFormat:@"%@ (%@)", e.name, [dateFormatter stringFromDate:date]] forState:UIControlStateNormal];
        } else {
            b.backgroundColor = FlatRedDark;
            [b setTitle:eventName forState:UIControlStateNormal];
        }
        b.highlightedBackgroundColor = [b.backgroundColor darkenByPercentage:0.2];
    }];
}

- (void)momentaryGreenButton:(UIButton *)b {
    UIColor *old = b.backgroundColor;
    b.layer.backgroundColor = FlatGreenDark.CGColor;
    [UIView animateWithDuration:3.0 animations:^{
        b.layer.backgroundColor = old.CGColor;
    }];
}

- (void)addEvent:(Event *)e {
    NSSet<Event *> *activeStates = [SyncManager i].data.activeStates;
    // If we're in sleep state but an event is added, we must not be asleep anymore.
    if (eventNamed(activeStates, EVENT_SLEEP)) {
        Event *e = [Event new];
        e.type = EventTypeEndState;
        e.name = EVENT_SLEEP;
        e.date = [NSDate date];
        [[SyncManager i].data addEvent:e];
    }
    [[SyncManager i].data addEvent:e];
    [self updateViews];
}

- (void)selectedOccurrence:(NSString *)occurrence {
    Event *e = [Event new];
    e.type = EventTypeOccurrence;
    e.name = occurrence;
    e.date = [NSDate date];
    [self addEvent:e];
    [self momentaryGreenButton:self.occurrenceButtons[occurrence]];
}

- (void)selectedState:(NSString *)state {
    NSSet<Event *> *activeStates = [SyncManager i].data.activeStates;
    Event *e = [Event new];
    e.type = eventNamed(activeStates, state) ? EventTypeEndState : EventTypeStartState;
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
    [self momentaryGreenButton:self.readingButtons[reading]];
}

@end
