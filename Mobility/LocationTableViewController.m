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
//        [self registerForNotifications];
    }
    return self;
}

//- (void)dealloc
//{
//    [self unregisterForNotifications];
//}
//
//- (void)registerForNotifications
//{
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enteredBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enteredForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
//}
//
//- (void)unregisterForNotifications
//{
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
//}
//
//- (void)enteredBackground
//{
//    NSLog(@"location table entered background");
//    self.fetchedResultsController.delegate = nil;
//}
//
//- (void)enteredForeground
//{
//    NSLog(@"location table entered foreground");
//    self.fetchedResultsController.delegate = self;
//    [self.fetchedResultsController performFetch:nil];
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fetchedResultsController = [[MobilityModel sharedModel] fetchedLocationsController];
    self.fetchedResultsController.delegate = self;
    [self.fetchedResultsController performFetch:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[MobilityModel sharedModel] logMessage:@"Location VC Memory Warning"];
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
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (accuracy: %gm)", [self formattedDate:location.timestamp], location.horizontalAccuracy];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"lat: %f, long: %f", location.latitude, location.longitude];
    
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

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    if (type == NSFetchedResultsChangeInsert) {
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                              withRowAnimation:UITableViewRowAnimationTop];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

@end
