//
//  ActivityLogger.m
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "ActivityLogger.h"
#import "OMHClient.h"
#import "MobilityModel.h"
#import "AppConstants.h"
#import "PedometerManager.h"

#import <CoreLocation/CoreLocation.h>
@import CoreMotion;


@interface ActivityLogger () <CLLocationManagerDelegate>

@property (nonatomic, strong) CMMotionActivityManager *motionActivitiyManager;
@property (nonatomic, strong) CMMotionActivity *lastActivityUpdate;
@property (nonatomic, strong) NSDate *lastQueriedActivityDate;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) CLLocationAccuracy bestAccuracy;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (nonatomic, strong) NSDate *stillMotionStartDate;
@property (nonatomic, strong) NSTimer *stillTimer;

@property (nonatomic, strong) NSTimer *locationSampleTimer;

@property (nonatomic, strong) NSDate *lastUploadDate;
@property (nonatomic, assign) BOOL isQueryingActivities;

@property (nonatomic, weak) MobilityModel *model;
@property (nonatomic, weak) PedometerManager *pedometerManager;


@end

@implementation ActivityLogger

+ (instancetype)sharedLogger
{
    static ActivityLogger *_sharedLogger = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSData *encodedClient = [defaults objectForKey:@"MobilityActivityLogger"];
        if (encodedClient != nil) {
            _sharedLogger = (ActivityLogger *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedClient];
        } else {
            _sharedLogger = [[self alloc] initPrivate];
        }
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
        self.lastQueriedActivityDate = self.lastUploadDate = [NSDate date];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self != nil) {
        _lastQueriedActivityDate = [decoder decodeObjectForKey:@"logger.lastQueriedActivityDate"];
        if (_lastQueriedActivityDate == nil) _lastQueriedActivityDate = [NSDate date];
        _lastUploadDate = [decoder decodeObjectForKey:@"logger.lastUploadDate"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.lastQueriedActivityDate forKey:@"logger.lastQueriedActivityDate"];
    [encoder encodeObject:self.lastUploadDate forKey:@"logger.lastUploadDate"];
}


- (void)archiveDataPoints
{
    NSData *encodedClient = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:encodedClient forKey:@"MobilityActivityLogger"];
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

- (void)startLogging
{
    [self startTrackingLocation];
    
    //test
    [self.pedometerManager queryPedometer];
}

- (void)stopLogging
{
    [self stopTrackingLocation];
}

- (void)enteredBackground
{
    [self.pedometerManager stopLogging];
    [self deferredDataUpload];
}

- (void)enteredForeground
{
    [self.pedometerManager startLogging];
}


- (BOOL)shouldUpload
{
    NSLog(@"should upload, active: %d, pending: %d, interval: %g", ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground), [OMHClient sharedClient].pendingDataPointCount, [[NSDate date] timeIntervalSinceDate:self.lastUploadDate]/60);
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) return NO;
    else if ([OMHClient sharedClient].pendingDataPointCount > kDataUploadMaxBatchSize) return NO;
    else if (self.lastUploadDate == nil) return YES;
    else return ([[NSDate date] timeIntervalSinceDate:self.lastUploadDate] > kDataUploadInterval);
}

- (void)deferredDataUpload
{
    NSLog(@"deferred data upload, should upload: %d, reachable: %d", [self shouldUpload], [OMHClient sharedClient].isReachable);
    if ([self shouldUpload] && [OMHClient sharedClient].isReachable) {
        [self queryActivities];
        [self.pedometerManager queryPedometer];
        [self uploadPendingData];
    }
}

- (void)uploadPendingData
{
    
    NSArray *pendingActivities = [[MobilityModel sharedModel] oldestPendingActivitiesWithLimit:kDataUploadMaxBatchSize / 2];
    NSArray *pendingLocations = [[MobilityModel sharedModel] oldestPendingLocationsWithLimit:kDataUploadMaxBatchSize / 2];
    NSLog(@"uploading data A=%d, L=%d", (int)pendingActivities.count, (int)pendingLocations.count);
    
    
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
    
    NSLog(@"done uploading");
    
    [self.model logMessage:[NSString stringWithFormat:@"uploading data A=%d, L=%d", (int)pendingActivities.count, (int)pendingLocations.count]];
    
    if (pendingActivities.count == kDataUploadMaxBatchSize / 2
        || pendingLocations.count == kDataUploadMaxBatchSize / 2
        || self.isQueryingActivities
        || self.pedometerManager.isQueryingPedometer) {
        NSLog(@"starting timer for next batch");
        [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(deferredDataUpload) userInfo:nil repeats:NO];
    }
    else {
        // only update upload date if we're done uploading all batches
        self.lastUploadDate = [NSDate date];
    }
}

