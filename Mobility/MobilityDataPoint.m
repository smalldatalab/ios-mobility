//
//  MobilityLogEntry.m
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "MobilityDataPoint.h"

#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

@implementation NSMutableDictionary (MobilityDataPoint)

+ (instancetype)dataPointWithMotionActivity:(CMMotionActivity *)motionActivity
                                   location:(CLLocation *)location
{
    OMHDataPoint *dataPoint = [OMHDataPoint templateDataPoint];
    dataPoint.header.schemaID = [self schemaID];
    dataPoint.header.acquisitionProvenance = [self acquisitionProvenance];
    if (motionActivity) {
        dataPoint.header.creationDateTime = motionActivity.startDate;
    }
    else if (location) {
        dataPoint.header.creationDateTime = location.timestamp;
    }
    dataPoint.body = [MobilityDataPointBody dataPointBodyWithMotionActivity:motionActivity location:location];
    
    return dataPoint;
}

+ (OMHSchemaID *)schemaID
{
    static OMHSchemaID *sSchemaID = nil;
    if (!sSchemaID) {
        sSchemaID = [[OMHSchemaID alloc] init];
        sSchemaID.schemaNamespace = @"cornell";
        sSchemaID.name = @"mobility-stream-iOS";
        sSchemaID.version = @"1.0";
    }
    return sSchemaID;
}

+ (OMHAcquisitionProvenance *)acquisitionProvenance
{
    static OMHAcquisitionProvenance *sProvenance = nil;
    if (!sProvenance) {
        sProvenance = [[OMHAcquisitionProvenance alloc] init];
        sProvenance.sourceName = @"Mobility-iOS-1.0";
        sProvenance.modality = OMHAcquisitionProvenanceModalitySensed;
    }
    return sProvenance;
}

@end


#pragma mark - MobilityDataPointBody

@implementation NSMutableDictionary (MobilityDataPointBody)

//+ (NSMutableDictionary *)dataPointBodyWithMotionActivity:(CMMotionActivity *)motionActivity
//                                         location:(CLLocation *)location
//{
//    return [[MobilityDataPointBody alloc] initWithMotionActivity:motionActivity location:location];
//}

+ (NSString *)confidenceForMotionActivity:(CMMotionActivity *)activity
{
    switch (activity.confidence) {
        case CMMotionActivityConfidenceLow:
            return @"low";
        case CMMotionActivityConfidenceMedium:
            return @"medium";
        case CMMotionActivityConfidenceHigh:
            return @"high";
        default:
            return nil;
    }
}

//- (instancetype)initWithMotionActivity:(CMMotionActivity *)motionActivity location:(CLLocation *)location
//{
//    self = [self init];
//    if (self) {
//        if (motionActivity != nil) {
//            [self createMobilityActivitiesFromMotionActivity:motionActivity];
//        }
//        if (location != nil) {
//            self.location = [MobilityLocation mobilityLocationWithCLLocation:location];
//        }
//    }
//    return self;
//}


- (void)createMobilityActivitiesFromMotionActivity:(CMMotionActivity *)motionActivity
{
    NSString *confidence = [MobilityDataPointBody confidenceForMotionActivity:motionActivity];
    
    if (motionActivity.stationary) {
        [self.activities addObject:@{@"activity" : [MobilityActivity stringForActivityType:MobilityActivityTypeStill],
                                     @"confidence" : confidence}];
    }
    if (motionActivity.walking) {
        [self.activities addObject:@{@"activity" : [MobilityActivity stringForActivityType:MobilityActivityTypeWalk],
                                     @"confidence" : confidence}];
    }
    if (motionActivity.running) {
        [self.activities addObject:@{@"activity" : [MobilityActivity stringForActivityType:MobilityActivityTypeRun],
                                     @"confidence" : confidence}];
    }
    if (motionActivity.automotive) {
        [self.activities addObject:@{@"activity" : [MobilityActivity stringForActivityType:MobilityActivityTypeTransport],
                                     @"confidence" : confidence}];
    }
    if (motionActivity.cycling) {
        [self.activities addObject:@{@"activity" : [MobilityActivity stringForActivityType:MobilityActivityTypeCycle],
                                     @"confidence" : confidence}];
    }
    if (motionActivity.unknown || self.activities.count == 0) {
        [self.activities addObject:@{@"activity" : [MobilityActivity stringForActivityType:MobilityActivityTypeUnknown],
                                     @"confidence" : confidence}];
    }
}

