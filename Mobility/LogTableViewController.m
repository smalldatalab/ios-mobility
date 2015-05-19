//
//  LogTableViewController.m
//  Mobility
//
//  Created by Charles Forkish on 1/7/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import "LogTableViewController.h"

@interface LogTableViewController ()

@end

@implementation LogTableViewController


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = @"Log";
    }
    return self;
}

- (void)loadTable
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (self.fetchedResultsController == nil) {
        self.fetchedResultsController = [[MobilityModel sharedModel] fetchedLogEntriesController];
        self.fetchedResultsController.delegate = self;
    }
    
//    [self.tableView reloadData];
    
    [self reloadData];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * sCellIdentifier = @"logCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:sCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:sCellIdentifier];
    }
    
    DebugLogEntry *logEntry = self.fetchedResultsController.fetchedObjects[indexPath.row];
    cell.textLabel.text = logEntry.text;
    cell.detailTextLabel.text = [logEntry.timestamp formattedDate];
    
    return cell;
}


@end
