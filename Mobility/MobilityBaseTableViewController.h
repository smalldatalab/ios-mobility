//
//  MobilityViewController.h
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MobilityModel.h"
#import "OMHClient.h"
#import "LoginViewController.h"
#import "MobilityLogger.h"
#import <CoreMotion/CoreMotion.h>

@interface MobilityBaseTableViewController : UITableViewController<NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, assign) BOOL isActiveView;

- (void)loadTable;
- (void)unloadTable;
- (void)reloadData;

@end
