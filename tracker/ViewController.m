//
//  ViewController.m
//  tracker
//
//  Created by Griffin on 6/8/16.
//  Copyright © 2016 griff.zone. All rights reserved.
//

#import "ViewController.h"
#import <DRYUI/DRYUI.h>

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface ViewController ()

@property (nonatomic, strong) NSMutableDictionary *data;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation ViewController


- (void)loadView {
    self.view = [UIView new];
    
    self.data = @{@"asdf":@"sdf"};
    [self saveToFile];
    [self readFromFile];
    
    build_subviews(self.view) {
        
    };
}

- (void)saveToFile {
    NSData *nsData = [NSJSONSerialization dataWithJSONObject:self.data options:NSJSONWritingPrettyPrinted error:nil];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"DATAR.json"];
    [nsData writeToFile:appFile atomically:YES];
}

- (void)readFromFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    [NSData dataWithContentsOfFile:[documentsDirectory stringByAppendingPathComponent:@"DATAR.json"]];
    
    self.data =
    [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[documentsDirectory stringByAppendingPathComponent:@"DATAR.json"]]
                                    options:NSJSONReadingMutableLeaves
                                      error:nil];
    
}

@end
