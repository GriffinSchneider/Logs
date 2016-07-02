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

#define PRETTY_PRINT(x) \
([[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[(x) toDictionary] \
                                                                options:NSJSONWritingPrettyPrinted \
                                                                  error:nil] \
                       encoding:NSUTF8StringEncoding]) \

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface ViewController () <DBRestClientDelegate>

@property (nonatomic, strong) Schema *schema;
@property (nonatomic, strong) Data *data;

@property (nonatomic, strong) DBRestClient* restClient;
@property (nonatomic, strong) NSString *currentlyLoadingFile;
@property (nonatomic, strong) NSString *fileRev;

@property (nonatomic, strong) NSMutableArray<UIButton *> *buttons;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation ViewController


- (instancetype)init {
    if ((self = [super init])) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        self.restClient.delegate = self;
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)loadView {
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view = [UIView new];
    self.buttons = [NSMutableArray array];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([[DBSession sharedSession] isLinked]) {
        [self refresh];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refresh)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:[UIApplication sharedApplication]];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refresh {
    [self readFromFile];
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
            button.highlightedBackgroundColor = [button.backgroundColor darkenByPercentage:0.2];
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
    
    __block UIScrollView *scrollView;
    build_subviews(self.view) {
        add_subview(scrollView) {
            _.make.edges.equalTo(superview);
        };
    };
    
    build_subviews(scrollView) {
        _.backgroundColor = FlatNavyBlueDark;
        __block UIView *add_subview(lastView) {
            _.make.top.equalTo(_.superview).with.offset(20);
        };
        lastView = [self buildGridWithLastView:lastView titles:self.schema.occurrences buttonBlock:^(UIButton *b, NSString *title) {
            if ([recentOccurrences containsObject:title]) {
                b.backgroundColor = FlatGreenDark;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    b.backgroundColor = FlatOrangeDark;
                });
            } else {
                b.backgroundColor = FlatOrangeDark;
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
                b.backgroundColor = FlatGreenDark;
            } else {
                b.backgroundColor = FlatRedDark;
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
                _.thumbTintColor = FlatGreenDark;
                _.minimumTrackTintColor = FlatGreenDark;
                _.maximumTrackTintColor = FlatRedDark;
                _.make.left.equalTo(superview).with.offset(10);
                _.make.top.equalTo(lastView.mas_bottom).with.offset(15);
                if (idx > 0) { _.make.width.equalTo(lastView); }
            };
            UIButton *add_subview(button) {
                [_ setTitleColor:FlatWhiteDark forState:UIControlStateNormal];
                _.layer.cornerRadius = 5;
                
                if ([[NSDate date] timeIntervalSinceDate:lastReadings[reading].date] < 1) {
                    _.backgroundColor = FlatGreenDark;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        _.backgroundColor = FlatBlueDark;
                        _.highlightedBackgroundColor = [_.backgroundColor darkenByPercentage:0.2];
                    });
                } else {
                    _.backgroundColor = FlatBlueDark;
                }
                _.highlightedBackgroundColor = [_.backgroundColor darkenByPercentage:0.2];
                
                _.make.top.and.bottom.equalTo(slider);
                _.make.right.equalTo(superview.superview).with.offset(-10);
                _.make.left.equalTo(slider.mas_right).with.offset(10);
            };
            [self sliderChanged:slider forReading:reading withButton:button];
            [button bk_addEventHandler:^(id _) { [self madeReading:reading withSlider:slider]; } forControlEvents:UIControlEventTouchUpInside];
            [slider bk_addEventHandler:^(id _) { [self sliderChanged:slider forReading:reading withButton:button]; } forControlEvents:UIControlEventAllEvents];
            lastView = slider;
        }];
        [lastView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(scrollView.mas_bottom).with.offset(-15);
        }];
    };
}

- (void)addEvent:(Event *)e {
    NSSet<NSString *> *activeStates = self.data.activeStates;
    // If we're in sleep state but an event is added, we must not be asleep anymore.
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
    NSLog(@"Writing data:\n%@", PRETTY_PRINT(self.data));
    NSData *nsData = [self.data toJSONData];
    [nsData writeToFile:self.localDataPath atomically:YES];
    [self.restClient uploadFile:@"data.json" toPath:@"/" withParentRev:self.fileRev fromPath:self.localDataPath];
}

- (void)makeSchemaFile {
    if (!self.schema) {
        self.schema = [Schema new];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.localSchemaPath]) {
        [[NSFileManager defaultManager] createFileAtPath:self.localSchemaPath contents:[self.schema toJSONData] attributes:nil];
    }
    [self.restClient uploadFile:@"schema.json" toPath:@"/" withParentRev:nil fromPath:self.localSchemaPath];
}

- (NSString *)localDataPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"data.json"];
}

- (NSString *)localSchemaPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"schema.json"];
}

- (void)readFromFile {
    [self.view makeToastActivity:CSToastPositionCenter];
    self.currentlyLoadingFile = self.localSchemaPath;
    [self.restClient loadFile:@"/schema.json" intoPath:self.localSchemaPath];
}

- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata {
    self.fileRev = metadata.rev;
    [self.restClient loadFile:metadata.path intoPath:self.localDataPath];
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error {
    [self restClient:nil loadedFile:self.localDataPath];
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)destPath {
    
    void (^block)(NSDictionary *dict);
    
    if ([destPath isEqual:self.localSchemaPath]) {
        self.currentlyLoadingFile = self.localDataPath;
        [self.restClient loadMetadata:@"/data.json"];
        block = ^(NSDictionary *dict) {
            self.schema = [[Schema alloc] initWithDictionary:dict error:nil];
            NSLog(@"Read schema:\n%@", PRETTY_PRINT(self.schema));
            [self.view makeToast:@"✅Loaded Schema✅"];
        };
    } else {
        block = ^(NSDictionary *dict) {
            if (dict) {
                self.data = [[Data alloc] initWithDictionary:dict error:nil];
            }
            if (!self.data) {
                self.data = [Data new];
                self.data.events = [NSMutableArray<Event> new];
            }
            NSLog(@"Read data:\n%@", PRETTY_PRINT(self.data));
            [self rebuildView];
            [self.view makeToast:@"✅Loaded Data✅"];
        };
    }
    NSData *data = [NSData dataWithContentsOfFile:destPath];
    NSDictionary *dict = nil;
    if (data) {
        dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    }
    block(dict);
    [self.view hideToastActivity];
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
    NSLog(@"LOAD FAILED WITH ERROR: %@", error);
    if (error.code == 401) {
        [self.view makeToast:@"Authentication Failure."];
        return;
    }
    if ([self.currentlyLoadingFile isEqualToString:self.localSchemaPath]) {
        [self.view makeToast:@"❌Loading Schema Failed!❌"];
        [self makeSchemaFile];
    } else {
        [self.view makeToast:@"❌Loading Data Failed!❌"];
        [self restClient:nil loadedFile:self.localDataPath];
        [self saveToFile];
    }
}


- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    self.fileRev = metadata.rev;
    if ([srcPath isEqualToString:self.localSchemaPath]) {
        [self.view makeToast:@"✅Created Schema File✅"];
        [self readFromFile];
    } else {
        [self.view makeToast:@"✅⏫✅"];
    }
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    if ([self.currentlyLoadingFile isEqualToString:self.localSchemaPath]) {
        [self.view makeToast:@"❌Failed to Create Schema File!❌"];
    } else {
        [self.view makeToast:@"❌Failed to Upload Data!❌"];
        
    }
}


@end
