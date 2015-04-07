//
//  MobilityPedometerData.m
//  Mobility
//
//  Created by Charles Forkish on 4/7/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import "MobilityPedometerData.h"


@implementation MobilityPedometerData

@dynamic startDate;
@dynamic endDate;
@dynamic stepCount;
@dynamic distance;
@dynamic floorsAscended;
@dynamic floorsDescended;
@dynamic userEmail;
@dynamic uuid;

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    self.uuid = [[[NSUUID alloc] init] UUIDString];
}

@end