- (void)setActivities:(NSMutableArray *)activities
{
    self[@"activities"] = activities;
}

- (NSMutableArray *)activities
{
    if (self[@"activities"] == nil) {
        self[@"activities"] = [NSMutableArray array];
    }
    return self[@"activities"];
}

- (void)setLocation:(NSMutableDictionary *)location
{
    self[@"location"] = location;
}

- (NSMutableDictionary *)location
{
    return self[@"location"];
}

//- (NSString *)debugActivityConfidence
//{
//    NSMutableString *text = [NSMutableString string];
//    MobilityActivity *activity;
//    for (int i = 0; i < self.activities.count; i++) {
//        if (i > 0) [text appendString:@", "];
//        activity = self.activities[i];
//        [text appendString:activity.confidence];
//    }
//    return text;
//}

@end


#pragma mark - MobilityLocation

@implementation NSMutableDictionary (MobilityLocation)

//+ (instancetype)mobilityLocationWithCLLocation:(CLLocation *)clLocation
//{
//    MobilityLocation *location = [[MobilityLocation alloc] init];
//    location.latitude = @(clLocation.coordinate.latitude);
//    location.longitude = @(clLocation.coordinate.longitude);
//    location.horizontalAccuracy = @(clLocation.horizontalAccuracy);
//    location.verticalAccuracy = @(clLocation.verticalAccuracy);
//    location.altitude = @(clLocation.altitude);
//    location.bearing = @(clLocation.course);
//    location.speed = @(clLocation.speed);
//    return location;
//}

- (void)setLatitude:(NSNumber *)latitude
{
    self[@"latitude"] = latitude;
}

- (NSNumber *)latitude
{
    return self[@"latitude"];
}

- (void)setLongitude:(NSNumber *)longitude
{
    self[@"longitude"] = longitude;
}

- (NSNumber *)longitude
{
    return self[@"longitude"];
}

- (void)setHorizontalAccuracy:(NSNumber *)accuracy
{
    self[@"horizontal_accuracy"] = accuracy;
}

- (NSNumber *)horizontalAccuracy
{
    return self[@"horizontal_accuracy"];
}

- (void)setVerticalAccuracy:(NSNumber *)accuracy
{
    self[@"vertical_accuracy"] = accuracy;
}

- (NSNumber *)verticalAccuracy
{
    return self[@"vertical_accuracy"];
}

- (void)setAltitude:(NSNumber *)altitude
{
    self[@"altitude"] = altitude;
}

- (NSNumber *)altitude
{
    return self[@"altitude"];
}

- (void)setBearing:(NSNumber *)bearing
{
    self[@"bearing"] = bearing;
}

- (NSNumber *)bearing
{
    return self[@"bearing"];
}

- (void)setSpeed:(NSNumber *)speed
{
    self[@"speed"] = speed;
}

- (NSNumber *)speed
{
    return self[@"speed"];
}

@end


#pragma mark - MobilityLocation

@implementation NSDictionary (MobilityActivity)

+ (NSString *)stringForActivityType:(MobilityActivityType)activityType
{
    switch (activityType) {
        case MobilityActivityTypeStill:
            return @"still";
        case MobilityActivityTypeWalk:
            return @"walk";
        case MobilityActivityTypeRun:
            return @"run";
        case MobilityActivityTypeTransport:
            return @"transport";
        case MobilityActivityTypeCycle:
            return @"cycle";
        default:
            return @"unknown";
    }
}

+ (MobilityActivityType)typeForActivityString:(NSString *)activityString
{
    if ([activityString isEqualToString:[self stringForActivityType:MobilityActivityTypeStill]]) {
        return MobilityActivityTypeStill;
    }
    else if ([activityString isEqualToString:[self stringForActivityType:MobilityActivityTypeWalk]]) {
        return MobilityActivityTypeWalk;
    }
    else if ([activityString isEqualToString:[self stringForActivityType:MobilityActivityTypeRun]]) {
        return MobilityActivityTypeRun;
    }
    else if ([activityString isEqualToString:[self stringForActivityType:MobilityActivityTypeTransport]]) {
        return MobilityActivityTypeTransport;
    }
    else if ([activityString isEqualToString:[self stringForActivityType:MobilityActivityTypeCycle]]) {
        return MobilityActivityTypeCycle;
    }
    else {
        return MobilityActivityTypeUnknown;
    }
}

@end
