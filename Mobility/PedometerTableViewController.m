//
//  PedometerTableViewController.m
//  Mobility
//
//  Created by Charles Forkish on 4/8/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import "PedometerTableViewController.h"
#import "MobilityModel.h"

@interface PedometerTableViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation PedometerTableViewController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.title = @"Pedometer";
        [self registerForNotifications];
    }
    return self;
}

- (void)dealloc
{
    [self unregisterForNotifications];
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enteredBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enteredForeground) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userChanged) name:kMobilityModelUserChangedNotification object:nil];
}

- (void)unregisterForNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMobilityModelUserChangedNotification object:nil];
}

- (void)enteredBackground
{
    NSLog(@"pedometer table entered background");
    self.fetchedResultsController = nil;
}

- (void)enteredForeground
{
    NSLog(@"pedometer table entered foreground");
    [self.fetchedResultsController.managedObjectContext performBlock:^{
        [self.fetchedResultsController performFetch:nil];
        [self.tableView reloadData];
    }];
}

- (void)userChanged
{
    self.fetchedResultsController = nil;
    [self.fetchedResultsController performFetch:nil];
    [self.tableView reloadData];
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController == nil) {
        _fetchedResultsController = [[MobilityModel sharedModel] fetchedPedometerDataController];
        _fetchedResultsController.delegate = self;
    }
    return _fetchedResultsController;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[MobilityModel sharedModel] logMessage:@"Pedometer VC Memory Warning"];
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
