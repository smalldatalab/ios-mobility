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
#import "MobilityPedometerData.h"

@implementation NSMutableDictionary (MobilityDataPoint)

+ (instancetype)dataPointWithEntity:(MobilityDataPointEntity *)entity
{
    OMHDataPoint *dataPoint = [OMHDataPoint templateDataPoint];
    dataPoint.header.schemaID = [self schemaID];
    dataPoint.header.acquisitionProvenance = [self acquisitionProvenance];
    dataPoint.header.headerID = entity.uuid;
    dataPoint.header.creationDateTime = entity.timestamp;
    dataPoint.body = entity.jsonDictionary;
    return dataPoint;
}

+ (OMHSchemaID *)schemaID
{
    static OMHSchemaID *sSchemaID = nil;
    if (!sSchemaID) {
        sSchemaID = [[OMHSchemaID alloc] init];
        sSchemaID.schemaNamespace = @"cornell";
        sSchemaID.name = @"mobility-stream-iOS";
        sSchemaID.version = @"1.1";
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
