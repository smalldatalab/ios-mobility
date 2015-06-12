//
//  MobilityDataPointEntity.m
//  Mobility
//
//  Created by Charles Forkish on 6/7/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import "MobilityDataPointEntity.h"


@implementation MobilityDataPointEntity

@dynamic timestamp;
@dynamic submitted;
@dynamic userEmail;
@dynamic uuid;
@dynamic uploaded;

@dynamic jsonDictionary;


- (void)awakeFromInsert
{
    [super awakeFromInsert];
    self.uuid = [[[NSUUID alloc] init] UUIDString];
}

@end
