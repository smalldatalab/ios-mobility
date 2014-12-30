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

+ (instancetype)baseMobilityDataPoint
{
    OMHDataPoint *dataPoint = [OMHDataPoint templateDataPoint];
    dataPoint.header.schemaID = [self schemaID];
    dataPoint.header.acquisitionProvenance = [self acquisitionProvenance];
    return dataPoint;
}

+ (instancetype)dataPointWithActivity:(MobilityActivity *)activity
{
    OMHDataPoint *dataPoint = [self baseMobilityDataPoint];
    dataPoint.header.creationDateTime = activity.timestamp;
    dataPoint.body = activity.jsonDictionary;
    return dataPoint;
}

+ (instancetype)dataPointWithLocation:(MobilityLocation *)location
{
    OMHDataPoint *dataPoint = [self baseMobilityDataPoint];
    dataPoint.header.creationDateTime = location.timestamp;
    dataPoint.body = location.jsonDictionary;
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
