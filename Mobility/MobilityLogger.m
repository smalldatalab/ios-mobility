//
//  ActivityLogger.m
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "MobilityLogger.h"
#import "OMHClient.h"
#import "MobilityModel.h"
#import "AppConstants.h"
#import "PedometerManager.h"
#import "ActivityManager.h"
#import "LocationManager.h"

#import "NotificationManager.h"

@import CoreLocation;
@import CoreMotion;


@interface MobilityLogger () <OMHReachabilityDelegate, OMHUploadDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSTimer *uploadTimer;
@property (nonatomic, strong) NSTimer *uploadBatchTimer;
@property (nonatomic, strong) NSTimer *locationSampleTimer;

@property (nonatomic, strong) NSDate *lastUploadDate;

@property (nonatomic, weak) MobilityModel *model;
@property (nonatomic, weak) PedometerManager *pedometerManager;
@property (nonatomic, weak) ActivityManager *activityManager;
@property (nonatomic, weak) LocationManager *locationManager;


@end

@implementation MobilityLogger

+ (instancetype)sharedLogger
{
    static MobilityLogger *_sharedLogger = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSData *encodedClient = [defaults objectForKey:@"MobilityLogger"];
        if (encodedClient != nil) {
            _sharedLogger = (MobilityLogger *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedClient];
        } else {
            _sharedLogger = [[self alloc] initPrivate];
        }
    });
    
    return _sharedLogger;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[MobilityLogger sharedLogger]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        self.lastUploadDate = [NSDate date];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self != nil) {
        _lastUploadDate = [decoder decodeObjectForKey:@"logger.lastUploadDate"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.lastUploadDate forKey:@"logger.lastUploadDate"];
}


- (void)archiveDataPoints
{
    NSData *encodedClient = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:encodedClient forKey:@"MobilityLogger"];
    [userDefaults synchronize];
    
    [self.model saveManagedContext];
}

- (MobilityModel *)model
{
    if (_model == nil) {
        _model = [MobilityModel sharedModel];
    }
    return _model;
}

- (PedometerManager *)pedometerManager
{
    if (_pedometerManager == nil) {
        _pedometerManager = [PedometerManager sharedManager];
    }
    return _pedometerManager;
}

- (ActivityManager *)activityManager
{
    if (_activityManager == nil) {
        _activityManager = [ActivityManager sharedManager];
    }
    return _activityManager;
}

- (LocationManager *)locationManager
{
    if (_locationManager == nil) {
        _locationManager = [LocationManager sharedManager];
    }
    return _locationManager;
}

- (void)startLogging
{
    if (![OMHClient sharedClient].isSignedIn) return;
    
    if (![NotificationManager hasNotificationPermissions]) {
        [NotificationManager requestNotificationPermissions];
    }
    
    [self.locationManager startTrackingLocation];
    [self startUploadTimer];
    [self.pedometerManager queryPedometer];
    [self.activityManager queryActivities];
    [self locationSampleTimerFired];
    
    [OMHClient sharedClient].reachabilityDelegate = self;
    [OMHClient sharedClient].uploadDelegate = self;
}

- (void)stopLogging
{
    [self.locationManager stopTrackingLocation];
    [self.activityManager stopLogging];
    [self stopUploadTimer];
    [self stopLocationSampleTimer];
}

- (void)enteredBackground
{
    [self.activityManager stopLogging];
    [self archiveDataPoints];
    [self uploadData];
}

- (void)enteredForeground
{
    if (![OMHClient sharedClient].isSignedIn) return;
    [self.activityManager startLogging];
}

- (void)startUploadTimer
{
    [self stopUploadTimer];
    
    self.uploadTimer = [NSTimer scheduledTimerWithTimeInterval:kDataUploadInterval target:self selector:@selector(uploadData) userInfo:nil repeats:YES];
}

- (void)stopUploadTimer
{
    if (self.uploadTimer != nil) {
        [self.uploadTimer invalidate];
        self.uploadTimer = nil;
    }
}

- (void)startLocationSampleTimerWithCurrentActivity:(CMMotionActivity *)currentActivity
{
    NSLog(@"%s, isMainThread: %d", __PRETTY_FUNCTION__, [NSThread isMainThread]);
    [self stopLocationSampleTimer];
    
    [self.model logMessage:[NSString stringWithFormat:@"starting timer, still: %d", [self motionActivityIsStationary:currentActivity]]];
    
    NSTimeInterval interval = [self motionActivityIsStationary:currentActivity]
    ? kLocationSamplingIntervalStationary
    : kLocationSamplingIntervalMoving;
    
    self.locationSampleTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(locationSampleTimerFired) userInfo:nil repeats:NO];
    [NotificationManager scheduleResumeNotificationWithFireDate:[[NSDate date] dateByAddingTimeInterval:interval + 30]];
}

