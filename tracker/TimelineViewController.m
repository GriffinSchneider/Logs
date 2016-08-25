//
//  TimelineViewController.m
//  tracker
//
//  Created by Griffin Schneider on 7/21/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "TimelineViewController.h"
#import <DRYUI/DRYUI.h>
#import "UIButton+ANDYHighlighted.h"

#import "ChameleonMacros.h"
#import "SyncManager.h"
#import "Utils.h"
#import "EventViewController.h"
#import "TimelineColumnView.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TimelineViewController ()

@property (nonatomic, strong) TimelineViewControllerDoneBlock done;

@property (nonatomic, strong) UIView *scrollViewWrapper;
@property (nonatomic, strong) UIScrollView *horizontalScrollView;
@property (nonatomic, strong) UIScrollView *verticalScrollView;
@property (nonatomic, strong) NSArray <TimelineColumnView *> *columns;
@property (nonatomic, strong) NSMutableArray <NSLayoutConstraint *> *columnHeightConstraints;
@property (nonatomic, strong) NSMutableArray <MASConstraint *> *rotationStartWrapperConstraints;
@property (nonatomic, strong) NSMutableArray <MASConstraint *> *rotationEndWrapperConstraints;
@property (nonatomic, strong) NSMutableArray <MASConstraint *> *portraitConstraints;
@property (nonatomic, strong) NSMutableArray <MASConstraint *> *landscapeConstraints;

@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGesture;

@property (nonatomic, assign) CGFloat currentZoom;

@property (nonatomic, assign) CGPoint lastPortraitHorizontalContentOffset;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TimelineViewController


- (instancetype)initWithDone:(TimelineViewControllerDoneBlock)done {
    if ((self = [super init])) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.done = done;
        self.currentZoom = 1.0;
    }
    return self;
}


- (void)handlePinch:(UIPinchGestureRecognizer *)gesture {
    CGFloat zoom = self.currentZoom * (gesture.scale ?: 1.0f);
    if (gesture.state == UIGestureRecognizerStateEnded) {
        self.currentZoom = zoom;
    }
    for (NSLayoutConstraint *constraint in self.columnHeightConstraints) {
        constraint.constant = self.view.frame.size.height * zoom;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [UIView setAnimationsEnabled:NO];
    CGPoint horizontalContentOffset = self.horizontalScrollView.contentOffset;
    CGPoint verticalContentOffset = self.verticalScrollView.contentOffset;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.horizontalScrollView.contentOffset = horizontalContentOffset;
        self.verticalScrollView.contentOffset = verticalContentOffset;
        self.scrollViewWrapper.layer.affineTransform = CGAffineTransformInvert(context.targetTransform);
        CGFloat rotation = atan2f(context.targetTransform.b, context.targetTransform.a);
        if (fabs(rotation - M_PI) > 0.0001 && fabs(rotation + M_PI) > 0.0001) {
            for (MASConstraint *constraint in self.rotationEndWrapperConstraints) {
                [constraint uninstall];
            }
            for (MASConstraint *constraint in self.rotationStartWrapperConstraints) {
                [constraint install];
            }
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [UIView setAnimationsEnabled:YES];
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:0.5 animations:^{
            [self updateConstraintsForOrientation];
            self.scrollViewWrapper.layer.affineTransform = CGAffineTransformIdentity;
            [self handlePinch:nil];
            [self.view layoutIfNeeded];
            if (self.view.frame.size.height > self.view.frame.size.width) {
                self.horizontalScrollView.contentOffset = self.lastPortraitHorizontalContentOffset;
            } else {
                self.lastPortraitHorizontalContentOffset = horizontalContentOffset;
            }
        }];
    }];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)updateConstraintsForOrientation {
    BOOL isPortrait = self.view.bounds.size.height > self.view.bounds.size.width;
    
    for (MASConstraint *constraint in self.rotationStartWrapperConstraints) {
        [constraint uninstall];
    }
    for (MASConstraint *constraint in self.rotationEndWrapperConstraints) {
        [constraint install];
    }
    if (isPortrait) {
        for (MASConstraint *constraint in self.landscapeConstraints) [constraint uninstall];
        for (MASConstraint *constraint in self.portraitConstraints) [constraint install];
    } else {
        for (MASConstraint *constraint in self.portraitConstraints) [constraint uninstall];
        for (MASConstraint *constraint in self.landscapeConstraints) [constraint install];
    }
    
    BOOL makeHeightConstraints = NO;
    if (!self.columnHeightConstraints) {
        self.columnHeightConstraints = [NSMutableArray new];
        makeHeightConstraints = YES;
    }
    
    __block TimelineColumnView *lastColumn;
    [self.columns enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TimelineColumnView *column, NSUInteger idx, BOOL *stop) {
        if (makeHeightConstraints) {
            NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:column attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:200.0];
            [column.superview addConstraint:constraint];
            [self.columnHeightConstraints addObject:constraint];
        }
        
        lastColumn = column;
    }];
}

