//
//  ViewController.m
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "ViewController.h"
#import <DRYUI/DRYUI.h>
#import <DropboxSDK/DropboxSDK.h>
#import "UIButton+ANDYHighlighted.h"
#import <Toast/UIView+Toast.h>

#import "ChameleonMacros.h"
#import "Schema.h"
#import "Data.h"
#import "ListViewController.h"
#import "TimelineViewController.h"
#import "SyncManager.h"
#import "Utils.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface ViewController () <DBRestClientDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString *, UIButton *> *occurrenceButtons;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIButton *> *stateButtons;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UISlider *> *readingSliders;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIButton *> *readingButtons;

@property (nonatomic, strong) NSTimer *updateTimer;

@property (nonatomic, strong) UIView *scrollViewWrapper;
@property (nonatomic, strong) UIScrollView *scrollView;

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
        self.preferredContentSize = CGSizeMake(0, 2000);
    }
    return self;
}


- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
    return UIEdgeInsetsZero;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    CGPoint contentOffset = self.scrollView.contentOffset;
    [UIView setAnimationsEnabled:NO];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.scrollViewWrapper.layer.affineTransform = CGAffineTransformInvert(context.targetTransform);
        self.scrollView.contentOffset = contentOffset;
        CGFloat rotation = atan2f(context.targetTransform.b, context.targetTransform.a);
        if (fabs(rotation - M_PI) > 0.0001 && fabs(rotation + M_PI) > 0.0001) {
            [self.scrollViewWrapper mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.equalTo(self.view.mas_width);
                make.width.equalTo(self.view.mas_height);
                make.center.equalTo(self.view);
            }];
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [UIView setAnimationsEnabled:YES];
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:0.3 animations:^{
            [self.scrollViewWrapper mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.equalTo(self.view);
                make.height.equalTo(self.view);
                make.center.equalTo(self.view);
            }];
            self.scrollViewWrapper.layer.affineTransform = CGAffineTransformIdentity;
            [self.view layoutIfNeeded];
        }];
    }];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}


- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)loadView {
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view = [UIView new];
    
    
    if ([[DBSession sharedSession] isLinked]) {
        [[SyncManager i] loadFromDisk];
    }
    
    
//    [RACObserve([SyncManager i], data) subscribeNext:^(id x) {
//        [self rebuildView];
//    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateViews];
    [self.updateTimer invalidate];
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateStateButtons) userInfo:nil repeats:YES];
}

- (void)rebuildView {
    [self.scrollViewWrapper removeFromSuperview];
    self.scrollView = nil;
    self.scrollViewWrapper = nil;
    [self buildView];
}

- (UIView *)buildGridInView:(UIView *)superview withLastView:(UIView *)lastVieww titles:(NSArray<NSString *> *)titles buttonBlock:(void (^)(UIButton *b, NSString *title))buttonBlock {
    __block UIView *lastView = lastVieww;
    build_subviews(superview) {
        [titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
            UIButton *add_subview(button) {
                [_ setTitleColor:FlatWhiteDark forState:UIControlStateNormal];
                [_ setTitle:title forState:UIControlStateNormal];
                _.layer.cornerRadius = 5;
                buttonBlock(_, title);
                _.highlightedBackgroundColor = [_.backgroundColor darkenByPercentage:0.2];
                if (lastView) {
                    make.width.equalTo(lastView);
                }
                if (idx % 2 == 0) {
                    make.left.equalTo(superview).with.offset(10);
                    make.top.equalTo(lastView.mas_bottom ?: superview).with.offset(10);
                } else {
                    make.top.equalTo(lastView);
                    make.left.equalTo(lastView.mas_right).with.offset(10);
                    make.right.equalTo(superview.superview).with.offset(-10);
                }
            };
            lastView = button;
        }];
    }
    return lastView;
}

- (UIView *)buildRowInView:(UIView *)superview withLastView:(UIView *)lastVieww titles:(NSArray<NSString *> *)titles buttonBlock:(void (^)(UIButton *b, NSString *title))buttonBlock {
    __block UIView *lastView = lastVieww;
    build_subviews(superview) {
        [titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
            UIButton *add_subview(button) {
                [_ setTitleColor:FlatWhiteDark forState:UIControlStateNormal];
                [_ setTitle:title forState:UIControlStateNormal];
                _.layer.cornerRadius = 5;
                _.adjustsImageWhenHighlighted = YES;
                make.top.equalTo(lastView);
                buttonBlock(_, title);
                _.highlightedBackgroundColor = [_.backgroundColor darkenByPercentage:0.2];
                if (idx == 0) {
                    make.left.equalTo(superview).with.offset(10);
                } else {
                    make.width.equalTo(lastView);
                    make.left.equalTo(lastView.mas_right).with.offset(10);
                }
                if (idx == titles.count-1) {
                    make.right.equalTo(superview.superview).with.offset(-10);
                }
            };
            lastView = button;
        }];
    }
    return lastView;
}


