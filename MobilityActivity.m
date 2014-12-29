//
//  MobilityActivity.m
//  Mobility
//
//  Created by Charles Forkish on 12/24/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "MobilityActivity.h"


@implementation MobilityActivity

@dynamic activityType;
@dynamic confidence;
@dynamic uuid;
@dynamic timestamp;

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    self.uuid = [[[NSUUID alloc] init] UUIDString];
}

@end
