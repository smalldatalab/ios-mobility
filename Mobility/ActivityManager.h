//
//  ActivityManager.h
//  Mobility
//
//  Created by Charles Forkish on 4/9/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CMMotionActivity;

@interface ActivityManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, readonly) BOOL isQueryingActivities;

- (void)startLogging;
- (void)stopLogging;
- (void)queryActivities;
- (void)getCurrentActivityWithCompletionBlock:(void (^)(CMMotionActivity *currentActivity))completionBlock;
@end