- (void)stopLocationSampleTimer
{
    if (self.locationSampleTimer != nil) {
        [self.locationSampleTimer invalidate];
        self.locationSampleTimer = nil;
    }
}

- (void)locationSampleTimerFired
{
    [self.locationManager sampleLocation];
    [self.activityManager getCurrentActivityWithCompletionBlock:^(CMMotionActivity *currentActivity) {
        [self performSelectorOnMainThread:@selector(startLocationSampleTimerWithCurrentActivity:) withObject:currentActivity waitUntilDone:NO];
//        [self startLocationSampleTimerWithCurrentActivity:currentActivity];
    }];
}

- (void)uploadData
{
//    NSLog(@"upload data, should upload: %d, reachable: %d", [self shouldUpload], [OMHClient sharedClient].isReachable);
    [self.model logMessage:[NSString stringWithFormat:@"should upload: %d, reachable: %d", [self shouldUpload], [OMHClient sharedClient].isReachable]];
    if ([self shouldUpload]) {
        [self.activityManager queryActivities];
        [self.pedometerManager queryPedometer];
        [self uploadPendingData];
    }
}

- (BOOL)shouldUpload
{
    NSLog(@"should upload, active: %d, pending: %d, interval: %g", ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground), [OMHClient sharedClient].pendingDataPointCount, [[NSDate date] timeIntervalSinceDate:self.lastUploadDate]/60);
    if ([OMHClient sharedClient].pendingDataPointCount >= kDataUploadMaxBatchSize) return NO;
    else if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) return YES;
    else if (self.lastUploadDate == nil) return YES;
    else return ([[NSDate date] timeIntervalSinceDate:self.lastUploadDate] > kDataUploadInterval);
}

- (void)uploadPendingData
{
    OMHClient *client = [OMHClient sharedClient];
    if (!client.isReachable) return;
    
    [self.uploadBatchTimer invalidate];
    self.uploadBatchTimer = nil;
    
    NSArray *pendingDataPointEntities = [self.model oldestPendingDataPointEntitiesWithLimit:kDataUploadMaxBatchSize];
    NSLog(@"uploading data points: %@", [@(pendingDataPointEntities.count) stringValue]);
    
    for (MobilityDataPointEntity *entity in pendingDataPointEntities) {
        MobilityDataPoint *dataPoint = [MobilityDataPoint dataPointWithEntity:entity];
        [client submitDataPoint:dataPoint];
        entity.submitted = YES;
    }
    
    [self.model logMessage:[NSString stringWithFormat:@"uploading data points: %d, q=%d", (int)pendingDataPointEntities.count, self.activityManager.isQueryingActivities]];
    
    if (pendingDataPointEntities.count == kDataUploadMaxBatchSize
        || self.activityManager.isQueryingActivities
        || self.pedometerManager.isQueryingPedometer) {
        NSLog(@"starting timer for next batch");
        self.uploadBatchTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(uploadData) userInfo:nil repeats:NO];
    }
    else {
        // only update upload date if we're done uploading all batches
        self.lastUploadDate = [NSDate date];
    }
    
    [self archiveDataPoints];
}

- (BOOL)motionActivityIsStationary:(CMMotionActivity *)activity
{
    if ([activity respondsToSelector:@selector(cycling)]) {
        BOOL hasCycling = (BOOL)[activity performSelector:@selector(cycling)];
        if (hasCycling) return NO;
    }
    
    if (activity.walking
        || activity.running
        || activity.automotive
        || activity.unknown) {
        return NO;
    }
    
    return activity.stationary;
}

- (void)OMHClient:(OMHClient *)client reachabilityStatusChanged:(BOOL)isReachable
{
    [self.model logMessage:[NSString stringWithFormat:@"reachability changed: %d", isReachable]];
    if (isReachable) {
        [self uploadData];
    }
}

- (void)OMHClient:(OMHClient *)client didUploadDataPoint:(NSDictionary *)dataPoint
{
    [self.model markUploadCompleteForDataPointWithUUID:((MobilityDataPoint *)dataPoint).header.headerID];
}



@end
