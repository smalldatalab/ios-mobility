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
@property (nonatomic, strong) NSMutableArray *privateDataPoints;
@property (strong) CMMotionActivity *lastLoggedActivity;

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
        self.privateDataPoints = [NSMutableArray array];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self != nil) {
        _privateDataPoints = [decoder decodeObjectForKey:@"logger.dataPoints"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.privateDataPoints forKey:@"logger.dataPoints"];
}

- (NSArray *)dataPoints
{
    return self.privateDataPoints;
}

- (void)archiveDataPoints
{
    NSLog(@"archiving data points, count: %d", (int)self.privateDataPoints.count);
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
    [self startLogging];
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
                                                         [weakSelf logActivity:activity
                                                                  withLocation:weakSelf.locationManager.location
                                                                      deferred:NO
                                                                     timestamp:[NSDate date]];
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

- (void)logActivity:(CMMotionActivity *)activity withLocation:(CLLocation *)location deferred:(BOOL)deferred timestamp:(NSDate *)timestamp
{
//    NSLog(@"%s %@", __PRETTY_FUNCTION__, activity);
    if (![self motionActivityHasActivity:activity]) return;
    
    self.lastLoggedActivity = activity;
    
    MobilityDataPoint *dataPoint = [MobilityDataPoint dataPointWithMotionActivity:activity location:location];
    NSString *defStr = deferred ? @"yes" : @"no";
    dataPoint[@"timestamp"] = timestamp;
    dataPoint[@"deferred"] = defStr;
    
    NSLog(@"log activity: %@ (%@), location: %@, deferred: %d", dataPoint.body.debugActivityString, dataPoint.body.debugActivityConfidence, location, deferred);
    
    if (dataPoint.body.activities.count == 0) {
        NSLog(@"no activities for motion activity: %@", activity);
    }
    [self.privateDataPoints insertObject:dataPoint atIndex:0];
    
    if (self.newDataPointBlock != nil) {
        self.newDataPointBlock(dataPoint);
    }
    
    [self archiveDataPoints];
    
//    [[OMHClient sharedClient] submitDataPoint:dataPoint];
}

- (CLLocation *)closestLocationToDate:(NSDate *)date fromLocations:(NSArray *)locations
{
    CLLocation *closest = locations.firstObject;
    NSTimeInterval dif = fabs([date timeIntervalSinceDate:closest.timestamp]);
    for (CLLocation *location in locations) {
        NSTimeInterval newDif = fabs([date timeIntervalSinceDate:location.timestamp]);
        if (newDif < dif) {
            dif = newDif;
            closest = location;
        }
    }
    return closest;
}

- (void)logActivities:(NSArray *)activities withLocations:(NSArray *)locations
{
//    NSLog(@"ACTIVITES: %d", (int)activities.count);
//    for (CMMotionActivity *activity in activities) {
//        NSLog(@"%@", activity);
//    }
//    NSLog(@"LOCATIONS: %d", (int)locations.count);
//    for (CLLocation *location in locations) {
//        NSLog(@"%@", location);
//    }
    
    for (CMMotionActivity *activity in activities) {
        NSComparisonResult comp = [activity.startDate compare:self.lastLoggedActivity.startDate];
        if (comp == NSOrderedAscending || comp == NSOrderedSame) continue;
        CLLocation *location = [self closestLocationToDate:activity.startDate fromLocations:locations];
        [self logActivity:activity withLocation:location deferred:YES timestamp:[NSDate date]];
    }
}

- (void)fetchActivitiesForLocations:(NSArray *)locations
{
    CLLocation *firstLocation = locations.firstObject;
    NSDate *startDate = [firstLocation.timestamp dateByAddingTimeInterval:-600];
//    NSLog(@"start date: %@, now: %@", startDate, [NSDate date]);
    __block NSArray *blockLocations = locations;
    __weak typeof(self) weakSelf = self;
    [self.motionActivitiyManager queryActivityStartingFromDate:startDate
                                                        toDate:[NSDate date]
                                                       toQueue:[NSOperationQueue mainQueue]
                                                   withHandler:^(NSArray *activities, NSError *error)
    {
        if (error) {
            NSLog(@"activity fetch error: %@", error);
        }
        else {
            [weakSelf logActivities:activities withLocations:blockLocations];
        }

    }];
}


#pragma mark - Location

- (CLLocationManager *)locationManager
{
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        [_locationManager setDistanceFilter:kCLDistanceFilterNone];
        [_locationManager setDelegate:self];
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
    [self fetchActivitiesForLocations:locations];
    
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

@end
