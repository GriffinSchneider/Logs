//
//  TimelineColumnView.m
//  tracker
//
//  Created by Griffin Schneider on 7/29/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "TimelineColumnView.h"
#import <DRYUI/DRYUI.h>
#import "ChameleonMacros.h"
#import "UIButton+ANDYHighlighted.h"
#import "State.h"
#import "Data.h"
#import "SyncManager.h"
#import "Utils.h"


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
@interface TimelineColumnView ()

@property (nonatomic, strong) NSArray<EEvent *> *events;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TimelineColumnView

- (instancetype)initWithEvents:(NSArray<EEvent *> *)events startTime:(NSDate *)startTime endTime:(NSDate *)endTime {
    if ((self = [super init])) {
        self.events = events;
        self.startTime = startTime;
        self.endTime = endTime;
        [self buildSubviews];
    }
    return self;
}
- (void)buildSubviews {
    NSArray<NSArray<StateSlotInfo *> *> *slots = [self fullSlotInfo];
    build_subviews(self) {
        _.backgroundColor = FlatNavyBlueDark;
        [slots enumerateObjectsUsingBlock:^(NSArray<StateSlotInfo *> *slotArray, NSUInteger slot, BOOL *stop) {
            [slotArray enumerateObjectsUsingBlock:^(StateSlotInfo *s, NSUInteger idx, BOOL * _Nonnull stop) {
                UIButton *add_subview(v) {
                    _.backgroundColor = colorForState(s.state.name);
                    _.highlightedBackgroundColor = [_.backgroundColor darkenByPercentage:0.3];
                    _.layer.borderColor = [_.backgroundColor darkenByPercentage:0.1].CGColor;
                    _.clipsToBounds = NO;
                    _.imageView.contentMode = UIViewContentModeScaleAspectFit;
                    [_ setImage: iconForState(s.state.name) forState:UIControlStateNormal];
                    
                    if ([s.state.start compare:self.startTime] == NSOrderedAscending) {
                        _.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
                    } else if ([s.state.end compare:self.endTime] == NSOrderedDescending) {
                        _.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
                    } else {
                        _.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                    }
                    
                    if (s.slotIndex == 0) {
                        make.leading.equalTo(@0);
                    } else {
                        make.leading.equalTo(superview.mas_trailing).multipliedBy((CGFloat)s.slotIndex/s.numberOfActiveSlots);
                    }
                    make.width.equalTo(superview).multipliedBy(1.0/s.numberOfActiveSlots);
                    make.height.equalTo(superview).multipliedBy([self scale:[s.state.end ?: [NSDate date] timeIntervalSinceDate:s.state.start]]);
                    make.top.equalTo(superview.mas_bottom).multipliedBy([self scale:[s.state.start timeIntervalSinceDate:self.startTime]]);
                }
//                @weakify(self);
//                v.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
//                    @strongify(self);
//                    [self selectedState:s.state];
//                    return nil;
//                }];
            }];
        }];
    }
}


- (NSSet<StateSlotInfo *> *)statesOverlappingState:(State *)s inSlot:(NSUInteger)slot ofSlots:(NSArray<NSArray<StateSlotInfo *> *> *)slots {
    // TODO?: Add an early exit by reverse-enumerating here if this is too slow
    if (slots.count <= slot) return nil;
    NSMutableSet<StateSlotInfo *> *retVal = [NSMutableSet new];
    [slots[slot] enumerateObjectsUsingBlock:^(StateSlotInfo *slotInfo, NSUInteger idx, BOOL *stop) {
        if (doStatesOverlap(s, slotInfo.state)) {
            [retVal addObject:slotInfo];
        }
    }];
    return retVal;
}

- (void)putState:(State *)s inSlot:(NSUInteger)slot ofSlots:(NSMutableArray<NSMutableArray<StateSlotInfo *> *> *)slots {
    StateSlotInfo *slotInfo = [StateSlotInfo new];
    slotInfo.state = s;
    slotInfo.slotIndex = slot;
    slotInfo.numberOfActiveSlots = 3; // TODO: this.
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
    NSArray<State *> *states = statesFromEvents(self.events);
    NSMutableArray<NSMutableArray<StateSlotInfo *> *> *retVal = [NSMutableArray new];
    [states enumerateObjectsUsingBlock:^(State *s, NSUInteger idx, BOOL *stop) {
        [self insertState:s intoSlots:retVal];
    }];
    return retVal;
}

- (CGFloat)scale:(NSTimeInterval)interval {
    CGFloat retVal = (CGFloat)interval/[self.endTime timeIntervalSinceDate:self.startTime];
    if (retVal == 0.0) retVal = 0.000001;
    return retVal;
}

- (void)selectedState:(State *)state {
    NSLog(@"%@", state);
}


@end
