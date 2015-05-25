//
//  LocationManager.m
//  Mobility
//
//  Created by Charles Forkish on 4/9/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import "LocationManager.h"
#import "MobilityModel.h"
#import "OMHClient.h"

#import "NotificationManager.h"

@import CoreLocation;

@interface LocationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) CLLocationAccuracy bestAccuracy;
@property (nonatomic, strong) CLLocation *lastLocation;

@property (nonatomic, weak) MobilityModel *model;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation LocationManager

+ (instancetype)sharedManager
{
    static LocationManager *_sharedManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] initPrivate];
    });
    
    return _sharedManager;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[LocationManager sharedManager]"
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
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined
        || ![CLLocationManager locationServicesEnabled]) {
        
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.locationManager performSelector:@selector(requestAlwaysAuthorization)];
        }
    }
    
    [self.locationManager startUpdatingLocation];
    [self.locationManager startMonitoringSignificantLocationChanges];
}

- (void)stopTrackingLocation
{
    [self.model logMessage:@"stop tracking location!!"];
    [self.locationManager stopUpdatingLocation];
}

- (void)sampleLocation
{
    [self startLocationSample];
}

- (void)startLocationSample
{
    [self.model logMessage:@"starting location sample"];
    self.bestAccuracy = CLLocationDistanceMax;
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [self.locationManager setDistanceFilter:kCLDistanceFilterNone];
}

- (void)endLocationSample
{
    if (self.locationManager.desiredAccuracy == kCLLocationAccuracyThreeKilometers) return;
    
    [self.model logMessage:@"ending location sample"];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyThreeKilometers];
    [self.locationManager setDistanceFilter:CLLocationDistanceMax];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    NSLog(@"did update locations");
    [self logLocations:locations];
    
    [self endLocationSample];
    
}

- (void)logLocations:(NSArray *)locations
{
    //    NSLog(@"LOG LOCATIONS: %d", (int)locations.count);
    [self.managedObjectContext performBlock:^{
        for (CLLocation *location in locations) {
            
            if ([self isDuplicateLocation:location]) continue;
            
            self.lastLocation = location;
            [self.model uniqueLocationWithCLLocation:location moc:self.managedObjectContext];
        }
        
        [self.managedObjectContext save:nil];
        [self.model saveManagedContext];
    }];
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
//        [self stopTrackingLocation];
        
//        [NotificationManager presentNotification:@"location status denied"];
        [NotificationManager presentSettingsNotification];
        
    }
    if ([self statusIsAuthorized:status])
    {
        // Location services have just been authorized on the device, start updating now.
        if ([OMHClient sharedClient].isSignedIn) {
            [self startTrackingLocation];
        }
        
        [NotificationManager presentNotification:@"location status authorized"];
    }
}

- (BOOL)statusIsAuthorized:(CLAuthorizationStatus)status
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        return YES;
    }
#endif
    
    return (status == kCLAuthorizationStatusAuthorized);
}


@end
