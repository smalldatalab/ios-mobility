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
@property (nonatomic, strong) NSMutableArray *privateLogEntries;


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

- (NSMutableArray *)privateLogEntries
{
    if (_privateLogEntries == nil) {
        _privateLogEntries = [NSMutableArray array];
    }
    return _privateLogEntries;
}

- (NSArray *)logEntries
{
    return self.privateLogEntries;
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

- (void)logActivity:(CMMotionActivity *)activity
{
    NSLog(@"%s %@", __PRETTY_FUNCTION__, activity);
    [self.activities insertObject:activity atIndex:0];
    
    MobilityLogEntry *logEntry = [[MobilityLogEntry alloc] init];
    [self.privateLogEntries insertObject:logEntry atIndex:0];
    
    if (self.newLogEntryBlock != nil) {
        self.newLogEntryBlock(logEntry);
    }
}


@end
