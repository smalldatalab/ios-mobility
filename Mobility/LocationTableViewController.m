//
//  LocationTableViewController.m
//  Mobility
//
//  Created by Charles Forkish on 12/23/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "LocationTableViewController.h"
#import "MobilityModel.h"

@interface LocationTableViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation LocationTableViewController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.title = @"Locations";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fetchedResultsController = [[MobilityModel sharedModel] fetchedLocationsController];
    self.fetchedResultsController.delegate = self;
    
//    UIBarButtonItem *refetch = [[UIBarButtonItem alloc] initWithTitle:@"Fetch" style:UIBarButtonItemStylePlain target:self action:@selector(fetch)];
//    self.navigationItem.rightBarButtonItem = refetch;
//
//    self.logger = [ActivityLogger sharedLogger];
//    
//    __weak typeof(self) weakSelf = self;
//    self.logger.newLocationDataPointBlock = ^(MobilityDataPoint *dataPoint) {
//        //        NSLog(@"new log entry: %@", dataPoint);
//        //        [weakSelf.tableView reloadData];
//        [weakSelf insertRowForDataPoint:dataPoint];
//    };
}

//- (void)insertRowForDataPoint:(MobilityDataPoint *)dataPoint
//{
//    [self.tableView beginUpdates];
//    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
//                          withRowAnimation:UITableViewRowAnimationTop];
//    [self.tableView endUpdates];
//}

- (void)fetch
{
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    NSLog(@"performed fetch. error: %@, count: %d", error, (int)self.fetchedResultsController.fetchedObjects.count);
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self fetch];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.fetchedResultsController.fetchedObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"locationCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    MobilityLocation *location = self.fetchedResultsController.fetchedObjects[indexPath.row];
    if (location.timestamp == nil) {
        NSLog(@"nil location: %@", location);
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%f)", [self formattedDate:location.timestamp], location.horizontalAccuracy];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"lat: %f, long: %f, course: %f", location.latitude, location.longitude, location.bearing];
    
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


#pragma mark - NSFetchedResultsController Delegate


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView reloadData];
}

@end
