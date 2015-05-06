//
//  PedometerTableViewController.m
//  Mobility
//
//  Created by Charles Forkish on 4/8/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import "PedometerTableViewController.h"

@interface PedometerTableViewController ()

@end

@implementation PedometerTableViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = @"Pedometer";
    }
    return self;
}

- (void)loadTable
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (self.fetchedResultsController == nil) {
        self.fetchedResultsController = [[MobilityModel sharedModel] fetchedPedometerDataController];
        self.fetchedResultsController.delegate = self;
    }
    
    [self.tableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"pedometerCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    MobilityPedometerData *dp = self.fetchedResultsController.fetchedObjects[indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ steps", dp.stepCount];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", [dp.startDate formattedDate], [dp.endDate formattedDate]];
    
    return cell;
}

@end
