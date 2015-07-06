//
//  AppConstants.m
//  Mobility
//
//  Created by Charles Forkish on 1/13/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import "AppConstants.h"


//NSString * const kMobilityGoogleClientID = @"48636836762-bt7sitfa4fk4h41i0rsq0tf9jdc9qrud.apps.googleusercontent.com";
NSString * const kMobilityDSUClientID = @"org.openmhealth.ios.mobility";
NSString * const kMobilityDSUClientSecret = @"Rtg43jkLD7z76c";

int const kLocationSamplingIntervalStationary = 60 * 5;
int const kLocationSamplingIntervalMoving = 60 * 1;
int const kDataUploadInterval = 60 * 20;
int const kDataUploadMaxBatchSize = 300;

@implementation AppConstants

+ (NSString *)mobilityGoogleClientID
{
    NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
    if ([bundleID isEqualToString:@"io.smalldatalab.mobility"]) {
        return @"48636836762-bt7sitfa4fk4h41i0rsq0tf9jdc9qrud.apps.googleusercontent.com";
    }
    else if ([bundleID isEqualToString:@"io.smalldatalab.mobility-internal"]) {
        return @"48636836762-161sklbqsnmg2lmilg5v66m79m46cegr.apps.googleusercontent.com";
    }
    
    return nil;
}

@end