- (void)createColumns {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps = [NSDateComponents new];
    NSDate *dateIdx = [NSDate date];
    NSDate *minDate = [NSDate date];
    NSDate *maxDate = [NSDate dateWithTimeIntervalSince1970:0];
    NSMutableArray<NSArray<Event *> *> *eventsByDay = [NSMutableArray new];
    
    for (int i = 0; i < 7; i++) {
        NSArray<Event *> *events = [[SyncManager i].data eventsForDay:dateIdx];
        
        comps.day = -1;
        dateIdx = [cal dateByAddingComponents:comps toDate:dateIdx options:0];
        comps.day = 0;
        
        [eventsByDay addObject:events];
        if (!events.count) {
            continue ;
        }
        
        NSDate *dayMinDate = [NSDate date];
        NSDate *dayMaxDate = [NSDate dateWithTimeIntervalSince1970:0];
        
        for (Event *e in events) {
            if (e.type == EventTypeStartState &&
                [e.name isEqualToString:EVENT_SLEEP] &&
                [e.date compare:dayMaxDate] == NSOrderedDescending) {
                dayMaxDate = e.date;
            }
            if (e.type == EventTypeEndState &&
                [e.name isEqualToString:EVENT_SLEEP] &&
                [e.date compare:dayMinDate] == NSOrderedAscending) {
                dayMinDate = e.date;
            }
        }
        
        comps.day = i;
        NSDate *scaledDayMaxDate = [cal dateByAddingComponents:comps toDate:dayMaxDate options:0];
        NSDate *scaledDayMinDate = [cal dateByAddingComponents:comps toDate:dayMinDate options:0];
        if ([scaledDayMaxDate compare:maxDate] == NSOrderedDescending) maxDate = scaledDayMaxDate;
        if ([scaledDayMinDate compare:minDate] == NSOrderedAscending) minDate = scaledDayMinDate;
        comps.day = 0;
    }
    
    comps.hour = -1;
    minDate = [cal dateByAddingComponents:comps toDate:minDate options:0];
    comps.hour = 1;
    maxDate = [cal dateByAddingComponents:comps toDate:maxDate options:0];
    comps.hour = 0;
    
    NSMutableArray<TimelineColumnView *> *columns = [NSMutableArray new];
    for (int i = 0; i < 7; i++) {
        NSArray<Event *> *day = eventsByDay[i];
        comps.day = -i;
        NSDate *scaledMinDate = [cal dateByAddingComponents:comps toDate:minDate options:0];
        NSDate *scaledMaxDate = [cal dateByAddingComponents:comps toDate:maxDate options:0];
        [columns addObject:[[TimelineColumnView alloc] initWithEvents:day startTime:scaledMinDate endTime:scaledMaxDate]];
    }
    
    self.columns = columns;
}


- (void)loadView {
    self.view = [UIView new];
    self.pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    
    self.rotationStartWrapperConstraints = [NSMutableArray new];
    self.rotationEndWrapperConstraints = [NSMutableArray new];
    self.portraitConstraints = [NSMutableArray new];
    self.landscapeConstraints = [NSMutableArray new];
    
    [self createColumns];
    
    build_subviews(self.view) {
        [self.view addGestureRecognizer:self.pinchGesture];
        _.clipsToBounds = YES;
        _.backgroundColor = FlatNavyBlueDark;
        add_subview(self.scrollViewWrapper) {
            _.clipsToBounds = NO;
            make.center.equalTo(self.view);
            [self.rotationStartWrapperConstraints addObjectsFromArray:
             @[make.height.equalTo(self.view.mas_width),
               make.width.equalTo(self.view.mas_height)]];
            [self.rotationEndWrapperConstraints addObjectsFromArray:
             @[make.width.equalTo(self.view),
               make.height.equalTo(self.view)]];
            add_subview(self.verticalScrollView) {
                _.clipsToBounds = NO;
                make.width.height.left.and.top.equalTo(superview);
                add_subview(self.horizontalScrollView) {
                    _.clipsToBounds = NO;
                    _.pagingEnabled = YES;
                    _.showsHorizontalScrollIndicator = NO;
                    _.bounces = NO;
                    make.top.left.and.right.equalTo(superview);
                    make.width.equalTo(superview.superview);
                    make.bottom.equalTo(superview);
                    [self.columns enumerateObjectsUsingBlock:^(TimelineColumnView *column, NSUInteger idx, BOOL *stop) {
                        make.height.greaterThanOrEqualTo(column);
                    }];
                    TimelineColumnView *lastColumn = nil;
                    for (__strong TimelineColumnView *col in self.columns.reverseObjectEnumerator) {
                        add_subview(col) {
                            [self.portraitConstraints addObjectsFromArray:
                             @[make.width.equalTo(superview.superview)]];
                            [self.landscapeConstraints addObjectsFromArray:
                             @[make.width.equalTo(superview.superview).multipliedBy(1.0/self.columns.count)]];
                            make.top.equalTo(superview);
                            make.bottom.lessThanOrEqualTo(superview);
                            make.left.equalTo(lastColumn.mas_right ?: superview);
                            make.right.lessThanOrEqualTo(superview);
                        }
                        lastColumn = col;
                    }
                };
            };
            
            UIButton *add_subview(closeButton) {
                [_ setTitle:@"×" forState:UIControlStateNormal];
                _.backgroundColor = [UIColor clearColor];
                _.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
                _.titleColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3];
                make.right.and.bottom.equalTo(superview).with.insets(UIEdgeInsetsMake(0, 0, 8, 8));
            };
            @weakify(self);
            [[closeButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
                @strongify(self);
                self.done();
            }];
        }
    }
    
    [self updateConstraintsForOrientation];
}

- (void)viewWillAppear:(BOOL)animated {
    // Dispatch so that the view has a size :(
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateConstraintsForOrientation];
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        [self.horizontalScrollView setContentOffset:CGPointMake(self.horizontalScrollView.contentSize.width - self.horizontalScrollView.bounds.size.width, 0) animated:NO];
        [self handlePinch:nil];
    });
}

- (void)selectedState:(State *)state {
    NSLog(@"%@", state);
}

@end
