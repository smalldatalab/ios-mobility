//
//  ActivityLogger.h
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobilityDataPoint.h"

/**
 *  MobilityLogger tracks three types of data, each conditional upon device capability:
 * 
 *  - Motion Activity Data
 *  - Pedometer Data
 *  - Location Data
 *
 *  Motion activity and pedometer data are recorded passively by devices that support
 *  those capabilities, so the data can be retrieved on demand. To conserve battery,
 *  that data is only logged activily while the app is in the foreground. When the app
 *  is in the background, activity and pedometer data is retrieved and uploaded
 *  at a timer-based interval, conditional upon DSU reachability.
 *
 *  Neither the motion activity nor pedometer data APIs are capable of keeping the
 *  device alive in the background, so for that the app relies on the Location API.
 *  
 *  To keep the app alive in the background, the location tracker needs remain on
 *  and tracking at all times. In order to conserve battery, it spends most of the time 
 *  in a low-power, low-accuracy state. At regular timer-based intervals, the
 *  location tracker switches to a high-power, high-accuracy state long enough to
 *  obtain an accurace location sample, then returns to its low-power state.
 *
 *  Obtaining a high-accuracy location sample is the most power-consumptive aspect
 *  of the app, so in the interest of conserving batter life the app performers fewer
 *  location samples while the device is stationary. To do that it uses the
 *  motion activity state of the device to determine an appropriate interval between
 *  location samples. When the device is stationary, the sampling timer is set
 *  to a longer interval than when it is in motion.
 *
 *  Consequently, every time the location sample timer fires, retrieves both 
 *  the current location and the current motion activity state of the device. 
 *  The motion activity state is then used to set the interval for the next 
 *  location sample timer to fire.
 */

@interface MobilityLogger : NSObject

+ (instancetype)sharedLogger;

- (void)startLogging;
- (void)stopLogging;
- (void)enteredBackground;
- (void)enteredForeground;

@end
