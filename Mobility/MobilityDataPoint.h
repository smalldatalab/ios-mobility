//
//  MobilityDataPoint.h
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MobilityActivity;
@class MobilityLocation;
@class MobilityPedometerData;

typedef NSMutableDictionary MobilityDataPoint;
typedef NSMutableDictionary MobilityDataPointBody;


@interface NSMutableDictionary (MobilityDataPoint)

+ (instancetype)dataPointWithActivity:(MobilityActivity *)activity;
+ (instancetype)dataPointWithLocation:(MobilityLocation *)location;
+ (instancetype)dataPointWithPedometerData:(MobilityPedometerData *)pedometerData;

@end

