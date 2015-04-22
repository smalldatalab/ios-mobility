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

@import CoreLocation;
@import CoreMotion;


@interface MobilityLogger () <OMHReachabilityDelegate>

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
    
    [self.locationManager startTrackingLocation];
    [self startUploadTimer];
    [self.pedometerManager queryPedometer];
    [self.activityManager queryActivities];
    [self locationSampleTimerFired];
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
    [self stopLocationSampleTimer];
    
    [self.model logMessage:[NSString stringWithFormat:@"starting timer, still: %d", [self motionActivityIsStationary:currentActivity]]];
    
    NSTimeInterval interval = [self motionActivityIsStationary:currentActivity]
    ? kLocationSamplingIntervalStationary
    : kLocationSamplingIntervalMoving;
    
    self.locationSampleTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(locationSampleTimerFired) userInfo:nil repeats:NO];
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
        [self startLocationSampleTimerWithCurrentActivity:currentActivity];
    }];
}

- (void)uploadData
{
    NSLog(@"upload data, should upload: %d, reachable: %d", [self shouldUpload], [OMHClient sharedClient].isReachable);
    if ([self shouldUpload]) {
        [self.activityManager queryActivities];
        [self.pedometerManager queryPedometer];
        [self uploadPendingData];
    }
}

- (BOOL)shouldUpload
{
    NSLog(@"should upload, active: %d, pending: %d, interval: %g", ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground), [OMHClient sharedClient].pendingDataPointCount, [[NSDate date] timeIntervalSinceDate:self.lastUploadDate]/60);
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) return NO;
    else if ([OMHClient sharedClient].pendingDataPointCount >= kDataUploadMaxBatchSize) return NO;
    else if (self.lastUploadDate == nil) return YES;
    else return ([[NSDate date] timeIntervalSinceDate:self.lastUploadDate] > kDataUploadInterval);
}

- (void)uploadPendingData
{
    if (![OMHClient sharedClient].isReachable) return;
    
    [self.uploadBatchTimer invalidate];
    self.uploadBatchTimer = nil;
    
    int batchSize = kDataUploadMaxBatchSize / 3;
    
    NSArray *pendingActivities = [self.model oldestPendingActivitiesWithLimit:batchSize];
    NSArray *pendingLocations = [self.model oldestPendingLocationsWithLimit:batchSize];
    NSArray *pendingPedometerData = [self.model oldestPendingPedometerDataWithLimit:batchSize];
    NSLog(@"uploading data A=%d, L=%d, P=%d", (int)pendingActivities.count, (int)pendingLocations.count, (int)pendingPedometerData.count);
    
    
    for (MobilityActivity *activity in pendingActivities) {
//        NSLog(@"submitting activity with timestamp: %@", activity.timestamp);
        MobilityDataPoint *dataPoint = [MobilityDataPoint dataPointWithActivity:activity];
        [[OMHClient sharedClient] submitDataPoint:dataPoint];
        activity.submitted = YES;
    }
    
    for (MobilityLocation *location in pendingLocations) {
//        NSLog(@"submitting location with timestamp: %@", location.timestamp);
        MobilityDataPoint *dataPoint = [MobilityDataPoint dataPointWithLocation:location];
        [[OMHClient sharedClient] submitDataPoint:dataPoint];
        location.submitted = YES;
    }
    
    for (MobilityPedometerData *pd in pendingPedometerData) {
        MobilityDataPoint *dataPoint = [MobilityDataPoint dataPointWithPedometerData:pd];
        [[OMHClient sharedClient] submitDataPoint:dataPoint];
        pd.submitted = YES;
    }
    
    NSLog(@"done uploading");
    
    [self.model logMessage:[NSString stringWithFormat:@"uploading A=%d, L=%d, P=%d, q=%d", (int)pendingActivities.count, (int)pendingLocations.count, (int)pendingPedometerData.count, self.activityManager.isQueryingActivities]];
    
    if (pendingActivities.count == batchSize
        || pendingLocations.count == batchSize
        || pendingPedometerData.count == batchSize
        || self.activityManager.isQueryingActivities
        || self.pedometerManager.isQueryingPedometer) {
        NSLog(@"starting timer for next batch"); // TODO: store this timer so can invalidate
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


@end
