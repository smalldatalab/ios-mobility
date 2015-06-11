//
//  AppConstants.m
//  Mobility
//
//  Created by Charles Forkish on 1/13/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import "AppConstants.h"


NSString * const kMobilityDSUClientID = @"org.openmhealth.ios.mobility";
NSString * const kMobilityDSUClientSecret = @"Rtg43jkLD7z76c";

int const kLocationSamplingIntervalStationary = 60 * 5;
int const kLocationSamplingIntervalMoving = 60 * 1;
int const kDataUploadInterval = 60 * 20;
int const kDataUploadMaxBatchSize = 300;

@implementation AppConstants

@end
