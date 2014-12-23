//
//  ActivityLogger.m
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "ActivityLogger.h"
#import "OMHClient.h"
//#import "LocationManager.h"

#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

#define STILL_TIMER_INTERVAL (7*60)
#define MOVING_TIMER_INTERVAL 60

@interface ActivityLogger () <CLLocationManagerDelegate>

@property (nonatomic, strong) CMMotionActivityManager *motionActivitiyManager;
@property (nonatomic, strong) NSMutableArray *privateActivityDataPoints;
@property (nonatomic, strong) NSMutableArray *privateLocationDataPoints;
@property (nonatomic, strong) NSDate *lastLoggedActivityDate;
@property (nonatomic, strong) MobilityDataPoint *lastLoggedActivityDataPoint;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) CLLocationAccuracy bestAccuracy;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (nonatomic, strong) NSDate *locationTrackingStartDate;

@property (nonatomic, assign) BOOL backgroundMode;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic, strong) NSTimer *backgroundTimer;


@end

@implementation ActivityLogger

+ (instancetype)sharedLogger
{
    static ActivityLogger *_sharedLogger = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSData *encodedClient = [defaults objectForKey:@"MobilityActivityLogger2"];
        if (encodedClient != nil) {
            _sharedLogger = (ActivityLogger *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedClient];
        } else {
            _sharedLogger = [[self alloc] initPrivate];
        }
        
//        [_sharedLogger startLogging];
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
        self.privateActivityDataPoints = [NSMutableArray array];
        self.privateLocationDataPoints = [NSMutableArray array];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self != nil) {
        _privateActivityDataPoints = [decoder decodeObjectForKey:@"logger.activityDataPoints"];
        _privateLocationDataPoints = [decoder decodeObjectForKey:@"logger.locationDataPoints"];
        _lastLoggedActivityDate = [decoder decodeObjectForKey:@"logger.lastLoggedActivityDate"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.privateActivityDataPoints forKey:@"logger.activityDataPoints"];
    [encoder encodeObject:self.privateLocationDataPoints forKey:@"logger.locationDataPoints"];
    [encoder encodeObject:self.lastLoggedActivityDate forKey:@"logger.lastLoggedActivityDate"];
}

- (NSArray *)activityDataPoints
{
    return self.privateActivityDataPoints;
}

- (NSArray *)locationDataPoints
{
    return self.privateLocationDataPoints;
}

- (void)archiveDataPoints
{
    NSLog(@"archiving data points, activites: %d, locations: %d", (int)self.privateActivityDataPoints.count, (int)self.privateLocationDataPoints.count);
    NSData *encodedClient = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:encodedClient forKey:@"MobilityActivityLogger2"];
    [userDefaults synchronize];
}

- (void)enterBackgroundMode
{
    NSLog(@"enter background mode");
    self.backgroundMode = YES;
//    [self stopLogging];
}

- (void)exitBackgroundMode
{
    NSLog(@"exit background mode");
    self.backgroundMode = NO;
    [self.locationManager disallowDeferredLocationUpdates];
//    [self startLogging];
}

#pragma mark - Motion Activity

- (CMMotionActivityManager *)motionActivitiyManager
{
    if (_motionActivitiyManager == nil) {
        _motionActivitiyManager = [[CMMotionActivityManager alloc] init];
    }
    return _motionActivitiyManager;
}

- (void)startLogging
{
    if ([CMMotionActivityManager isActivityAvailable]) {
        __weak typeof(self) weakSelf = self;
        [self.motionActivitiyManager startActivityUpdatesToQueue:[NSOperationQueue mainQueue]
                                                     withHandler:^(CMMotionActivity *activity) {
                                                         [weakSelf logActivity:activity];
                                                     }];
    }
    else {
        NSLog(@"motion data not available on this device");
    }
}

- (void)stopLogging
{
    [self.motionActivitiyManager stopActivityUpdates];
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
//    if (![self motionActivityHasActivity:activity]) return;
    
    
    MobilityDataPoint *dataPoint = [MobilityDataPoint dataPointWithMotionActivity:activity location:nil];
    
    NSLog(@"log activity: %@ (%@)", dataPoint.body.debugActivityString, dataPoint.body.debugActivityConfidence);
    
    if (dataPoint.body.activities.count == 0) {
        NSLog(@"no activities for motion activity: %@", activity);
    }
    [self.privateActivityDataPoints insertObject:dataPoint atIndex:0];
    
    if (self.newActivityDataPointBlock != nil) {
        self.newActivityDataPointBlock(dataPoint);
    }
    
    [self archiveDataPoints];
    
    
    self.lastLoggedActivityDate = activity.startDate;
    self.lastLoggedActivityDataPoint = dataPoint;
    
//    [[OMHClient sharedClient] submitDataPoint:dataPoint];
}

- (void)logActivities:(NSArray *)activities
{
    NSLog(@"LOG ACTIVITES: %d, bestAccuracy: %f", (int)activities.count, self.bestAccuracy);
//    for (CMMotionActivity *activity in activities) {
//        NSLog(@"%@", activity);
//    }
//    NSLog(@"LOCATIONS: %d", (int)locations.count);
//    for (CLLocation *location in locations) {
//        NSLog(@"%@", location);
//    }
    
    for (CMMotionActivity *activity in activities) {
        if (self.lastLoggedActivityDate) {
            NSComparisonResult comp = [activity.startDate compare:self.lastLoggedActivityDate];
            if (comp == NSOrderedAscending || comp == NSOrderedSame) continue;
        }
        
        [self logActivity:activity];
    }
    
    if ([self shouldScheduleNextUpdate]) {
        [self scheduleNextLocationUpdate];
    }
}


