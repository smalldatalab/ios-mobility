//
//  MobilityModel.h
//  Mobility
//
//  Created by Charles Forkish on 12/24/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobilityActivity.h"
#import "MobilityLocation.h"
#import "MobilityPedometerData.h"
#import "DebugLogEntry.h"

static NSString * const kMobilityModelUserChangedNotification = @"MobilityModelUserChanged";

@class CLLocation;
@class CMMotionActivity;
@class CMPedometerData;

@interface MobilityModel : NSObject

+ (instancetype)sharedModel;

- (void)setUserEmail:(NSString *)userEmail;
- (void)saveManagedContext;

- (void)logMessage:(NSString *)message;

- (MobilityActivity *)uniqueActivityWithMotionActivity:(CMMotionActivity *)motionActivity;
- (MobilityLocation *)uniqueLocationWithCLLocation:(CLLocation *)clLocation;
- (MobilityPedometerData *)uniquePedometerDataWithCMPedometerData:(CMPedometerData *)cmPedometerData;
- (NSArray *)oldestPendingActivitiesWithLimit:(NSInteger)fetchLimit;
- (NSArray *)oldestPendingLocationsWithLimit:(NSInteger)fetchLimit;
- (NSArray *)oldestPendingPedometerDataWithLimit:(NSInteger)fetchLimit;
- (NSFetchedResultsController *)fetchedActivitesController;
- (NSFetchedResultsController *)fetchedLocationsController;
- (NSFetchedResultsController *)fetchedPedometerDataController;
- (NSFetchedResultsController *)fetchedLogEntriesController;

@end
