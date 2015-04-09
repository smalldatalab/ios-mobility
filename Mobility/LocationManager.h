//
//  LocationManager.h
//  Mobility
//
//  Created by Charles Forkish on 4/9/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocationManager : NSObject

+ (instancetype)sharedManager;

- (void)startTrackingLocation;
- (void)stopTrackingLocation;
- (void)sampleLocation;

@end