- (UIView *)buildSmallGridInView:(UIView *)superview withLastView:(UIView *)lastView titles:(NSArray<NSString *> *)titles buttonBlock:(void (^)(UIButton *b, NSString *title))buttonBlock {
    NSMutableArray<NSString *> *iter = [NSMutableArray new];
    for (NSString *title in titles) {
        [iter addObject:title];
        if (iter.count >= 5) {
            lastView = [self buildRowInView:superview withLastView:lastView titles:iter buttonBlock:buttonBlock];
            UIView *spacer;
            build_subviews(superview) {
                add_subview(spacer) {
                    make.height.equalTo(@0);
                    make.top.equalTo(lastView.mas_bottom).with.offset(3);
                };
            };
            lastView = spacer;
            [iter removeAllObjects];
        }
    }
    return lastView;
}

- (void)buildView {
//    @weakify(self);
    
    build_subviews(self.view) {
        _.backgroundColor = FlatNavyBlueDark;
        add_subview(self.scrollViewWrapper) {
            _.backgroundColor = FlatNavyBlueDark;
            make.width.and.height.equalTo(superview);
            make.center.equalTo(superview);
            add_subview(self.scrollView) {
                _.backgroundColor = FlatNavyBlueDark;
                make.width.and.height.equalTo(superview);
                make.center.equalTo(superview);
            };
        };
    };
    
    build_subviews(self.scrollView) {
        __block UIView *add_subview(lastView) {
            make.top.equalTo(_.superview).with.offset(30);
        };
        lastView = [self buildRowInView:_ withLastView:lastView titles:@[@"Edit", @"Timeline", @"Reload", @"Save"] buttonBlock:^(UIButton *b, NSString *title) {
            b.backgroundColor = FlatPlum;
//            @weakify(b);
//            [[b rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
//                @strongify(self);
//                @strongify(b);
//                if ([b.currentTitle isEqualToString:@"Edit"]) {
//                    ListViewController *lvc = [[ListViewController alloc] initWithDone:^{
//                        [self dismissViewControllerAnimated:YES completion:nil];
//                    }];
//                    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:lvc] animated:YES completion:^{}];
//                }
//                if ([b.currentTitle isEqualToString:@"Timeline"]) {
//                    TimelineViewController *vc = [[TimelineViewController alloc] initWithDone:^{
//                        [self dismissViewControllerAnimated:YES completion:nil];
//                    }];
//                    [self presentViewController:vc animated:YES completion:^{}];
//                }
//                if ([b.currentTitle isEqualToString:@"Reload"]) {
//                    [[SyncManager i] loadFromDisk];
//                    [self rebuildView];
//                }
//                if ([b.currentTitle isEqualToString:@"Save"]) {
//                    [[SyncManager i] saveImmediately];
//                }
//            }];
        }];
        UIView *add_subview(spacer) {
            make.height.equalTo(@0);
            make.top.equalTo(lastView.mas_bottom).with.offset(10);
        };
        lastView = spacer;
        lastView = [self buildGridInView:_ withLastView:lastView titles:[SyncManager i].schema.occurrences buttonBlock:^(UIButton *b, NSString *title) {
            b.backgroundColor = FlatOrangeDark;
            self.occurrenceButtons[title] = b;
//            [[b rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
//                @strongify(self);
//                [self selectedOccurrence:title];
//            }];
        }];
        UIView *add_subview(spacer2) {
            make.height.equalTo(@0);
            make.top.equalTo(lastView.mas_bottom).with.offset(10);
        };
        lastView = spacer2;
        NSMutableArray *titles = [NSMutableArray new];
        for (StateSchema *s in [SyncManager i].schema.states) [titles addObject:s.name];
        lastView = [self buildGridInView:_ withLastView:lastView titles:titles buttonBlock:^(UIButton *b, NSString *title) {
            self.stateButtons[title] = b;
//            [[b rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
//                @strongify(self);
//                [self selectedState:title];
//            }];
        }];
        UIView *add_subview(spacer3) {
            make.height.equalTo(@0);
            make.top.equalTo(lastView.mas_bottom).with.offset(10);
        };
        lastView = spacer3;
        [[SyncManager i].schema.readings enumerateObjectsUsingBlock:^(NSString *reading, NSUInteger idx, BOOL *stop) {
            UISlider *add_subview(slider) {
                _.thumbTintColor = FlatGreenDark;
                _.minimumTrackTintColor = FlatGreenDark;
                _.maximumTrackTintColor = FlatRedDark;
                self.readingSliders[reading] = _;
                make.left.equalTo(superview).with.offset(10);
                make.top.equalTo(lastView.mas_bottom).with.offset(15);
                if (idx > 0) { make.width.equalTo(lastView); }
            };
            UIButton *add_subview(button) {
                [_ setTitleColor:FlatWhiteDark forState:UIControlStateNormal];
                _.backgroundColor = FlatBlueDark;
                _.layer.cornerRadius = 5;
                self.readingButtons[reading] = _;
                make.top.and.bottom.equalTo(slider);
                make.right.equalTo(superview.superview).with.offset(-10);
                make.left.equalTo(slider.mas_right).with.offset(10);
            };
//            [[button rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
//                @strongify(self);
//                [self madeReading:reading withSlider:slider];
//            }];
//            [[slider rac_signalForControlEvents:UIControlEventAllEvents] subscribeNext:^(id x) {
//                @strongify(self);
//                [self sliderChanged:slider forReading:reading withButton:button];
//            }];
            lastView = slider;
        }];
        [lastView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.scrollView.mas_bottom).with.offset(-15);
        }];
    };
    
    [self updateViews];
}

