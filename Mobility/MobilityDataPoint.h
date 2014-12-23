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

+ (NSMutableDictionary *)dataPointBodyWithMotionActivity:(CMMotionActivity *)motionActivity
                                         location:(CLLocation *)location;

@property (nonatomic, strong) MobilityLocation *location;
@property (nonatomic, strong) NSMutableArray *activities;
@property (nonatomic, readonly) NSString *debugActivityString;
@property (nonatomic, readonly) NSString *debugActivityConfidence;


@end

@interface NSMutableDictionary (MobilityLocation)

+ (instancetype)mobilityLocationWithCLLocation:(CLLocation *)clLocation;

@property (nonatomic, strong) NSNumber *latitude;
@property (nonatomic, strong) NSNumber *longitude;
@property (nonatomic, strong) NSNumber *horizontalAccuracy;
@property (nonatomic, strong) NSNumber *verticalAccuracy;
@property (nonatomic, strong) NSNumber *altitude;
@property (nonatomic, strong) NSNumber *bearing;
@property (nonatomic, strong) NSNumber *speed;

@end


typedef enum {
    MobilityActivityTypeStill,
    MobilityActivityTypeWalk,
    MobilityActivityTypeRun,
    MobilityActivityTypeTransport,
    MobilityActivityTypeCycle,
    MobilityActivityTypeUnknown
} MobilityActivityType;

@interface NSDictionary (MobilityActivity)

+ (NSString *)stringForActivityType:(MobilityActivityType)activityType;
+ (MobilityActivityType)typeForActivityString:(NSString *)activityString;

@property (nonatomic, readonly) MobilityActivityType activityType;
@property (nonatomic, readonly) NSString *activityString;
@property (nonatomic, readonly) NSString *confidence;

@end

