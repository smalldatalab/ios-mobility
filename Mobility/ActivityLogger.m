//
//  ActivityLogger.m
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "ActivityLogger.h"

#import <CoreMotion/CoreMotion.h>

@interface ActivityLogger ()


@property (nonatomic, strong) CMMotionActivityManager *motionActivitiyManager;
@property (nonatomic, strong) NSMutableArray *activities;
@property (nonatomic, strong) NSMutableArray *privateDataPoints;


@end

@implementation ActivityLogger

+ (instancetype)sharedLogger
{
    static ActivityLogger *_sharedLogger = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLogger = [[self alloc] initPrivate];
    });
    
    return _sharedLogger;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[ActivityLogger sharedLogger]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        [self startLogging];
    }
    return self;
}

- (CMMotionActivityManager *)motionActivitiyManager
{
    if (_motionActivitiyManager == nil) {
        _motionActivitiyManager = [[CMMotionActivityManager alloc] init];
    }
    return _motionActivitiyManager;
}

- (NSMutableArray *)activities
{
    if (_activities == nil) {
        _activities = [NSMutableArray array];
    }
    return _activities;
}

- (NSMutableArray *)privateDataPoints
{
    if (_privateDataPoints == nil) {
        _privateDataPoints = [NSMutableArray array];
    }
    return _privateDataPoints;
}

- (NSArray *)dataPoints
{
    return self.privateDataPoints;
}


- (void)startLogging
{
    if ([CMMotionActivityManager isActivityAvailable]) {
        __weak typeof(self) weakSelf = self;
        [self.activities removeAllObjects];
        [self.motionActivitiyManager startActivityUpdatesToQueue:[NSOperationQueue mainQueue]
                                                     withHandler:^(CMMotionActivity *activity) {
                                                         [weakSelf logActivity:activity];
                                                     }];
    }
    else {
        NSLog(@"motion data not available on this device");
    }
}

- (BOOL)motionActivityHasActivity:(CMMotionActivity *)activity
{
    return (activity.stationary
            || activity.walking
            || activity.running
            || activity.automotive
            || activity.cycling
            || activity.unknown);
}

- (void)logActivity:(CMMotionActivity *)activity
{
//    NSLog(@"%s %@", __PRETTY_FUNCTION__, activity);
    if (![self motionActivityHasActivity:activity]) return;
    
    [self.activities insertObject:activity atIndex:0];
    
    MobilityDataPoint *dataPoint = [MobilityDataPoint dataPointWithMotionActivity:activity location:nil];
    if (dataPoint.body.activities.count == 0) {
        NSLog(@"no activities for motion activity: %@", activity);
    }
    [self.privateDataPoints insertObject:dataPoint atIndex:0];
    
    if (self.newDataPointBlock != nil) {
        self.newDataPointBlock(dataPoint);
    }
}


@end
