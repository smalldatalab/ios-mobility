//
//  ActivityManager.m
//  Mobility
//
//  Created by Charles Forkish on 4/9/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import "ActivityManager.h"
#import "MobilityModel.h"

@import CoreMotion;

@interface ActivityManager ()

@property (nonatomic, strong) CMMotionActivityManager *motionActivitiyManager;
@property (nonatomic, strong) NSDate *lastQueriedActivityDate;
@property (nonatomic, strong) NSDate *stillMotionStartDate;
@property (nonatomic, assign) BOOL isQueryingActivities;
@property (nonatomic, assign) BOOL isLoggingActivities;
@property (nonatomic, copy) void (^activitySampleCompletionBlock)(CMMotionActivity *currentActivity);

@property (nonatomic, weak) MobilityModel *model;



@end

@implementation ActivityManager

+ (instancetype)sharedManager
{
    static ActivityManager *_sharedManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSData *encodedClient = [defaults objectForKey:@"MobilityActivityManager"];
        if (encodedClient != nil) {
            _sharedManager = (ActivityManager *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedClient];
        } else {
            _sharedManager = [[self alloc] initPrivate];
        }
    });
    
    return _sharedManager;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[ActivityManager sharedManager]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        self.lastQueriedActivityDate = [NSDate timeOfDayWithHours:0 minutes:0];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self != nil) {
        _lastQueriedActivityDate = [decoder decodeObjectForKey:@"lastQueriedActivityDate"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.lastQueriedActivityDate forKey:@"lastQueriedActivityDate"];
}

- (void)archive
{
    NSData *encodedClient = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:encodedClient forKey:@"MobilityActivityManager"];
    [userDefaults synchronize];
}

- (MobilityModel *)model
{
    if (_model == nil) {
        _model = [MobilityModel sharedModel];
    }
    return _model;
}

- (CMMotionActivityManager *)motionActivitiyManager
{
    if (_motionActivitiyManager == nil) {
        _motionActivitiyManager = [[CMMotionActivityManager alloc] init];
    }
    return _motionActivitiyManager;
}

- (void)startLogging
{
    self.isLoggingActivities = YES;
    [self startUpdatingActivities];
}

- (void)stopLogging
{
    self.isLoggingActivities = NO;
    [self stopUpdatingActivities];
}

- (void)queryActivities
{
    [self.model logMessage:@"query activities"];
    self.isQueryingActivities = YES;
    __weak typeof(self) weakSelf = self;
    [self.motionActivitiyManager queryActivityStartingFromDate:self.lastQueriedActivityDate
                                                        toDate:[NSDate date]
                                                       toQueue:[NSOperationQueue mainQueue]
                                                   withHandler:^(NSArray *activities, NSError *error)
     {
         if (error) {
             NSLog(@"activity fetch error: %@", error);
         }
         else {
             for (CMMotionActivity *activity in activities) {
                 [weakSelf logActivity:activity];
             }
             if (activities.count > 0 ){
                 CMMotionActivity *lastQueriedActivity = activities.lastObject;
                 self.lastQueriedActivityDate = lastQueriedActivity.startDate;
             }
         }
         self.isQueryingActivities = NO;
         
     }];
}

- (void)getCurrentActivityWithCompletionBlock:(void (^)(CMMotionActivity *))completionBlock
{
    self.activitySampleCompletionBlock = completionBlock;
    if (!self.isLoggingActivities) {
        [self startUpdatingActivities];
    }
}

- (void)startUpdatingActivities
{
    NSLog(@"start updating activities");
    if ([CMMotionActivityManager isActivityAvailable]) {
        __weak typeof(self) weakSelf = self;
        [self.motionActivitiyManager startActivityUpdatesToQueue:[NSOperationQueue mainQueue]
                                                     withHandler:^(CMMotionActivity *activity) {
                                                         [weakSelf activityUpdateHandler:activity];
                                                     }];
    }
    else {
        NSLog(@"motion data not available on this device");
    }
}

- (void)stopUpdatingActivities
{
    NSLog(@"stop updating activities");
    [self.motionActivitiyManager stopActivityUpdates];
}

- (void)activityUpdateHandler:(CMMotionActivity *)cmActivity
{
    if ([self motionActivityHasKnownActivity:cmActivity]) {
        if (self.activitySampleCompletionBlock != nil) {
            self.activitySampleCompletionBlock(cmActivity);
            self.activitySampleCompletionBlock = nil;
        }
        if (!self.isLoggingActivities) {
            [self stopUpdatingActivities];
        }
    }
    [self logActivity:cmActivity];
}

- (void)logActivity:(CMMotionActivity *)cmActivity
{
    [self.model uniqueActivityWithMotionActivity:cmActivity];
}

- (BOOL)motionActivityHasKnownActivity:(CMMotionActivity *)activity
{
    if ([activity respondsToSelector:@selector(cycling)]) {
        BOOL hasCycling = (BOOL)[activity performSelector:@selector(cycling)];
        if (hasCycling) return YES;
    }
    
    return (activity.stationary
            || activity.walking
            || activity.running
            || activity.automotive);
}


@end