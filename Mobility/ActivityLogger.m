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

#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

#define STILL_TIMER_INTERVAL (2*60)
#define MOVING_TIMER_INTERVAL 60

@interface ActivityLogger () <CLLocationManagerDelegate>

@property (nonatomic, strong) CMMotionActivityManager *motionActivitiyManager;
@property (nonatomic, strong) NSMutableArray *logEntries;
//@property (nonatomic, strong) NSMutableArray *privateLocationDataPoints;
@property (nonatomic, strong) NSDate *lastLoggedActivityDate;
@property (nonatomic, strong) CMMotionActivity *lastKnownActivity;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) CLLocationAccuracy bestAccuracy;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (nonatomic, strong) NSDate *locationTrackingStartDate;
@property (nonatomic, strong) NSDate *stillMotionStartDate;
@property (nonatomic, strong) NSTimer *stillTimer;

@property (nonatomic, weak) MobilityModel *model;


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
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self != nil) {
        _logEntries = [decoder decodeObjectForKey:@"logger.logEntries"];
        _lastLoggedActivityDate = [decoder decodeObjectForKey:@"logger.lastLoggedActivityDate"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.logEntries forKey:@"logger.logEntries"];
    [encoder encodeObject:self.lastLoggedActivityDate forKey:@"logger.lastLoggedActivityDate"];
}

- (void)logMessage:(NSString *)message
{
    NSDictionary *logEntry = @{@"time" : [self formattedDate:[NSDate date]],
                               @"message" : message};
    [self.logEntries insertObject:logEntry atIndex:0];
    if (self.newLogEntryBlock) {
        self.newLogEntryBlock(logEntry);
    }
}

- (void)archiveDataPoints
{
//    NSLog(@"archiving data points, activites: %d, locations: %d", (int)self.privateActivityDataPoints.count, (int)self.privateLocationDataPoints.count);
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

- (NSMutableArray *)logEntries
{
    if (_logEntries == nil) {
        _logEntries = [NSMutableArray array];
    }
    return _logEntries;
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
    NSLog(@"start logging");
    self.bestAccuracy = CLLocationDistanceMax;
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
    
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.locationManager performSelector:@selector(requestAlwaysAuthorization)];
        }
    }
    [self.locationManager startUpdatingLocation];
}

- (void)stopLogging
{
    NSLog(@"stop logging");
    [self.motionActivitiyManager stopActivityUpdates];
    [self.locationManager stopUpdatingLocation];
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

- (void)logActivity:(CMMotionActivity *)cmActivity
{
    MobilityActivity * activity = [self.model uniqueActivityWithMotionActivity:cmActivity];
    MobilityDataPoint *dataPoint = [MobilityDataPoint dataPointWithActivity:activity];
    
    [[OMHClient sharedClient] submitDataPoint:dataPoint];
    [self archiveDataPoints];
    
    self.lastLoggedActivityDate = cmActivity.startDate;
    if ([self motionActivityHasKnownActivity:cmActivity]) {
        self.lastKnownActivity = cmActivity;
        [self updateLocationManagerAccuracy];
    }
    
}


#pragma mark - Location

- (CLLocationManager *)locationManager
{
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest]; //kCLLocationAccuracyNearestTenMeters
        [_locationManager setDistanceFilter:kCLDistanceFilterNone];
        [_locationManager setDelegate:self];
    }
    return _locationManager;
}

- (void)updateLocationManagerAccuracy
{
    if ([self motionActivityIsStationary:self.lastKnownActivity]) {
        if (self.stillMotionStartDate == nil) {
            self.stillMotionStartDate = [NSDate date];
            [self startStillTimer];
        }
        if (self.lastLocation != nil && self.lastLocation.horizontalAccuracy < self.bestAccuracy) {
            self.bestAccuracy = self.lastLocation.horizontalAccuracy;
        }
        if ([self shouldReduceAccuracy]) {
            [self reduceLocationTracking];
        }
    }
    else {
        [self resumeLocationTracking];
    }
}

- (void)startStillTimer
{
    self.stillTimer = [NSTimer scheduledTimerWithTimeInterval:120 target:self selector:@selector(reduceLocationTracking) userInfo:nil repeats:NO];
}

- (void)stopStillTimer
{
    [self.stillTimer invalidate];
    self.stillTimer = nil;
}

- (void)resumeLocationTracking
{
    NSLog(@"turning up location accuracy");
    [self logMessage:@"increasing accuracy"];
    self.stillMotionStartDate = nil;
    [self stopStillTimer];
    self.bestAccuracy = CLLocationDistanceMax;
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
    [self.locationManager setDistanceFilter:5.0];
}

- (void)reduceLocationTracking
{
    NSLog(@"turning down location accuracy");
    [self logMessage:@"reducing accuracy"];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyThreeKilometers];
    [self.locationManager setDistanceFilter:CLLocationDistanceMax];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    NSLog(@"did update locations");
    [self logLocations:locations];
    [self updateLocationManagerAccuracy];
    
    if (!self.lastLoggedActivityDate) {
        CLLocation *firstLocation = locations.firstObject;
        self.lastLoggedActivityDate = firstLocation.timestamp;
    }

}

- (void)logLocations:(NSArray *)locations
{
//    NSLog(@"LOG LOCATIONS: %d", (int)locations.count);
    for (CLLocation *location in locations) {
        
        if ([self isDuplicateLocation:location]) continue;
        
        self.lastLocation = location;
        
        MobilityLocation *mobilityLocation = [self.model uniqueLocationWithCLLocation:location];
        MobilityDataPoint *dataPoint = [MobilityDataPoint dataPointWithLocation:mobilityLocation];
        
        [[OMHClient sharedClient] submitDataPoint:dataPoint];
        [self archiveDataPoints];
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
// * elapsed time > 120s -> YES
// otherwise NO
- (BOOL)shouldReduceAccuracy
{
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:self.stillMotionStartDate];
    NSLog(@"should reduce, interval: %f, accuracy: %f", interval, self.bestAccuracy);
    [self logMessage:[NSString stringWithFormat:@"reduce? acc:%g, int:%.1f", self.bestAccuracy, interval]];
    if (self.bestAccuracy <= 5) return YES;
    else if (self.bestAccuracy <= 10 && interval > 10) return YES;
    else if (self.bestAccuracy <= 100 && interval > 30) return YES;
    else if (self.bestAccuracy <= 500 && interval > 60) return YES;
    else if (interval > 120) return YES;
    else return NO;
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
        if ([OMHClient sharedClient].isSignedIn) {
            [self.locationManager startUpdatingLocation];
        }
    }
}

@end
