//
//  MobilityPedometerData.h
//  Mobility
//
//  Created by Charles Forkish on 4/7/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef NSMutableDictionary MobilityPedometerDataDictionary;

@interface MobilityPedometerData : NSManagedObject

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSNumber *stepCount;
@property (nonatomic, strong) NSNumber *distance;
@property (nonatomic, strong) NSNumber *floorsAscended;
@property (nonatomic, strong) NSNumber *floorsDescended;
@property (nonatomic, retain) NSString * userEmail;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic) BOOL submitted;

@property (nonatomic, readonly) NSMutableDictionary *jsonDictionary;

@end


@interface NSMutableDictionary (MobilityPedometerDataDictionary)

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSNumber *stepCount;
@property (nonatomic, strong) NSNumber *distance;
@property (nonatomic, strong) NSNumber *floorsAscended;
@property (nonatomic, strong) NSNumber *floorsDescended;

@end