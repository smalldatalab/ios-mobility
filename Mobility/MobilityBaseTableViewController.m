//
//  MobilityViewController.m
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "MobilityBaseTableViewController.h"
#import "AppDelegate.h"
#import "AppConstants.h"
#import "WebViewController.h"

@interface MobilityBaseTableViewController ()

@property (assign) BOOL shouldAnimateTableUpdates;

@end

@implementation MobilityBaseTableViewController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        [self registerForNotifications];
        self.isActiveView = NO;
    }
    return self;
}

- (void)dealloc
{
    [self unregisterForNotifications];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    
    self.navigationItem.rightBarButtonItem = doneButton;
    
}

- (void)viewWillAppear:(BOOL)animated
{
//    NSLog(@"%s, %@", __PRETTY_FUNCTION__, [self class]);
    [super viewWillAppear:animated];
    self.isActiveView = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
//    NSLog(@"%s, %@", __PRETTY_FUNCTION__, [self class]);
    [super viewDidAppear:animated];
    [self loadTable];
}

- (void)viewDidDisappear:(BOOL)animated
{
//    NSLog(@"%s, %@", __PRETTY_FUNCTION__, [self class]);
    [super viewDidDisappear:animated];
    self.isActiveView = NO;
    [self unloadTable];
}
//
//- (void)didReceiveMemoryWarning
//{
//    [super didReceiveMemoryWarning];
//    [[MobilityModel sharedModel] logMessage:@"Memory Warning"];
//}

- (void)doneButtonPressed {
    UINavigationController *nav = (UINavigationController *)self.presentingViewController;
    WebViewController *wv = (WebViewController *)nav.topViewController;
    [wv dismissDataTabs];
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enteredBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enteredForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userChanged) name:kMobilityModelUserChangedNotification object:nil];
}

- (void)unregisterForNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMobilityModelUserChangedNotification object:nil];
}

- (void)enteredForeground
{
    NSLog(@"%s, %@", __PRETTY_FUNCTION__, [self class]);
    if (self.isActiveView) {
        [self loadTable];
    }
}

- (void)enteredBackground
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self unloadTable];
}

- (void)userChanged
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.fetchedResultsController = nil;
    [self.fetchedResultsController performFetch:nil];
    [self.tableView reloadData];
}

- (void)loadTable {}

- (void)reloadData
{
    [self.tableView reloadData];
//    [self.fetchedResultsController.managedObjectContext performBlock:^{
//        [self.tableView reloadData];
//    }];
}

- (void)unloadTable
{
    self.fetchedResultsController = nil;
    [self.tableView reloadData];
}

- (void)logout
{
    [[MobilityLogger sharedLogger] stopLogging];
    [[OMHClient sharedClient] signOut];
    [[MobilityModel sharedModel] setUserEmail:nil];
    
    [(AppDelegate *)[UIApplication sharedApplication].delegate userDidLogout];
}

- (void)visualizeButtonPressed
{
    NSURL *url = [NSURL URLWithString:kMobilityVisualizerURL];
    [[UIApplication sharedApplication] openURL:url];
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
    return nil;
}


#pragma mark - NSFetchedResultsController Delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    self.shouldAnimateTableUpdates = [self.tableView.indexPathsForVisibleRows containsObject:[NSIndexPath indexPathForRow:0 inSection:0]];
    if (self.shouldAnimateTableUpdates) {
        [self.tableView beginUpdates];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    if (type == NSFetchedResultsChangeUpdate) {
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    if (!self.shouldAnimateTableUpdates) return;
    
    if (type == NSFetchedResultsChangeInsert) {
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                              withRowAnimation:UITableViewRowAnimationTop];
    }
    else if (type == NSFetchedResultsChangeDelete) {
        NSLog(@"%s deleting row. indexPath: %@, newIndexPath: %@", __PRETTY_FUNCTION__, [@(indexPath.row) stringValue], [@(newIndexPath.row) stringValue]);
        [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (self.shouldAnimateTableUpdates) {
        [self.tableView endUpdates];
    }
    else {
        CGSize beforeContentSize = self.tableView.contentSize;
        [self.tableView reloadData];
        CGSize afterContentSize = self.tableView.contentSize;
        
        CGPoint afterContentOffset = self.tableView.contentOffset;
        CGPoint newContentOffset = CGPointMake(afterContentOffset.x, afterContentOffset.y + afterContentSize.height - beforeContentSize.height);
        self.tableView.contentOffset = newContentOffset;
    }
}

@end
