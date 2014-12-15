//
//  MobilityLogEntry.m
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "MobilityLogEntry.h"

#import <CoreMotion/CoreMotion.h>

@implementation NSMutableDictionary (MobilityLogEntry)

- (instancetype)initWithActivity:(CMMotionActivity *)activity
{
    self = [NSMutableDictionary dictionary];
    if (self) {
        self[@"start_date"] = activity.startDate;
        self[@"confidence"] = @(activity.confidence);
    }
    return self;
}

@end
