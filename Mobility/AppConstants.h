//
//  AppConstants.h
//  Mobility
//
//  Created by Charles Forkish on 1/13/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#ifndef Mobility_AppConstants_h
#define Mobility_AppConstants_h

/**
 *  DSU Sign-in keys
 */
extern NSString * const kMobilityGoogleClientID;
extern NSString * const kOMHServerGoogleClientID;
extern NSString * const kMobilityDSUClientID;
extern NSString * const kMobilityDSUClientSecret;

/**
 *  kLocationSamplingIntervalStationary
 *  Location sampling frequency while stationary
 *  - Once every five minutes
 */
extern int const kLocationSamplingIntervalStationary;

/**
 *  kLocationSamplingIntervalMoving
 *  Location sampling frequency while moving
 *  - Once every minute
 */
extern int const kLocationSamplingIntervalMoving;

/**
 *  kDataUploadInterval
 *  Minimum interval between successful data uploads
 *  - One hour
 */
extern int const kDataUploadInterval;

/**
 *  kDataUploadMaxBatchSize
 *  Maximum number of data points to submit to DSU at a time
 */
extern int const kDataUploadMaxBatchSize;


@interface AppConstants : NSObject
@end

#endif
