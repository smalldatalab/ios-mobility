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

@property (nonatomic, readonly) NSArray *dataPoints;
@property (copy) void (^newDataPointBlock)(MobilityDataPoint *dataPoint);

- (void)startLogging;

@end
