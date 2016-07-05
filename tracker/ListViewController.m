//
//  ListViewController.m
//  tracker
//
//  Created by Griffin on 7/4/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "ListViewController.h"
#import <DRYUI/DRYUI.h>
#import <ChameleonFramework/Chameleon.h>

#import "Event.h"
#import "EventViewController.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface ListViewController () <
UITableViewDelegate,
UITableViewDataSource
>

@property (nonatomic, strong) Schema *schema;
@property (nonatomic, strong) Data *data;
@property (nonatomic, strong) ListViewControllerDoneBlock done;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) UITableView *tableView;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation ListViewController

- (instancetype)initWithSchema:(Schema *)schema andData:(Data *)data done:(ListViewControllerDoneBlock)done {
    if ((self = [super init])) {
        self.schema = schema;
        self.data = data;
        self.done = done;
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [self.dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return self;
}

- (void)loadView {
    self.view = [UIView new];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]  initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    
    build_subviews(self.view) {
        add_subview(self.tableView) {
            _.delegate = self;
            _.dataSource = self;
            _.backgroundColor = FlatNavyBlueDark;
            _.make.edges.equalTo(superview);
        };
    };
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.tableView reloadData];
}

#pragma mark - Helper Functions

- (NSUInteger)eventIndexForRow:(NSUInteger)row {
    return self.data.events.count - row - 1;
}

- (Event *)eventForRow:(NSUInteger)row {
    return self.data.events[[self eventIndexForRow:row]];
}

#pragma mark - UI Responding

- (void)doneButtonPressed:(id)sender {
    self.done();
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data.events.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    cell.backgroundColor = FlatNavyBlueDark;
    cell.textLabel.textColor = FlatWhiteDark;
    cell.textLabel.highlightedTextColor = FlatNavyBlue;
    cell.detailTextLabel.textColor = FlatGray;
    cell.detailTextLabel.highlightedTextColor = FlatNavyBlue;
    
    Event *e = [self eventForRow:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", EventType_toString(e.type), e.name];
    cell.detailTextLabel.text = [self.dateFormatter stringFromDate:e.date];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Event *event = [self eventForRow:indexPath.row];
    NSUInteger eventIndex = [self eventIndexForRow:indexPath.row];
    [self.navigationController pushViewController:[[EventViewController alloc] initWithData:self.data andEvent:event done:^(Event *editedEvent) {
        if (![[editedEvent toDictionary] isEqual:[event toDictionary]]) {
            [self.data.events replaceObjectAtIndex:eventIndex withObject:editedEvent];
            [self.data sortEvents];
        }
        [self.navigationController popViewControllerAnimated:YES];
    }] animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.data.events removeObjectAtIndex:[self eventIndexForRow:indexPath.row]];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
    }
}

@end
