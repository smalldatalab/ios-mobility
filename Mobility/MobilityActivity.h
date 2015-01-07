//
//  MobilityActivity.h
//  Mobility
//
//  Created by Charles Forkish on 12/29/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreMotion/CoreMotion.h>

typedef NSDictionary MobilityActivityDictionary;

typedef enum {
    MobilityActivityTypeStill,
    MobilityActivityTypeWalk,
    MobilityActivityTypeRun,
    MobilityActivityTypeTransport,
    MobilityActivityTypeCycle,
    MobilityActivityTypeUnknown
} MobilityActivityType;


@interface MobilityActivity : NSManagedObject

@property (nonatomic) int16_t confidence;
@property (nonatomic, strong) NSDate * timestamp;
@property (nonatomic, strong) NSString * uuid;
@property (nonatomic) BOOL stationary;
@property (nonatomic) BOOL walking;
@property (nonatomic) BOOL running;
@property (nonatomic) BOOL automotive;
@property (nonatomic) BOOL cycling;
@property (nonatomic) BOOL unknown;
@property (nonatomic) BOOL submitted;

@property (nonatomic, readonly) NSArray *activitiesArray;
@property (nonatomic, readonly) NSString *debugActivityString;
@property (nonatomic, readonly) NSString *confidenceString;

@property (nonatomic, readonly) NSMutableDictionary *jsonDictionary;

+ (NSString *)stringForActivityType:(MobilityActivityType)activityType;
+ (MobilityActivityType)typeForActivityString:(NSString *)activityString;

+ (NSString *)stringForConfidence:(CMMotionActivityConfidence)confidence;
//+ (CMMotionActivityConfidence)confidenceForConfidenceString:(NSString *)confidenceString;

@end

@interface NSDictionary (MobilityActivityDictionary)

@property (nonatomic, readonly) MobilityActivityType activityType;
@property (nonatomic, readonly) NSString *activityString;
@property (nonatomic, readonly) NSString *confidence;

@end
