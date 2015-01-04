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
//@property (nonatomic, strong) NSMutableArray *privateActivityDataPoints;
//@property (nonatomic, strong) NSMutableArray *privateLocationDataPoints;
//@property (nonatomic, strong) NSDate *lastLoggedActivityDate;
//@property (nonatomic, strong) MobilityDataPoint *lastLoggedActivityDataPoint;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) CLLocationAccuracy bestAccuracy;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (nonatomic, strong) NSDate *locationTrackingStartDate;

@property (nonatomic, assign) BOOL backgroundMode;
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic, strong) NSTimer *backgroundTimer;

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
//        self.privateActivityDataPoints = [NSMutableArray array];
//        self.privateLocationDataPoints = [NSMutableArray array];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self != nil) {
//        _privateActivityDataPoints = [decoder decodeObjectForKey:@"logger.activityDataPoints"];
//        _privateLocationDataPoints = [decoder decodeObjectForKey:@"logger.locationDataPoints"];
//        _lastLoggedActivityDate = [decoder decodeObjectForKey:@"logger.lastLoggedActivityDate"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
//    [encoder encodeObject:self.privateActivityDataPoints forKey:@"logger.activityDataPoints"];
//    [encoder encodeObject:self.privateLocationDataPoints forKey:@"logger.locationDataPoints"];
//    [encoder encodeObject:self.lastLoggedActivityDate forKey:@"logger.lastLoggedActivityDate"];
}

//- (NSArray *)activityDataPoints
//{
//    return self.privateActivityDataPoints;
//}
//
//- (NSArray *)locationDataPoints
//{
//    return self.privateLocationDataPoints;
//}

- (void)archiveDataPoints
{
//    NSLog(@"archiving data points, activites: %d, locations: %d", (int)self.privateActivityDataPoints.count, (int)self.privateLocationDataPoints.count);
    NSData *encodedClient = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:encodedClient forKey:@"MobilityActivityLogger"];
    [userDefaults synchronize];
    
    [self.model saveManagedContext];
}

- (void)enterBackgroundMode
{
    NSLog(@"enter background mode");
    self.backgroundMode = YES;
//    [self stopLogging];
}

- (MobilityModel *)model
{
    if (_model == nil) {
        _model = [MobilityModel sharedModel];
    }
    return _model;
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
    
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.locationManager performSelector:@selector(requestAlwaysAuthorization)];
        }
    }
    [self.locationManager startUpdatingLocation];
}

- (void)stopLogging
{
    [self.motionActivitiyManager stopActivityUpdates];
    [self.locationManager stopUpdatingLocation];
}

- (BOOL)motionActivityHasActivity:(CMMotionActivity *)activity
{
    if ([activity respondsToSelector:@selector(cycling)]) {
        BOOL hasCycling = [activity performSelector:@selector(cycling)];
        if (hasCycling) return YES;
    }
    
    return (activity.stationary
            || activity.walking
            || activity.running
            || activity.automotive
            || activity.unknown);
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

- (void)logActivity:(CMMotionActivity *)cmActivity
{
    if (![self motionActivityHasActivity:cmActivity]) return;
    
    MobilityActivity * activity = [self.model uniqueActivityWithMotionActivity:cmActivity];
    MobilityDataPoint *dataPoint = [MobilityDataPoint dataPointWithActivity:activity];
    
    [[OMHClient sharedClient] submitDataPoint:dataPoint];
    [self archiveDataPoints];
    
    [self updateLocationManagerForActivity:activity];
}


#pragma mark - Location

- (CLLocationManager *)locationManager
{
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters]; //kCLLocationAccuracyNearestTenMeters
        [_locationManager setDistanceFilter:1.0];
        [_locationManager setDelegate:self];
    }
    return _locationManager;
}

- (void)updateLocationManagerForActivity:(MobilityActivity *)activity
{
    // if activity is only stationary, turn down location accuracy
    if (activity.activitiesArray.count == 1 && activity.stationary) {
        NSLog(@"turning down location accuracy");
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
        [self.locationManager setDistanceFilter:10.0];
    }
    else {
        NSLog(@"turning up location accuracy");
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        [self.locationManager setDistanceFilter:1.0];
    }
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    NSLog(@"heading: %@", self.locationManager.heading);
    [self logLocations:locations];
    
    if (self.backgroundTask != UIBackgroundTaskInvalid) {
        
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
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

- (void)logLocations:(NSArray *)locations
{
//    NSLog(@"LOG LOCATIONS: %d", (int)locations.count);
    for (CLLocation *location in locations) {
        
        if ([self isDuplicateLocation:location]) continue;
        
        self.lastLocation = location;
        
        NSLog(@"log location: %@", location);
        if ((self.bestAccuracy == 0) || location.horizontalAccuracy < self.bestAccuracy) {
            self.bestAccuracy = location.horizontalAccuracy;
        }
        
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
