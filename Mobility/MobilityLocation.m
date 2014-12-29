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

@end
