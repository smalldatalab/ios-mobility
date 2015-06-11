//
//  MobilityDataPoint.h
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MobilityDataPointEntity;

typedef NSMutableDictionary MobilityDataPoint;
typedef NSMutableDictionary MobilityDataPointBody;


@interface NSMutableDictionary (MobilityDataPoint)

+ (instancetype)dataPointWithEntity:(MobilityDataPointEntity *)entity;

@end

