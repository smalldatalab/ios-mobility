//
//  ActivityLogger.h
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobilityDataPoint.h"

@interface ActivityLogger : NSObject

+ (instancetype)sharedLogger;

- (void)startLogging;
- (void)stopLogging;
- (void)enteredBackground;
- (void)enteredForeground;

@end
