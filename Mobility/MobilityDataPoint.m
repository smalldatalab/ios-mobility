//
//  MobilityLogEntry.m
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "MobilityDataPoint"

#import <CoreMotion/CoreMotion.h>

@implementation NSMutableDictionary (MobilityDataPoint)

+ (instancetype)dataPointWithMotionActivity:(CMMotionActivity *)motionActivity
                                   location:(CLLocation *)location
{
    OMHDataPoint *dataPoint = [OMHDataPoint templateDataPoint];
    dataPoint.header.schemaID = [self schemaID];
    dataPoint.header.acquisitionProvenance = [self acquisitionProvenance];
    dataPoint.header.creationDateTime = motionActivity.startDate;
    dataPoint.body = [MobilityDataPointBody dataPointWithMotionActivity:motionActivity location:location];
    
    return dataPoint;
}

+ (OMHSchemaID *)schemaID
{
    static OMHSchemaID *sSchemaID = nil;
    if (!sSchemaID) {
        sSchemaID = [[OMHSchemaID alloc] init];
        sSchemaID.schemaNamespace = @"cornell";
        sSchemaID.name = @"mobility-stream";
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

+ (NSDictionary *)dataPointBodyWithMotionActivity:(CMMotionActivity *)motionActivity
                                         location:(CLLocation *)location
{
    return [[MobilityDataPointBody alloc] initWithMotionActivity:motionActivity location:location];
}

+ (NSNumber *)confidenceForMotionActivity:(CMMotionActivity *)activity
{
    switch (activity.confidence) {
        case CMMotionActivityConfidenceLow:
            return @(0);
        case CMMotionActivityConfidenceMedium:
            return @(50);
        case CMMotionActivityConfidenceHigh:
            return @(100);
        default:
            return nil;
    }
}

- (instancetype)initWithMotionActivity:(CMMotionActivity *)motionActivity location:(CLLocation *)location
{
    self = [self init];
    if (self) {
        [self createMobilityActivitiesFromMotionActivity:motionActivity];
    }
    return self;
}


- (void)createMobilityActivitiesFromMotionActivity:(CMMotionActivity *)motionActivity
{
    NSNumber *confidence = [MobilityDataPointBody confidenceForMotionActivity:motionActivity];
    
    if (motionActivity.stationary) {
        [self.activities addObject:@{@"activity" : @"still",
                                     @"confidence" : confidence}];
    }
    if (motionActivity.walking) {
        [self.activities addObject:@{@"activity" : @"walk",
                                     @"confidence" : confidence}];
    }
    if (motionActivity.running) {
        [self.activities addObject:@{@"activity" : @"run",
                                     @"confidence" : confidence}];
    }
    if (motionActivity.automotive) {
        [self.activities addObject:@{@"activity" : @"transport",
                                     @"confidence" : confidence}];
    }
    if (motionActivity.cycling) {
        [self.activities addObject:@{@"activity" : @"cycling",
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

@end


#pragma mark - MobilityLocation

@implementation NSMutableDictionary (MobilityLocation)

- (void)setLatitude:(NSNumber *)latitude
{
    self[@"latitude"] = latitude;
}

- (NSNumber *)latitude
{
    return self[@"latitide"];
}

- (void)setLongitude:(NSNumber *)longitude
{
    self[@"longitude"] = longitude;
}

- (NSNumber *)longitude
{
    return self[@"longitude"];
}

- (void)setAccuracy:(NSNumber *)accuracy
{
    self[@"accuracy"] = accuracy;
}

- (NSNumber *)accuracy
{
    return self[@"accuracy"];
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

@implementation NSMutableDictionary (MobilityActivity)


- (void)setActivity:(NSString *)activity
{
    self[@"activity"] = activity;
}

- (NSString *)activity
{
    return self[@"activity"];
}

- (void)setConfidence:(NSNumber *)confidence
{
    self[@"confidence"] = confidence;
}

- (NSNumber *)confidence
{
    return self[@"confidence"];
}

@end
