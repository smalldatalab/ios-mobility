//
//  MobilityLocation.h
//  Mobility
//
//  Created by Charles Forkish on 12/24/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MobilityDataPointEntity.h"

typedef NSMutableDictionary MobilityLocationDictionary;


@interface MobilityLocation : MobilityDataPointEntity

@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic) double horizontalAccuracy;
@property (nonatomic) double verticalAccuracy;
@property (nonatomic) double altitude;
@property (nonatomic) double bearing;
@property (nonatomic) double speed;

@end


@interface NSMutableDictionary (MobilityLocationDictionary)

@property (nonatomic, strong) NSNumber *latitude;
@property (nonatomic, strong) NSNumber *longitude;
@property (nonatomic, strong) NSNumber *horizontalAccuracy;
@property (nonatomic, strong) NSNumber *verticalAccuracy;
@property (nonatomic, strong) NSNumber *altitude;
@property (nonatomic, strong) NSNumber *bearing;
@property (nonatomic, strong) NSNumber *speed;

@end