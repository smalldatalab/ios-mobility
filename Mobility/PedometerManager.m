//
//  StepCountManager.m
//  Mobility
//
//  Created by Charles Forkish on 4/7/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import "PedometerManager.h"
#import "NSDate+Additions.h"

#define QUERY_INTERVAL (5*60)

@import CoreMotion;

@interface PedometerManager ()

@property (nonatomic, strong) CMPedometer *pedometer;
@property (nonatomic, strong) NSDate *lastQueryDate;
@property (atomic, assign) int remainingQueries;

@end

@implementation PedometerManager

+ (instancetype)sharedManager
{
    static PedometerManager *_sharedManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSData *encodedClient = [defaults objectForKey:@"MobilityPedometerManager"];
        if (encodedClient != nil) {
            _sharedManager = (PedometerManager *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedClient];
        } else {
            _sharedManager = [[self alloc] initPrivate];
        }
    });
    
    return _sharedManager;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[PedometerManager sharedManager]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        self.lastQueryDate = [NSDate timeOfDayWithHours:0 minutes:0];
        NSLog(@"beginning of today: %@", self.lastQueryDate);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self != nil) {
        _lastQueryDate = [decoder decodeObjectForKey:@"lastQueryDate"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.lastQueryDate forKey:@"lastQueryDate"];
}

- (void)archive
{
    NSData *encodedManager = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:encodedManager forKey:@"MobilityPedometerManager"];
    [userDefaults synchronize];
}

- (CMPedometer *)pedometer
{
    if (_pedometer == nil) {
        _pedometer = [[CMPedometer alloc] init];
    }
    return _pedometer;
}

- (void)queryPedometer
{
    if (![CMPedometer isStepCountingAvailable]) return;
    if (self.remainingQueries > 0) return;
    
    NSTimeInterval totalQueryInterval = -[self.lastQueryDate timeIntervalSinceNow];
    int numQueries = totalQueryInterval / QUERY_INTERVAL;
    self.remainingQueries = numQueries;
    NSLog(@"query pedometer, count: %d", self.remainingQueries);
    
    for (int i = 0; i < numQueries; i++) {
        NSDate *startDate = [self.lastQueryDate dateByAddingTimeInterval:i*QUERY_INTERVAL];
        NSDate *endDate = [self.lastQueryDate dateByAddingTimeInterval:(i+1)*QUERY_INTERVAL];
        
        [self.pedometer queryPedometerDataFromDate:startDate toDate:endDate withHandler:^(CMPedometerData *pedometerData, NSError *error) {
            NSLog(@"pedData: %@, remQueries: %d, error: %@", pedometerData, self.remainingQueries, error);
            self.remainingQueries--;
        }];
    }
    
    self.lastQueryDate = [self.lastQueryDate dateByAddingTimeInterval:numQueries*QUERY_INTERVAL];
}



@end
