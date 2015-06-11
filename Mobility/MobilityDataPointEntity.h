//
//  MobilityDataPointEntity.h
//  Mobility
//
//  Created by Charles Forkish on 6/7/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MobilityDataPointEntity : NSManagedObject

@property (nonatomic, strong) NSDate * timestamp;
@property (nonatomic) BOOL submitted;
@property (nonatomic, strong) NSString * userEmail;
@property (nonatomic, strong) NSString * uuid;
@property (nonatomic) BOOL uploaded;

@end