#pragma mark - Location

- (CLLocationManager *)locationManager
{
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        [_locationManager setDistanceFilter:kCLDistanceFilterNone];
        [_locationManager setDelegate:self];
        
        if ( [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
            [_locationManager requestAlwaysAuthorization];
        }
    }
    return _locationManager;
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
//    //Filter out inaccurate points
//    CLLocation *lastLocation = [locations lastObject];
//    if(lastLocation.horizontalAccuracy < 0)
//    {
//        return;
//    }
    
//    NSLog(@"did update locations: %d", (int)locations.count);
    
    if (self.backgroundTask != UIBackgroundTaskInvalid) {

        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
    
    [self logLocations:locations];
    
//    NSLog(@"background time: %f", [UIApplication sharedApplication].backgroundTimeRemaining);
    
    if (!self.lastLoggedActivityDate) {
        CLLocation *firstLocation = locations.firstObject;
        self.lastLoggedActivityDate = firstLocation.timestamp;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.motionActivitiyManager queryActivityStartingFromDate:self.lastLoggedActivityDate
                                                        toDate:[NSDate date]
                                                       toQueue:[NSOperationQueue mainQueue]
                                                   withHandler:^(NSArray *activities, NSError *error)
     {
         if (error) {
             NSLog(@"activity fetch error: %@", error);
         }
         else {
             [weakSelf logActivities:activities];
         }
         
     }];
    
//    if (self.backgroundMode) {
//        [self.locationManager allowDeferredLocationUpdatesUntilTraveled:CLLocationDistanceMax timeout:60.0*60.0];
//    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    NSLog(@"location manager did fail with error: %@", error);
    if (error.code == kCLErrorDenied) {
        [self.locationManager stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager
didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"location manager did change auth status: %d", status);
    
    if (status == kCLAuthorizationStatusDenied)
    {
        // Location services are disabled on the device.
        [self.locationManager stopUpdatingLocation];
        
    }
    if (status == kCLAuthorizationStatusAuthorized)
    {
        // Location services have just been authorized on the device, start updating now.
        [self resumeLocationTracking];
    }
}

- (void)resumeLocationTracking
{
    NSLog(@"ending background task");
    
    [self.backgroundTimer invalidate];
    self.backgroundTimer = nil;
    
    self.locationTrackingStartDate = [NSDate date];
    [self.locationManager startUpdatingLocation];
    [self startLogging];
}

- (void)scheduleNextLocationUpdate
{
    MobilityDataPoint *dataPoint = self.lastLoggedActivityDataPoint;
    NSLog(@"schedule next update for activity: %@", dataPoint.body.debugActivityString);
    
    [self.locationManager stopUpdatingLocation];
    [self stopLogging];
    self.bestAccuracy = 0;
    self.locationTrackingStartDate = nil;
    
    NSTimeInterval interval = MOVING_TIMER_INTERVAL;
    
    // use still interval if still is the only activity type
    if (dataPoint.body.activities.count == 1) {
        MobilityActivity *activity = dataPoint.body.activities.firstObject;
        if (activity.activityType == MobilityActivityTypeStill) {
            interval = STILL_TIMER_INTERVAL;
        }
    }
    
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self resumeLocationTracking];
    }];
    
    self.backgroundTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                            target:self
                                                          selector:@selector(resumeLocationTracking)
                                                          userInfo:nil
                                                           repeats:NO];
}

- (void)logLocations:(NSArray *)locations
{
    NSLog(@"LOG LOCATIONS: %d", (int)locations.count);
    for (CLLocation *location in locations) {
        
        if ([self isDuplicateLocation:location]) continue;
        
        self.lastLocation = location;
        
        NSLog(@"log location with accuracy: %f", location.horizontalAccuracy);
        if ((self.bestAccuracy == 0) || location.horizontalAccuracy < self.bestAccuracy) {
            self.bestAccuracy = location.horizontalAccuracy;
        }
        
        MobilityDataPoint *dataPoint = [MobilityDataPoint dataPointWithMotionActivity:nil location:location];

        [self.privateLocationDataPoints insertObject:dataPoint atIndex:0];
        
        if (self.newLocationDataPointBlock != nil) {
            self.newLocationDataPointBlock(dataPoint);
        }
    }
    
    [self archiveDataPoints];
}

- (BOOL)isDuplicateLocation:(CLLocation *)location
{
    if (location.coordinate.latitude != self.lastLocation.coordinate.latitude) return NO;
    if (location.coordinate.longitude != self.lastLocation.coordinate.longitude) return NO;
    if (location.horizontalAccuracy < self.lastLocation.horizontalAccuracy) return NO;
    return YES;
}

// conditions:
// * accuracy <= 5m -> YES
// * accuracy <= 10m && elapsed time > 10s -> YES
// * accuracy <= 100m && elapsed time > 30s -> YES
// * accuracy <= 500m && elapsed time > 60s -> YES
// otherwise NO
- (BOOL)shouldScheduleNextUpdate
{
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:self.locationTrackingStartDate];
    NSLog(@"should schedule, interval: %f, accuracy: %f", interval, self.bestAccuracy);
    if (self.bestAccuracy <= 5) return YES;
    else if (self.bestAccuracy <= 10 && interval > 10) return YES;
    else if (self.bestAccuracy <= 100 && interval > 30) return YES;
    else if (self.bestAccuracy <= 500 && interval > 60) return YES;
    else return NO;
}

@end
