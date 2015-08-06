//
//  ActivityTableViewController.m
//  Mobility
//
//  Created by Charles Forkish on 5/5/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import "ActivityTableViewController.h"

@interface ActivityTableViewController ()

@property (nonatomic, assign) BOOL isActivityAvailable;

@end

@implementation ActivityTableViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = @"Activities";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isActivityAvailable = [CMMotionActivityManager isActivityAvailable];
}

- (void)loadTable
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (!self.isActivityAvailable) return;
    
    if (self.fetchedResultsController == nil) {
        self.fetchedResultsController = [[MobilityModel sharedModel] fetchedActivitesController];
        self.fetchedResultsController.delegate = self;
    }
    
    [self reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[MobilityModel sharedModel] logMessage:@"Memory Warning"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.isActivityAvailable) return 1;
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.isActivityAvailable) {
        return [self noActivityCell];
    }
    
    static NSString *cellIdentifier = @"activityCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    MobilityActivity *activity = self.fetchedResultsController.fetchedObjects[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (confidence: %@)", activity.debugActivityString, activity.confidenceString];
    cell.detailTextLabel.text = [activity.timestamp formattedDate];
    
//    cell.detailTextLabel.text = [NSString stringWithFormat:@"%f", activity.timestamp.timeIntervalSince1970];
    cell.accessoryType = activity.uploaded ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (UITableViewCell *)noActivityCell
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.text = @"Activity tracking not supported";
    return cell;
}

@end
