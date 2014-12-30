//
//  MobilityLocation.m
//  Mobility
//
//  Created by Charles Forkish on 12/24/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "MobilityLocation.h"


@implementation MobilityLocation

@dynamic latitude;
@dynamic longitude;
@dynamic horizontalAccuracy;
@dynamic verticalAccuracy;
@dynamic altitude;
@dynamic bearing;
@dynamic speed;
@dynamic uuid;
@dynamic timestamp;

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    self.uuid = [[[NSUUID alloc] init] UUIDString];
}

- (MobilityLocationDictionary *)jsonDictionary
{
    MobilityLocationDictionary *location = [[MobilityLocationDictionary alloc] init];
    location.latitude = @(self.latitude);
    location.longitude = @(self.longitude);
    location.horizontalAccuracy = @(self.horizontalAccuracy);
    location.verticalAccuracy = @(self.verticalAccuracy);
    location.altitude = @(self.altitude);
    location.bearing = @(self.bearing);
    location.speed = @(self.speed);
    return [NSMutableDictionary dictionaryWithObject:location forKey:@"location"];
}

@end


#pragma mark - MobilityLocationDictionary

@implementation NSMutableDictionary (MobilityLocationDictionary)

- (void)setLatitude:(NSNumber *)latitude
{
    self[@"latitude"] = latitude;
}

- (NSNumber *)latitude
{
    return self[@"latitude"];
}

- (void)setLongitude:(NSNumber *)longitude
{
    self[@"longitude"] = longitude;
}

- (NSNumber *)longitude
{
    return self[@"longitude"];
}

- (void)setHorizontalAccuracy:(NSNumber *)accuracy
{
    self[@"horizontal_accuracy"] = accuracy;
}

- (NSNumber *)horizontalAccuracy
{
    return self[@"horizontal_accuracy"];
}

- (void)setVerticalAccuracy:(NSNumber *)accuracy
{
    self[@"vertical_accuracy"] = accuracy;
}

- (NSNumber *)verticalAccuracy
{
    return self[@"vertical_accuracy"];
}

- (void)setAltitude:(NSNumber *)altitude
{
    self[@"altitude"] = altitude;
}

- (NSNumber *)altitude
{
    return self[@"altitude"];
}

- (void)setBearing:(NSNumber *)bearing
{
    self[@"bearing"] = bearing;
}

- (NSNumber *)bearing
{
    return self[@"bearing"];
}

- (void)setSpeed:(NSNumber *)speed
{
    self[@"speed"] = speed;
}

- (NSNumber *)speed
{
    return self[@"speed"];
}

@end
