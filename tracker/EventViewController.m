//
//  EventViewController.m
//  tracker
//
//  Created by Griffin on 7/4/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "EventViewController.h"
#import <DRYUI/DRYUI.h>
#import <MoveViewUpForKeyboardKit/MVUFKView.h>
#import "ChameleonMacros.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface EventViewController()

@property (nonatomic, strong) Data *data;
@property (nonatomic, strong) EEvent *originalEvent;
@property (nonatomic, strong) EEvent *editingEvent;
@property (nonatomic, strong) EventViewControllerDoneBlock done;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) UITextField *dateTextField;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation EventViewController

- (instancetype)initWithData:(Data *)data andEvent:(EEvent *)event done:(EventViewControllerDoneBlock)done {
    if (([super init])) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.data = data;
        self.originalEvent = event;
        self.editingEvent = [event copy];
        self.done = done;
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [self.dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return self;
}

- (void)loadView {
    self.view = [UIView new];
    self.view.backgroundColor = FlatNavyBlueDark;
    build_subviews(self.view) {
        MVUFKView *add_subview(keyboardView){};
        add_subview(self.dateTextField) {
            _.text = [self.dateFormatter stringFromDate:self.editingEvent.date];
            _.textColor = FlatWhiteDark;
            _.backgroundColor = FlatNavyBlue;
            
            UIDatePicker *pickerView = [UIDatePicker new];
            pickerView.date = self.editingEvent.date;
            _.inputView = pickerView;
            
            // create a done view + done button, attach to it a doneClicked action, and place it in a toolbar as an accessory input view...
            // Prepare done button
            UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] init];
            keyboardDoneButtonView.barStyle = UIBarStyleBlack;
            keyboardDoneButtonView.translucent = YES;
            keyboardDoneButtonView.tintColor = nil;
            [keyboardDoneButtonView sizeToFit];
            
            UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dateDoneButtonPressed:)];
            [keyboardDoneButtonView setItems:@[doneButton]];
             _.inputAccessoryView = keyboardDoneButtonView;
            
//            @weakify(self);
//            [[pickerView rac_signalForControlEvents:UIControlEventValueChanged] subscribeNext:^(id x) {
//                @strongify(self);
//                self.editingEvent.date = pickerView.date;
//                _.text = [self.dateFormatter stringFromDate:self.editingEvent.date];
//            }];
            
            make.left.and.right.equalTo(superview);
            make.bottom.equalTo(keyboardView.mas_top).with.offset(-10);
            make.height.equalTo(@50);
        };
        UITextField *add_subview(name) {
            _.text = self.editingEvent.name;
            _.backgroundColor = FlatNavyBlue;
            _.textColor = FlatWhiteDark;
            make.left.and.right.equalTo(superview);
            make.bottom.equalTo(self.dateTextField.mas_top).with.offset(-10);
            make.height.equalTo(@50);
//            [_.rac_textSignal subscribeNext:^(id x) {
//                self.editingEvent.name = _.text;
//            }];
        };
    };
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
}

- (void)viewDidAppear:(BOOL)animated {
    [self.dateTextField becomeFirstResponder];
}

- (void)dateDoneButtonPressed:(id)sender {
    [self.view endEditing:YES];
}

- (void)doneButtonPressed:(id)sender {
    self.done(self.editingEvent);
}

- (void)cancelButtonPressed:(id)sender {
    self.done(self.originalEvent);
}

@end
