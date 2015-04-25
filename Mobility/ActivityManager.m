//
//  ActivityManager.m
//  Mobility
//
//  Created by Charles Forkish on 4/9/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import "ActivityManager.h"
#import "MobilityModel.h"

#define QUERY_INTERVAL (60*10)

@import CoreMotion;

@interface ActivityManager ()

@property (nonatomic, strong) CMMotionActivityManager *motionActivitiyManager;
@property (nonatomic, strong) NSDate *lastQueriedActivityDate;
@property (nonatomic, strong) NSDate *lastQueryDate;
@property (atomic, assign) BOOL isQueryingActivities;
@property (atomic, assign) BOOL isLoggingActivities;
@property (nonatomic, copy) void (^activitySampleCompletionBlock)(CMMotionActivity *currentActivity);

@property (nonatomic, weak) MobilityModel *model;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSOperationQueue *operationQueue;



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

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext == nil) {
        _managedObjectContext = [self.model newChildMOC];
    }
    return _managedObjectContext;
}

- (NSOperationQueue *)operationQueue
{
    if (_operationQueue == nil) {
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    return _operationQueue;
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
    NSLog(@"query activities, isQuerying: %d, interval: %f", self.isQueryingActivities, -[self.lastQueryDate timeIntervalSinceNow]);
    if (self.isQueryingActivities ||
        (self.lastQueryDate && -[self.lastQueryDate timeIntervalSinceNow] < QUERY_INTERVAL))
        return;
    
    self.lastQueryDate = [NSDate date];
    
    [self.model logMessage:[NSString stringWithFormat:@"query activities from: %@", [self.lastQueriedActivityDate formattedDate]]];
    self.isQueryingActivities = YES;
    __weak typeof(self) weakSelf = self;
    
    [self.managedObjectContext performBlock:^{
        [self.motionActivitiyManager queryActivityStartingFromDate:self.lastQueriedActivityDate
                                                            toDate:[NSDate date]
                                                           toQueue:self.operationQueue
                                                       withHandler:^(NSArray *activities, NSError *error)
         {
             if (error) {
                 NSLog(@"activity fetch error: %@", error);
             }
             else {
                 for (CMMotionActivity *activity in activities) {
//                     [weakSelf logActivity:activity];
                     
                     [weakSelf.model insertActivityWithMotionActivity:activity moc:weakSelf.managedObjectContext];
                 }
                 if (activities.count > 0 ){
                     [self removeDuplicateActivities];
                     CMMotionActivity *lastQueriedActivity = activities.lastObject;
                     self.lastQueriedActivityDate = lastQueriedActivity.startDate;
                 }
             }
             self.isQueryingActivities = NO;
             [self save];
             NSLog(@"done querying activities, count: %@", [@(activities.count) stringValue]);
             
         }];
    }];
}

- (void)removeDuplicateActivities
{
    NSArray *activities = [self.model activitiesSinceDate:self.lastQueriedActivityDate moc:self.managedObjectContext];
    NSLog(@"remove duplicate activites, inRange count: %@", [@(activities.count) stringValue]);
    
    NSMutableSet *timestamps = [NSMutableSet set];
//    NSMutableArray *duplicates = [NSMutableArray array];
    for (MobilityActivity *activity in activities) {
        if ([timestamps containsObject:activity.timestamp]) {
            NSLog(@"deleting duplicate activity for date: %@", activity.timestamp);
            [self.managedObjectContext deleteObject:activity];
        }
        else {
            [timestamps addObject:activity.timestamp];
        }
    }
    
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
        [self.managedObjectContext performBlock:^{
            [self.motionActivitiyManager startActivityUpdatesToQueue:self.operationQueue
                                                         withHandler:^(CMMotionActivity *activity) {
                                                             [weakSelf activityUpdateHandler:activity];
                                                         }];
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
//    [self logActivity:cmActivity];
    
    [self.model insertActivityWithMotionActivity:cmActivity moc:self.managedObjectContext];
    [self save];
}

//- (void)logActivity:(CMMotionActivity *)cmActivity
//{
//    [self.model uniqueActivityWithMotionActivity:cmActivity moc:self.managedObjectContext];
//    if (self.isLoggingActivities) {
//        [self save];
//    }
//}

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

- (void)save
{
    [self archive];
    
    NSError *error = nil;
    [self.managedObjectContext save:&error];
    if (error != nil) {
        NSLog(@"error saving activites: %@", [error debugDescription]);
    }
    else {
        [self.model saveManagedContext];
    }
}


@end
