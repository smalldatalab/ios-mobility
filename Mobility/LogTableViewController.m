//
//  LogTableViewController.m
//  Mobility
//
//  Created by Charles Forkish on 1/7/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import "LogTableViewController.h"
#import "MobilityModel.h"

@interface LogTableViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation LogTableViewController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.title = @"Log";
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
//    NSLog(@"log table entered background");
//    self.fetchedResultsController.delegate = nil;
//}
//
//- (void)enteredForeground
//{
//    NSLog(@"log table entered foreground");
//    self.fetchedResultsController.delegate = self;
//    [self.fetchedResultsController performFetch:nil];
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.fetchedResultsController = [[MobilityModel sharedModel] fetchedLogEntriesController];
    self.fetchedResultsController.delegate = self;
    [self.fetchedResultsController performFetch:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[MobilityModel sharedModel] logMessage:@"Log VC Memory Warning"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.fetchedResultsController.fetchedObjects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * sCellIdentifier = @"logCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:sCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:sCellIdentifier];
    }
    
    DebugLogEntry *logEntry = self.fetchedResultsController.fetchedObjects[indexPath.row];
    cell.textLabel.text = logEntry.text;
    cell.detailTextLabel.text = [self formattedDate:logEntry.timestamp];
    
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
