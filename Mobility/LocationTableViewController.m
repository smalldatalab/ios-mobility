//
//  LocationTableViewController.m
//  Mobility
//
//  Created by Charles Forkish on 12/23/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "LocationTableViewController.h"
#import "ActivityLogger.h"

@interface LocationTableViewController ()

@property (nonatomic, strong) ActivityLogger *logger;

@end

@implementation LocationTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Locations";
    
    self.logger = [ActivityLogger sharedLogger];
    
    __weak typeof(self) weakSelf = self;
    self.logger.newLocationDataPointBlock = ^(MobilityDataPoint *dataPoint) {
        //        NSLog(@"new log entry: %@", dataPoint);
        //        [weakSelf.tableView reloadData];
        [weakSelf insertRowForDataPoint:dataPoint];
    };
}

- (void)insertRowForDataPoint:(MobilityDataPoint *)dataPoint
{
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                          withRowAnimation:UITableViewRowAnimationTop];
    [self.tableView endUpdates];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.logger.locationDataPoints.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"mobilityCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    MobilityDataPoint *dataPoint = self.logger.locationDataPoints[indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@m)", [self formattedDate:dataPoint.header.creationDateTime], dataPoint.body.location.horizontalAccuracy];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"lat: %@, long: %@", dataPoint.body.location.latitude, dataPoint.body.location.longitude];
    
    return cell;
}

- (NSString *)formattedDate:(NSDate *)date
{
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"MMMM d h:m:s" options:0
                                                                  locale:[NSLocale currentLocale]];
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:formatString];
    }
    
    return [dateFormatter stringFromDate:date];
}

@end
