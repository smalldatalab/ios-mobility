//
//  MobilityActivity.h
//  Mobility
//
//  Created by Charles Forkish on 12/24/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreMotion/CoreMotion.h>


typedef enum {
    MobilityActivityTypeStill,
    MobilityActivityTypeWalk,
    MobilityActivityTypeRun,
    MobilityActivityTypeTransport,
    MobilityActivityTypeCycle,
    MobilityActivityTypeUnknown
} MobilityActivityType;

@interface MobilityActivity : NSManagedObject

@property (nonatomic) int16_t activityType;
@property (nonatomic) int16_t confidence;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic) NSTimeInterval timestamp;


@property (nonatomic, readonly) NSString *activityString;
@property (nonatomic, readonly) NSString *confidenceString;

+ (NSString *)stringForActivityType:(MobilityActivityType)activityType;
+ (MobilityActivityType)typeForActivityString:(NSString *)activityString;

+ (NSString *)stringForConfidence:(CMMotionActivityConfidence)confidence;
+ (CMMotionActivityConfidence)confidenceForConfidenceString:(NSString *)confidenceString;

@end
