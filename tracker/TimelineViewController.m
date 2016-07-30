//
//  TimelineViewController.m
//  tracker
//
//  Created by Griffin Schneider on 7/21/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "TimelineViewController.h"
#import <DRYUI/DRYUI.h>
#import <ChameleonFramework/Chameleon.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UIButton+ANDYHighlighted.h"

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

@property (nonatomic, assign) CGPoint lastPortraitHorizontalContentOffset;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TimelineViewController


- (instancetype)initWithDone:(TimelineViewControllerDoneBlock)done {
    if ((self = [super init])) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.done = done;
    }
    return self;
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
            [self.scrollViewWrapper mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.height.equalTo(self.view.mas_width);
                make.width.equalTo(self.view.mas_height);
                make.center.equalTo(self.view);
            }];
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [UIView setAnimationsEnabled:YES];
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:0.5 animations:^{
            [self updateConstraintsForOrientation];
            self.scrollViewWrapper.layer.affineTransform = CGAffineTransformIdentity;
            [self.view layoutIfNeeded];
            if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
                self.horizontalScrollView.contentOffset = self.lastPortraitHorizontalContentOffset;
            } else {
                self.lastPortraitHorizontalContentOffset = horizontalContentOffset;
            }
        }];
    }];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)updateConstraintsForOrientation {
    BOOL isPortrait = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
    
    [self.scrollViewWrapper mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view);
        make.height.equalTo(self.view);
        make.center.equalTo(self.view);
    }];
    
    self.horizontalScrollView.bounces = NO;
    [self.horizontalScrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.and.right.equalTo(self.horizontalScrollView.superview);
        make.width.equalTo(self.horizontalScrollView.superview.superview);
        make.bottom.equalTo(self.horizontalScrollView.superview);
        [self.columns enumerateObjectsUsingBlock:^(TimelineColumnView *column, NSUInteger idx, BOOL *stop) {
            make.height.greaterThanOrEqualTo(column);
        }];
    }];
    
    __block TimelineColumnView *lastColumn;
    [self.columns enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TimelineColumnView *column, NSUInteger idx, BOOL *stop) {
        [column mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(column.superview);
            make.bottom.lessThanOrEqualTo(column.superview);
            make.left.equalTo(lastColumn.mas_right ?: column.superview);
            make.width.equalTo(column.superview.superview.superview).multipliedBy(isPortrait ? 1 : 1.0/self.columns.count);
            make.right.lessThanOrEqualTo(column.superview);
        }];
        lastColumn = column;
    }];
}

- (void)createColumns {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps = [NSDateComponents new];
    NSDate *dateIdx = [NSDate date];
    NSDate *minDate = [NSDate date];
    NSMutableArray<NSArray<Event *> *> *eventsByDay = [NSMutableArray new];
    for (int i = 0; i < 7; i++) {
        NSArray<Event *> *events = [[SyncManager i].data eventsForDay:dateIdx];
        [eventsByDay addObject:events];
        if (!events.count) continue;
        comps.day = i;
        NSDate *scaledStartDate = [cal dateByAddingComponents:comps toDate:events[0].date options:0];
        if ([scaledStartDate compare:minDate] == NSOrderedAscending) {
            minDate = scaledStartDate;
        }
        comps.day = -1;
        dateIdx = [cal dateByAddingComponents:comps toDate:dateIdx options:0];
    }
    
    NSMutableArray<TimelineColumnView *> *columns = [NSMutableArray new];
    for (int i = 0; i < 7; i++) {
        NSArray<Event *> *day = eventsByDay[i];
        comps.day = -i;
        NSDate *scaledMinDate = [cal dateByAddingComponents:comps toDate:minDate options:0];
        [columns addObject:[[TimelineColumnView alloc] initWithEvents:day startTime:scaledMinDate]];
    }
    
    self.columns = columns;
}


- (void)loadView {
    self.view = [UIView new];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]  initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    
    [self createColumns];
    
    build_subviews(self.view) {
        _.backgroundColor = FlatNavyBlueDark;
        add_subview(self.scrollViewWrapper) {
            _.clipsToBounds = NO;
            add_subview(self.verticalScrollView) {
                _.clipsToBounds = NO;
                _.make.width.height.left.and.top.equalTo(superview);
                add_subview(self.horizontalScrollView) {
                    _.clipsToBounds = NO;
                    _.pagingEnabled = YES;
                    _.showsHorizontalScrollIndicator = NO;
                    for (__strong TimelineColumnView *col in self.columns) { add_subview(col){}; }
                };
            };
        }
    }
    
    [self updateConstraintsForOrientation];
}

- (void)viewWillAppear:(BOOL)animated {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.horizontalScrollView setContentOffset:CGPointMake(self.horizontalScrollView.contentSize.width - self.horizontalScrollView.bounds.size.width, 0) animated:NO];
    });
}

- (void)selectedState:(State *)state {
    NSLog(@"%@", state);
}

- (void)doneButtonPressed:(id)sender {
    self.done();
}

@end
