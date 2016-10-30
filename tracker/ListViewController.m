//
//  ListViewController.m
//  tracker
//
//  Created by Griffin on 7/4/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "ListViewController.h"
#import <DRYUI/DRYUI.h>
#import "ChameleonMacros.h"

#import "EEvent.h"
#import "EventViewController.h"
#import "SyncManager.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface ListViewController () <
UITableViewDelegate,
UITableViewDataSource
>

@property (nonatomic, strong) ListViewControllerDoneBlock done;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) UITableView *tableView;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation ListViewController

- (instancetype)initWithDone:(ListViewControllerDoneBlock)done {
    if ((self = [super init])) {
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
            make.edges.equalTo(superview);
        };
    };
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.tableView reloadData];
}

#pragma mark - Helper Functions

- (NSUInteger)eventIndexForRow:(NSUInteger)row {
    return [SyncManager i].data.events.count - row - 1;
}

- (EEvent *)eventForRow:(NSUInteger)row {
    return [SyncManager i].data.events[[self eventIndexForRow:row]];
}

#pragma mark - UI Responding

- (void)doneButtonPressed:(id)sender {
    self.done();
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [SyncManager i].data.events.count;
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
    
    EEvent *e = [self eventForRow:indexPath.row];
    
    NSString *icon = [[SyncManager i].schema schemaForStateNamed:e.name].icon;
    icon = icon ? [NSString stringWithFormat:@"%@ ", icon] : @"";
    cell.textLabel.text = [NSString stringWithFormat:@"%@%@: %@", icon, EventType_toString(e.type), e.name];
    cell.detailTextLabel.text = [self.dateFormatter stringFromDate:e.date];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    EEvent *event = [self eventForRow:indexPath.row];
    [self.navigationController pushViewController:[[EventViewController alloc] initWithData:[SyncManager i].data andEvent:event done:^(EEvent *editedEvent) {
        if (![[editedEvent toDictionary] isEqual:[event toDictionary]]) {
            [[SyncManager i].data replaceEvent:event withEvent:editedEvent];
            [[SyncManager i].data sortEvents];
            [[SyncManager i] writeToDisk];
        }
        [self.navigationController popViewControllerAnimated:YES];
    }] animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[SyncManager i].data removeEvent:[self eventForRow:indexPath.row]];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
        [[SyncManager i] writeToDisk];
    }
}

@end
