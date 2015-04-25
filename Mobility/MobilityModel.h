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

//- (MobilityActivity *)uniqueActivityWithMotionActivity:(CMMotionActivity *)motionActivity moc:(NSManagedObjectContext *)moc;
- (MobilityActivity *)insertActivityWithMotionActivity:(CMMotionActivity *)motionActivity moc:(NSManagedObjectContext *)moc;
- (MobilityLocation *)uniqueLocationWithCLLocation:(CLLocation *)clLocation moc:(NSManagedObjectContext *)moc;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (MobilityPedometerData *)uniquePedometerDataWithCMPedometerData:(CMPedometerData *)cmPedometerData moc:(NSManagedObjectContext *)moc;
#else
- (MobilityPedometerData *)uniquePedometerDataWithStepCount:(NSInteger)stepCount startDate:(NSDate *)startDate endDate:(NSDate *)endDate moc:(NSManagedObjectContext *)moc;
#endif
- (NSArray *)activitiesSinceDate:(NSDate *)startDate moc:(NSManagedObjectContext *)moc;
- (NSArray *)oldestPendingActivitiesWithLimit:(NSInteger)fetchLimit;
- (NSArray *)oldestPendingLocationsWithLimit:(NSInteger)fetchLimit;
- (NSArray *)oldestPendingPedometerDataWithLimit:(NSInteger)fetchLimit;
- (NSFetchedResultsController *)fetchedActivitesController;
- (NSFetchedResultsController *)fetchedLocationsController;
- (NSFetchedResultsController *)fetchedPedometerDataController;
- (NSFetchedResultsController *)fetchedLogEntriesController;

- (NSManagedObjectContext *)newChildMOC;

@end
