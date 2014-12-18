//
//  MobilityDataPoint.h
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OMHDataPoint.h"

@class CMMotionActivity;
@class CLLocation;

typedef NSMutableDictionary MobilityDataPoint;
typedef NSMutableDictionary MobilityDataPointBody;
typedef NSMutableDictionary MobilityActivity;
typedef NSMutableDictionary MobilityLocation;


@interface NSMutableDictionary (MobilityDataPoint)

+ (instancetype)dataPointWithMotionActivity:(CMMotionActivity *)motionActivity
                                   location:(CLLocation *)location;

@end

@interface NSMutableDictionary (MobilityDataPointBody)

@property (nonatomic, strong) MobilityLocation *location;
@property (nonatomic, strong) NSMutableArray *activities;

@end

@interface NSMutableDictionary (MobilityLocation)

@property (nonatomic, strong) NSNumber *latitude;
@property (nonatomic, strong) NSNumber *longitude;
@property (nonatomic, strong) NSNumber *accuracy;
@property (nonatomic, strong) NSNumber *altitude;
@property (nonatomic, strong) NSNumber *bearing;
@property (nonatomic, strong) NSNumber *speed;

@end


@interface NSMutableDictionary (MobilityActivity)

@property (nonatomic, strong) NSString *activity;
@property (nonatomic, strong) NSNumber *confidence;

@end

