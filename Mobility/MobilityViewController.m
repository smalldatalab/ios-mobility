//
//  MobilityViewController.m
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "MobilityViewController.h"
#import "MobilityModel.h"
#import "OMHClient.h"
#import "LoginViewController.h"
#import "ActivityLogger.h"

@interface MobilityViewController () <NSFetchedResultsControllerDelegate>

//@property (nonatomic, strong) ActivityLogger *logger;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation MobilityViewController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.title = @"Activities";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(logout)];
    
    self.navigationItem.leftBarButtonItem = logoutButton;
    
    self.fetchedResultsController = [[MobilityModel sharedModel] fetchedActivitesController];
    self.fetchedResultsController.delegate = self;
    
//    self.logger = [ActivityLogger sharedLogger];
//    
//    __weak typeof(self) weakSelf = self;
//    self.logger.newActivityDataPointBlock = ^(MobilityDataPoint *dataPoint) {
////        NSLog(@"new log entry: %@", dataPoint);
////        [weakSelf.tableView reloadData];
//        [weakSelf insertRowForDataPoint:dataPoint];
//    };
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.fetchedResultsController performFetch:nil];
}

- (void)logout
{
    [[ActivityLogger sharedLogger] stopLogging];
    [[OMHClient sharedClient] signOut];
    [self presentViewController:[[LoginViewController alloc] init] animated:YES completion:nil];
}

//- (void)insertRowForDataPoint:(MobilityDataPoint *)dataPoint
//{
//    [self.tableView beginUpdates];
//    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
//                          withRowAnimation:UITableViewRowAnimationTop];
//    [self.tableView endUpdates];
//}

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
    static NSString *cellIdentifier = @"activityCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    MobilityActivity *activity = self.fetchedResultsController.fetchedObjects[indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", activity.debugActivityString, activity.confidenceString];
    cell.detailTextLabel.text = [self formattedDate:activity.timestamp];
    
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
