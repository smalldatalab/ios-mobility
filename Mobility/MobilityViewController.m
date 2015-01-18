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
#import <CoreMotion/CoreMotion.h>

@interface MobilityViewController () <NSFetchedResultsControllerDelegate>

//@property (nonatomic, strong) ActivityLogger *logger;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, assign) BOOL isActivityAvailable;

@end

@implementation MobilityViewController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.title = @"Activities";
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
    NSLog(@"activity table entered background");
    self.fetchedResultsController = nil;
}

- (void)enteredForeground
{
    NSLog(@"activity table entered foreground");
    [self.fetchedResultsController performFetch:nil];
    [self.tableView reloadData];
}

- (void)userChanged
{
    self.fetchedResultsController = nil;
    [self.fetchedResultsController performFetch:nil];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(logout)];
    
    self.navigationItem.leftBarButtonItem = logoutButton;
    
    self.isActivityAvailable = [CMMotionActivityManager isActivityAvailable];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[MobilityModel sharedModel] logMessage:@"Activity VC Memory Warning"];
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (!self.isActivityAvailable) return nil;
    
    if (_fetchedResultsController == nil) {
        _fetchedResultsController = [[MobilityModel sharedModel] fetchedActivitesController];
        _fetchedResultsController.delegate = self;
    }
    return _fetchedResultsController;
}

- (void)logout
{
    [[ActivityLogger sharedLogger] stopLogging];
    [[OMHClient sharedClient] signOut];
    [[MobilityModel sharedModel] setUserEmail:nil];
    [self presentViewController:[[LoginViewController alloc] init] animated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.isActivityAvailable) {
        return self.fetchedResultsController.fetchedObjects.count;
    }
    else {
        return 1;
    }
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
    cell.detailTextLabel.text = [self formattedDate:activity.timestamp];
    
    return cell;
}

- (UITableViewCell *)noActivityCell
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.text = @"Activity tracking not supported";
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