#pragma mark - Motion Activity

- (CMMotionActivityManager *)motionActivitiyManager
{
    if (_motionActivitiyManager == nil) {
        _motionActivitiyManager = [[CMMotionActivityManager alloc] init];
    }
    return _motionActivitiyManager;
}

- (void)startUpdatingActivities
{
    NSLog(@"start updating activities");
    self.bestAccuracy = CLLocationDistanceMax;
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


// debug
- (NSString *)formattedDate:(NSDate *)date
{
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"MMMM d h:m:s" options:0
                                                                  locale:[NSLocale currentLocale]];
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:formatString];
    }
    
    return [dateFormatter stringFromDate:date];
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

- (void)activityUpdateHandler:(CMMotionActivity *)cmActivity
{
    if ([self motionActivityHasKnownActivity:cmActivity]) {
        
        self.lastActivityUpdate = cmActivity;
        [self stopUpdatingActivities];
        [self endLocationSample];
    }
    [self logActivity:cmActivity];
}

- (void)logActivity:(CMMotionActivity *)cmActivity
{
    [self.model uniqueActivityWithMotionActivity:cmActivity];
    [self archiveDataPoints];
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



#pragma mark - Location

- (CLLocationManager *)locationManager
{
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        [_locationManager setDistanceFilter:kCLDistanceFilterNone];
        [_locationManager setDelegate:self];
    }
    return _locationManager;
}

- (void)startTrackingLocation
{
    [self.model logMessage:@"start tracking location"];
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.locationManager performSelector:@selector(requestAlwaysAuthorization)];
        }
    }
    
    [self.locationManager startUpdatingLocation];
}

- (void)stopTrackingLocation
{
    [self.model logMessage:@"stop tracking location!!"];
    [self.locationManager stopUpdatingLocation];
    [self stopLocationSampleTimer];
}

- (void)startLocationSample
{
    [self stopLocationSampleTimer];
    [self.model logMessage:@"starting location sample"];
    self.bestAccuracy = CLLocationDistanceMax;
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [self.locationManager setDistanceFilter:kCLDistanceFilterNone];
}

- (void)endLocationSample
{
    [self.model logMessage:[NSString stringWithFormat:@"ending location sample, still: %d", [self motionActivityIsStationary:self.lastActivityUpdate]]];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyThreeKilometers];
    [self.locationManager setDistanceFilter:CLLocationDistanceMax];
    [self startLocationSampleTimer];
}

- (void)startLocationSampleTimer
{
    if (self.locationSampleTimer != nil) {
        [self stopLocationSampleTimer];
    }
    
    NSTimeInterval interval = [self motionActivityIsStationary:self.lastActivityUpdate]
    ? kLocationSamplingIntervalStationary
    : kLocationSamplingIntervalMoving;
    
    self.locationSampleTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(startLocationSample) userInfo:nil repeats:NO];
}

- (void)stopLocationSampleTimer
{
    [self.locationSampleTimer invalidate];
    self.locationSampleTimer = nil;
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    NSLog(@"did update locations");
    [self logLocations:locations];
    
    if (self.locationSampleTimer == nil) {
        [self startUpdatingActivities];
    }

}

- (void)logLocations:(NSArray *)locations
{
//    NSLog(@"LOG LOCATIONS: %d", (int)locations.count);
    for (CLLocation *location in locations) {
        
        if ([self isDuplicateLocation:location]) continue;
        
        self.lastLocation = location;
        [self.model uniqueLocationWithCLLocation:location];
    }
    
    [self archiveDataPoints];
    [self deferredDataUpload];
}

- (BOOL)isDuplicateLocation:(CLLocation *)location
{
    if (location.coordinate.latitude != self.lastLocation.coordinate.latitude) return NO;
    if (location.coordinate.longitude != self.lastLocation.coordinate.longitude) return NO;
    if (location.horizontalAccuracy < self.lastLocation.horizontalAccuracy) return NO;
    return YES;
}


- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    NSLog(@"location manager did fail with error: %@", error);
    [self.model logMessage:[NSString stringWithFormat:@"location failed with error: %ld", (long)error.code]];
    if (error.code == kCLErrorDenied) {
        [self stopTrackingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager
didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"location manager did change auth status: %d", status);
    [self.model logMessage:[NSString stringWithFormat:@"location auth changed: %d", status]];
    
    if (status == kCLAuthorizationStatusDenied)
    {
        // Location services are disabled on the device.
        [self stopTrackingLocation];
        
    }
    if (status == kCLAuthorizationStatusAuthorized)
    {
        // Location services have just been authorized on the device, start updating now.
        if ([OMHClient sharedClient].isSignedIn) {
            [self startTrackingLocation];
        }
    }
}

@end
