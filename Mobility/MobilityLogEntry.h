//
//  MobilityLogEntry.h
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CMMotionActivity;

typedef NSMutableDictionary MobilityLogEntry;

@interface NSMutableDictionary (MobilityLogEntry)

- (instancetype)initWithActivity:(CMMotionActivity *)activity;

@end
