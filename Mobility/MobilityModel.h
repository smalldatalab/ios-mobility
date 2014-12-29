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

@class CLLocation;
@class CMMotionActivity;

@interface MobilityModel : NSObject

+ (instancetype)sharedModel;

- (MobilityActivity *)uniqueActivityWithMotionActivity:(CMMotionActivity *)motionActivity;
- (MobilityLocation *)uniqueLocationWithCLLocation:(CLLocation *)clLocation;
- (NSFetchedResultsController *)fetchedActivitesController;
- (NSFetchedResultsController *)fetchedLocationsController;

@end
