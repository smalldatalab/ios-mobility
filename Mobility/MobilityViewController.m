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
        [weakSelf.tableView reloadData];
    };
    
    UIBarButtonItem *startButton = [[UIBarButtonItem alloc] initWithTitle:@"Start" style:UIBarButtonItemStylePlain target:self.logger action:@selector(startLogging)];
    self.navigationItem.rightBarButtonItem = startButton;
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
    
    NSArray *activities = dataPoint.body.activities;
    NSMutableString *text = [NSMutableString string];
    MobilityActivity *activity;
    for (int i = 0; i < activities.count; i++) {
        if (i > 0) [text appendString:@", "];
        activity = activities[i];
        [text appendString:activity.activity];
    }
    if (activity == nil) {
        NSLog(@"nil activity for data point: %@", dataPoint);
    }
    cell.textLabel.text = text;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, confidence: %@", dataPoint.header.creationDateTime, activity.confidence];
    
    return cell;
}

@end
