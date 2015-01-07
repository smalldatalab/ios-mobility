//
//  LogTableViewController.m
//  Mobility
//
//  Created by Charles Forkish on 1/7/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import "LogTableViewController.h"
#import "ActivityLogger.h"

@interface LogTableViewController ()

@end

@implementation LogTableViewController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.title = @"Log";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [ActivityLogger sharedLogger].newLogEntryBlock = ^(NSDictionary *logEntry) {
        [self addLogEntry];
    };
}

- (void)addLogEntry
{
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [ActivityLogger sharedLogger].logEntries.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * sCellIdentifier = @"logCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:sCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:sCellIdentifier];
    }
    NSDictionary *logEntry = [ActivityLogger sharedLogger].logEntries[indexPath.row];
    cell.textLabel.text = logEntry[@"message"];
    cell.detailTextLabel.text = logEntry[@"time"];
    
    return cell;
}


@end
