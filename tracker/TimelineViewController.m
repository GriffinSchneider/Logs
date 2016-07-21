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
#import "SyncManager.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface StateSlotInfo : NSObject
@property (nonatomic, assign) NSUInteger slotIndex;
@property (nonatomic, assign) NSUInteger numberOfActiveSlots;
@property (nonatomic, strong) State *state;
@end
@implementation StateSlotInfo
- (NSString *)description {
    return [NSString stringWithFormat:@"<StateSlotInfo idx:%u #:%u %@>", self.slotIndex, self.numberOfActiveSlots, self.state];
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
    colors = @[FlatBlue, FlatCoffee, FlatForestGreen, FlatGreen,
               FlatLime, FlatMagenta, FlatMaroon, FlatMint,
               FlatNavyBlue, FlatOrange, FlatPink, FlatPurple,
               FlatRed, FlatSkyBlue, FlatWatermelon, FlatYellow];
}

static NSUInteger colorIndex = 0;
- (UIColor *)getColor {
    colorIndex = (colorIndex + 1) % colors.count;
    return colors[colorIndex];
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

- (NSUInteger)getNumberOfOverlappingStatesAndUpdateNumberOfActiveSlotsForThoseStatesForState:(State *)s inSlots:(NSMutableArray<NSMutableArray<StateSlotInfo *> *> *)slots {
    // TODO: Actually figure out the numberOfActiveSlots.
    [slots enumerateObjectsUsingBlock:^(NSArray<StateSlotInfo *> *slotArray, NSUInteger slot, BOOL *stop) {
        [slotArray enumerateObjectsUsingBlock:^(StateSlotInfo *s, NSUInteger idx, BOOL * _Nonnull stop) {
            s.numberOfActiveSlots = 4;
        }];
    }];
    return 4;
}

- (void)putState:(State *)s inSlot:(NSUInteger)slot ofSlots:(NSMutableArray<NSMutableArray<StateSlotInfo *> *> *)slots {
    StateSlotInfo *slotInfo = [StateSlotInfo new];
    slotInfo.state = s;
    slotInfo.slotIndex = slot;
    // +1 because of this state.
    slotInfo.numberOfActiveSlots = [self getNumberOfOverlappingStatesAndUpdateNumberOfActiveSlotsForThoseStatesForState:s inSlots:slots] + 1;
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
    NSLog(@"%@", states);
    NSMutableArray<NSMutableArray<StateSlotInfo *> *> *retVal = [NSMutableArray new];
    [states enumerateObjectsUsingBlock:^(State *s, NSUInteger idx, BOOL *stop) {
        [self insertState:s intoSlots:retVal];
    }];
    return retVal;
}

- (CGFloat)scale:(NSTimeInterval)interval {
//    return interval/120.0;
    return interval/10.0;
}

- (void)loadView {
    NSArray<NSArray<StateSlotInfo *> *> *slots = [self fullSlotInfo];
    NSDate *start = slots[0][0].state.start;
    
    NSLog(@"%@", slots);
    
    self.view = [UIView new];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]  initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    
    build_subviews(self.view) {
        _.backgroundColor = [UIColor whiteColor];
        UIScrollView *add_subview(scrollView) {
            _.make.edges.equalTo(superview);
            [slots enumerateObjectsUsingBlock:^(NSArray<StateSlotInfo *> *slotArray, NSUInteger slot, BOOL *stop) {
                [slotArray enumerateObjectsUsingBlock:^(StateSlotInfo *s, NSUInteger idx, BOOL * _Nonnull stop) {
                    UIView *add_subview(v) {
                        _.backgroundColor = [self getColor];
                        _.layer.borderWidth = 4.0;
                        CGFloat w = [UIScreen mainScreen].bounds.size.width;
                        _.make.left.equalTo(superview.superview).with.offset((w/s.numberOfActiveSlots-4)*s.slotIndex);
                        _.make.width.equalTo(@((w/s.numberOfActiveSlots)));
                        _.make.height.equalTo(@([self scale:[s.state.end timeIntervalSinceDate:s.state.start]]));
                        if (idx == 0) {
                            _.make.top.equalTo(superview);
                        } else {
                            _.make.top.equalTo(@([self scale:[s.state.start timeIntervalSinceDate:start]]));
                        }
                    }
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

- (void)doneButtonPressed:(id)sender {
    self.done();
}

@end
