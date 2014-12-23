//
//  MobilityViewController.m
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "MobilityViewController.h"
#import "ActivityLogger.h"

@interface MobilityViewController ()

@property (nonatomic, strong) ActivityLogger *logger;

@end

@implementation MobilityViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Mobility";
    
    self.logger = [ActivityLogger sharedLogger];
    
    __weak typeof(self) weakSelf = self;
    self.logger.newDataPointBlock = ^(MobilityDataPoint *dataPoint) {
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
    return self.logger.dataPoints.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"mobilityCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    MobilityDataPoint *dataPoint = self.logger.dataPoints[indexPath.row];
    if (dataPoint.body.activities.count == 0) {
        NSLog(@"no activities in data point: %@", dataPoint);
    }
    
    cell.textLabel.text = dataPoint.body.debugActivityString;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, confidence: %@", [self formattedDate:dataPoint.header.creationDateTime], dataPoint.body.debugActivityConfidence];
    
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
