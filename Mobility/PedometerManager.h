//
//  StepCountManager.h
//  Mobility
//
//  Created by Charles Forkish on 4/7/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PedometerManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, readonly) BOOL isQueryingPedometer;

- (void)queryPedometer;
- (void)stopQueries;

@end
