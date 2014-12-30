//
//  ActivityLogger.h
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobilityDataPoint.h"

@interface ActivityLogger : NSObject

+ (instancetype)sharedLogger;

@property (nonatomic, readonly) NSArray *activityDataPoints;
@property (nonatomic, readonly) NSArray *locationDataPoints;
@property (copy) void (^newActivityDataPointBlock)(MobilityDataPoint *dataPoint);
@property (copy) void (^newLocationDataPointBlock)(MobilityDataPoint *dataPoint);

- (void)startLogging;
//
//- (void)enterBackgroundMode;
//- (void)exitBackgroundMode;

@end
