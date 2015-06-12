//
//  LocationTableViewController.m
//  Mobility
//
//  Created by Charles Forkish on 12/23/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "LocationTableViewController.h"

@interface LocationTableViewController ()

@end

@implementation LocationTableViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = @"Locations";
    }
    return self;
}



- (void)loadTable
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (self.fetchedResultsController == nil) {
        self.fetchedResultsController = [[MobilityModel sharedModel] fetchedLocationsController];
        self.fetchedResultsController.delegate = self;
    }
    
//    [self.tableView reloadData];
    
    [self reloadData];
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
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (accuracy: %gm)", [location.timestamp formattedDate], location.horizontalAccuracy];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"lat: %f, long: %f", location.latitude, location.longitude];
    cell.accessoryType = location.uploaded ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

//
//#pragma mark - NSFetchedResultsController Delegate
//
//- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
//{
//    [self.tableView beginUpdates];
//}
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
//       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
//      newIndexPath:(NSIndexPath *)newIndexPath
//{
//    if (type == NSFetchedResultsChangeInsert) {
//        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
//                              withRowAnimation:UITableViewRowAnimationTop];
//    }
//}
//
//- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
//{
//    [self.tableView endUpdates];
//}

@end
