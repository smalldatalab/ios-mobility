//
//  MobilityPedometerData.h
//  Mobility
//
//  Created by Charles Forkish on 4/7/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MobilityDataPointEntity.h"

typedef NSMutableDictionary MobilityPedometerDataDictionary;

@interface MobilityPedometerData : MobilityDataPointEntity

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSNumber *stepCount;
@property (nonatomic, strong) NSNumber *distance;
@property (nonatomic, strong) NSNumber *floorsAscended;
@property (nonatomic, strong) NSNumber *floorsDescended;

@end


@interface NSMutableDictionary (MobilityPedometerDataDictionary)

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSNumber *stepCount;
@property (nonatomic, strong) NSNumber *distance;
@property (nonatomic, strong) NSNumber *floorsAscended;
@property (nonatomic, strong) NSNumber *floorsDescended;

@end
