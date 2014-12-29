//
//  MobilityLocation.h
//  Mobility
//
//  Created by Charles Forkish on 12/24/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MobilityLocation : NSManagedObject

@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic) double horizontalAccuracy;
@property (nonatomic) double verticalAccuracy;
@property (nonatomic) double altitude;
@property (nonatomic) double bearing;
@property (nonatomic) double speed;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic) NSTimeInterval timestamp;

@end
