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

@interface ActivityLogger () <CLLocationManagerDelegate>

@property (nonatomic, strong) CMMotionActivityManager *motionActivitiyManager;
@property (nonatomic, strong) NSMutableArray *privateActivityDataPoints;
@property (nonatomic, strong) NSMutableArray *privateLocationDataPoints;
@property (strong) NSDate *lastLoggedActivityDate;

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, assign) BOOL backgroundMode;


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
    NSLog(@"archiving data points, activites: %d, locations: %d", (int)self.privateActivityDataPoints.count, (int)self.privateLocationDataPoints);
    NSData *encodedClient = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:encodedClient forKey:@"MobilityActivityLogger"];
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
    
    self.lastLoggedActivityDate = activity.startDate;
    
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
    
//    [[OMHClient sharedClient] submitDataPoint:dataPoint];
}

- (void)logActivities:(NSArray *)activities
{
    NSLog(@"LOG ACTIVITES: %d", (int)activities.count);
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
    
    NSLog(@"did update locations: %d", (int)locations.count);
//    for (CLLocation *location in locations) {
//        NSLog(@"%@", location);
//    }
    
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
    
    [self logLocations:locations];
    
    if (self.backgroundMode) {
        [self.locationManager allowDeferredLocationUpdatesUntilTraveled:CLLocationDistanceMax timeout:60.0];
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    if (error.code == kCLErrorDenied) {
        [self.locationManager stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager
didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusDenied)
    {
        // Location services are disabled on the device.
        [self.locationManager stopUpdatingLocation];
        
    }
    if (status == kCLAuthorizationStatusAuthorized)
    {
        // Location services have just been authorized on the device, start updating now.
        [self.locationManager startUpdatingLocation];
    }
}

- (void)logLocations:(NSArray *)locations
{
    NSLog(@"LOG LOCATIONS: %d", (int)locations.count);
    for (CLLocation *location in locations) {
        MobilityDataPoint *dataPoint = [MobilityDataPoint dataPointWithMotionActivity:nil location:location];
    
        NSLog(@"log location: %@", location);

        [self.privateLocationDataPoints insertObject:dataPoint atIndex:0];
        
        if (self.newLocationDataPointBlock != nil) {
            self.newLocationDataPointBlock(dataPoint);
        }
    }
    
    [self archiveDataPoints];
}

@end
