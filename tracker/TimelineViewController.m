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


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface StateSlotInfo : NSObject
@property (nonatomic, assign) NSUInteger slotIndex;
@property (nonatomic, assign) NSUInteger numberOfActiveSlots;
@property (nonatomic, strong) State *state;
@end
@implementation StateSlotInfo
- (NSString *)description {
    return [NSString stringWithFormat:@"<StateSlotInfo idx:%lu #:%lu %@>", (unsigned long)self.slotIndex, (unsigned long)self.numberOfActiveSlots, self.state];
}
@end



////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TimelineViewController ()

@property (nonatomic, strong) TimelineViewControllerDoneBlock done;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TimelineViewController

static NSArray<UIColor *> *colors;
+ (void)load {
    colors = @[FlatBlueDark, FlatRedDark, FlatGreenDark, FlatBlueDark,
             FlatMagentaDark,
               FlatOrangeDark, FlatPinkDark, FlatPurpleDark, FlatRedDark,
               FlatSkyBlueDark, FlatWatermelonDark, FlatYellowDark];
    colorMap = [NSMutableDictionary new];
}

static NSUInteger colorIndex = 0;
static NSMutableDictionary<NSString *, UIColor *> *colorMap;
- (UIColor *)getColor:(NSString *)key {
    UIColor *retVal = colorMap[key];
    if (!retVal) {
        colorIndex = (colorIndex + 1) % colors.count;
        retVal = colors[colorIndex];
        colorMap[key] = retVal;
    }
    return retVal;
}

- (instancetype)initWithDone:(TimelineViewControllerDoneBlock)done {
    if ((self = [super init])) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.done = done;
    }
    return self;
}

- (BOOL)doesState:(State *)s1 overlapWithState:(State *)s2 {
    return [s1.start compare:s2.end] != NSOrderedDescending && [s2.start compare:s1.end] != NSOrderedDescending;
}

- (NSSet<StateSlotInfo *> *)statesOverlappingState:(State *)s inSlot:(NSUInteger)slot ofSlots:(NSArray<NSArray<StateSlotInfo *> *> *)slots {
    // TODO?: Add an early exit by reverse-enumerating here if this is too slow
    if (slots.count <= slot) return nil;
    NSMutableSet<StateSlotInfo *> *retVal = [NSMutableSet new];
    [slots[slot] enumerateObjectsUsingBlock:^(StateSlotInfo *slotInfo, NSUInteger idx, BOOL *stop) {
        if ([self doesState:s overlapWithState:slotInfo.state]) {
            [retVal addObject:slotInfo];
        }
    }];
    return retVal;
}

- (void)putState:(State *)s inSlot:(NSUInteger)slot ofSlots:(NSMutableArray<NSMutableArray<StateSlotInfo *> *> *)slots {
    StateSlotInfo *slotInfo = [StateSlotInfo new];
    slotInfo.state = s;
    slotInfo.slotIndex = slot;
    slotInfo.numberOfActiveSlots = 4; // TODO: this.
    if (slots.count <= slot) {
        [slots addObject:[NSMutableArray new]];
    }
    NSMutableArray<StateSlotInfo *> *slotArray = slots[slot];
    [slotArray addObject:slotInfo];
}

- (BOOL)canState:(State *)s fitInSlot:(NSUInteger)slot ofSlots:(NSArray<NSArray<StateSlotInfo *> *> *)slots {
    if (slots.count <= slot) return YES;
    return [self statesOverlappingState:s inSlot:slot ofSlots:slots].count == 0;
}

- (void)insertState:(State *)s intoSlots:(NSMutableArray<NSMutableArray<StateSlotInfo *> *> *)slots {
    NSUInteger candidateSlot = 0;
    while (true) {
        if ([self canState:s fitInSlot:candidateSlot ofSlots:slots]) {
            [self putState:s inSlot:candidateSlot ofSlots:slots];
            break;
        }
        candidateSlot++;
    }
}

- (NSArray<NSArray<StateSlotInfo *> *> *)fullSlotInfo {
    NSArray<State *> *states = [SyncManager i].data.allStates;
    NSMutableArray<NSMutableArray<StateSlotInfo *> *> *retVal = [NSMutableArray new];
    [states enumerateObjectsUsingBlock:^(State *s, NSUInteger idx, BOOL *stop) {
        [self insertState:s intoSlots:retVal];
    }];
    return retVal;
}

- (CGFloat)scale:(NSTimeInterval)interval {
    return roundf(interval/40.0);
}

- (void)loadView {
    NSArray<NSArray<StateSlotInfo *> *> *slots = [self fullSlotInfo];
    NSDate *start = slots[0][0].state.start;
    
    self.view = [UIView new];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]  initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    
    build_subviews(self.view) {
        _.backgroundColor = FlatNavyBlue;
        UIScrollView *add_subview(scrollView) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CGPoint bottomOffset = CGPointMake(0, _.contentSize.height - _.bounds.size.height);
                [_ setContentOffset:bottomOffset animated:NO];
            });
            _.make.edges.equalTo(superview);
            [slots enumerateObjectsUsingBlock:^(NSArray<StateSlotInfo *> *slotArray, NSUInteger slot, BOOL *stop) {
                [slotArray enumerateObjectsUsingBlock:^(StateSlotInfo *s, NSUInteger idx, BOOL * _Nonnull stop) {
                    UIButton *add_subview(v) {
                        [_ setTitle:[NSString stringWithFormat:@"%@ %@", s.state.name, formatDuration([(s.state.end ?: [NSDate date]) timeIntervalSinceDate:s.state.start])] forState:UIControlStateNormal];
                        [_ setTitleColor:FlatWhiteDark forState:UIControlStateNormal];
                        _.backgroundColor = [self getColor:s.state.name];
                        _.highlightedBackgroundColor = [_.backgroundColor darkenByPercentage:0.3];
                        _.layer.borderColor = [_.backgroundColor darkenByPercentage:0.1].CGColor;
                        _.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBlack];
                        _.titleLabel.numberOfLines = 0;
                        _.titleLabel.adjustsFontSizeToFitWidth = YES;
                        _.titleLabel.minimumScaleFactor = 0;
                        _.titleLabel.lineBreakMode = NSLineBreakByClipping;
                        CGFloat w = [UIScreen mainScreen].bounds.size.width;
                        _.make.left.equalTo(superview.superview).with.offset((w/s.numberOfActiveSlots)*s.slotIndex);
                        _.make.width.equalTo(@((w/s.numberOfActiveSlots)));
                        if (s.state.end) {
                            _.make.height.equalTo(@([self scale:[s.state.end timeIntervalSinceDate:s.state.start]]));
                        } else {
                            _.make.bottom.equalTo(superview);
                        }
                        if (idx == 0) {
                            _.make.top.equalTo(superview);
                        } else {
                            _.make.top.equalTo(@([self scale:[s.state.start timeIntervalSinceDate:start]]));
                        }
                    };
                    [v bk_addEventHandler:^(id sender) {
                        [self selectedState:s.state];
                    } forControlEvents:UIControlEventTouchUpInside];
                    
                }];
            }];
            UIView *add_subview(nowSpacer) {
                _.make.top.equalTo(@([self scale:[[NSDate date] timeIntervalSinceDate:start]]));
                _.make.height.equalTo(@0);
                _.make.bottom.equalTo(superview);
            };
        }
    }
}

- (void)selectedState:(State *)state {
    NSLog(@"%@", state);
}

- (void)doneButtonPressed:(id)sender {
    self.done();
}

@end