- (void)updateViews {
    [self updateStateButtons];
    NSDictionary<NSString *, EEvent *> *lastReadings = [SyncManager i].data.lastReadings;
    [self.readingSliders enumerateKeysAndObjectsUsingBlock:^(NSString *eventName, UISlider *slider, BOOL *stop) {
        slider.value = lastReadings[eventName].reading.floatValue;
        [self sliderChanged:slider forReading:eventName withButton:self.readingButtons[eventName]];
    }];
}

- (void)updateStateButtons {
    NSSet<EEvent *> *activeStates = [SyncManager i].data.activeStates;
    [self.stateButtons enumerateKeysAndObjectsUsingBlock:^(NSString *eventName, UIButton *b, BOOL *stop) {
        EEvent *e = eventNamed(activeStates, eventName);
        if (e) {
            b.backgroundColor = FlatGreenDark;
            [b setTitle:[NSString stringWithFormat:@"%@ (%@)", e.name, formatDuration([[NSDate date] timeIntervalSinceDate:e.date])] forState:UIControlStateNormal];
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

- (void)addEvent:(EEvent *)e {
    [[SyncManager i].data addEvent:e];
    [[SyncManager i] writeToDisk];
    [self updateViews];
}

- (void)selectedOccurrence:(NSString *)occurrence {
    EEvent *e = [EEvent new];
    e.type = EventTypeOccurrence;
    e.name = occurrence;
    e.date = [NSDate date];
    [self addEvent:e];
    [self momentaryGreenButton:self.occurrenceButtons[occurrence]];
}

- (void)selectedState:(NSString *)state {
    NSSet<EEvent *> *activeStates = [SyncManager i].data.activeStates;
    EEvent *e = [EEvent new];
    e.type = eventNamed(activeStates, state) ? EventTypeEndState : EventTypeStartState;
    e.name = state;
    e.date = [NSDate date];
    [self addEvent:e];
}

- (void)sliderChanged:(UISlider *)slider forReading:(NSString *)reading withButton:(UIButton *)button {
    [button setTitle:[NSString stringWithFormat:@"%@: %d", reading, (int)round(floorf(slider.value*10))] forState:UIControlStateNormal];
}

- (void)madeReading:(NSString *)reading withSlider:(UISlider *)slider {
    EEvent *e = [EEvent new];
    e.type = EventTypeReading;
    e.name = reading;
    e.date = [NSDate date];
    e.reading = [NSNumber numberWithFloat:slider.value];
    [self addEvent:e];
    [self momentaryGreenButton:self.readingButtons[reading]];
}

@end
