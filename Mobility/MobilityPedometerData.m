//
//  MobilityPedometerData.m
//  Mobility
//
//  Created by Charles Forkish on 4/7/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import "MobilityPedometerData.h"
#import "OMHDataPoint.h"


@implementation MobilityPedometerData

@dynamic startDate;
@dynamic endDate;
@dynamic stepCount;
@dynamic distance;
@dynamic floorsAscended;
@dynamic floorsDescended;
@dynamic userEmail;
@dynamic uuid;
@dynamic submitted;

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    self.uuid = [[[NSUUID alloc] init] UUIDString];
}

- (MobilityPedometerDataDictionary *)jsonDictionary
{
    MobilityPedometerDataDictionary *pd = [[MobilityPedometerDataDictionary alloc] init];
    pd.startDate = self.startDate;
    pd.endDate = self.endDate;
    pd.distance = self.distance;
    pd.floorsAscended = self.floorsAscended;
    pd.floorsDescended = self.floorsDescended;
    return [NSMutableDictionary dictionaryWithObject:pd forKey:@"pedometer_data"];
}

@end

#pragma mark - MobilityLocationDictionary

@implementation NSMutableDictionary (MobilityPedometerDataDictionary)

- (void)setStartDate:(NSDate *)startDate
{
    self[@"start_date"] = [OMHDataPoint stringFromDate:startDate];
}

- (NSDate *)startDate
{
    return [OMHDataPoint dateFromString:self[@"start_date"]];
}

- (void)setEndDate:(NSDate *)endDate
{
    self[@"end_date"] = [OMHDataPoint stringFromDate:endDate];
}

- (NSDate *)endDate
{
    return [OMHDataPoint dateFromString:self[@"end_date"]];
}

- (void)setStepCount:(NSNumber *)stepCount
{
    self[@"step_count"] = stepCount;
}

- (NSNumber *)stepCount
{
    return self[@"step_count"];
}

- (void)setDistance:(NSNumber *)distance
{
    self[@"distance"] = distance;
}

- (NSNumber *)distance
{
    return self[@"distance"];
}

- (void)setFloorsAscended:(NSNumber *)floorsAscended
{
    self[@"floors_ascended"] = floorsAscended;
}

- (NSNumber *)floorsAscended
{
    return self[@"floors_ascended"];
}

- (void)setFloorsDescended:(NSNumber *)floorsDescended
{
    self[@"floors_descended"] = floorsDescended;
}

- (NSNumber *)floorsDescended
{
    return self[@"floors_descended"];
}

@end
