//
//  MobilityLogEntry.m
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "MobilityDataPoint.h"
#import "OMHDataPoint.h"
#import "MobilityActivity.h"
#import "MobilityLocation.h"

@implementation NSMutableDictionary (MobilityDataPoint)

+ (instancetype)mobilityDataPointWithHeaderID:(NSString *)headerID timestamp:(NSDate *)timestamp body:(NSMutableDictionary *)body
{
    OMHDataPoint *dataPoint = [OMHDataPoint templateDataPoint];
    dataPoint.header.schemaID = [self schemaID];
    dataPoint.header.acquisitionProvenance = [self acquisitionProvenance];
    dataPoint.header.headerID = headerID;
    dataPoint.header.creationDateTime = timestamp;
    dataPoint.body = body;
    return dataPoint;
}

+ (instancetype)dataPointWithActivity:(MobilityActivity *)activity
{
    return [self mobilityDataPointWithHeaderID:activity.uuid timestamp:activity.timestamp body:activity.jsonDictionary];
}

+ (instancetype)dataPointWithLocation:(MobilityLocation *)location
{
    return [self mobilityDataPointWithHeaderID:location.uuid timestamp:location.timestamp body:location.jsonDictionary];
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
