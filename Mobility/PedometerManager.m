//
//  StepCountManager.m
//  Mobility
//
//  Created by Charles Forkish on 4/7/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import "PedometerManager.h"
#import "MobilityModel.h"
#import "NSDate+Additions.h"

#define QUERY_INTERVAL (5*60)

@import CoreMotion;

@interface PedometerManager ()

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
@property (nonatomic, strong) CMPedometer *pedometer;
#else
@property (nonatomic, strong) CMStepCounter *stepCounter;
#endif

@property (nonatomic, strong) NSDate *lastQueryDate;
@property (atomic, assign) int remainingQueries;

@property (nonatomic, weak) MobilityModel *model;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

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

- (NSOperationQueue *)operationQueue
{
    if (_operationQueue == nil) {
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    return _operationQueue;
}


#pragma mark - iOS 8+
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

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
    
    [self backgroundQuery];
}

- (void)backgroundQuery
{
    NSTimeInterval totalQueryInterval = -[self.lastQueryDate timeIntervalSinceNow];
    int numQueries = totalQueryInterval / QUERY_INTERVAL;
    self.remainingQueries = numQueries;
    NSLog(@"query pedometer, count: %d", self.remainingQueries);
    
    for (int i = 0; i < numQueries; i++) {
        NSDate *startDate = [self.lastQueryDate dateByAddingTimeInterval:i*QUERY_INTERVAL];
        NSDate *endDate = [self.lastQueryDate dateByAddingTimeInterval:(i+1)*QUERY_INTERVAL];
        
        [self.pedometer queryPedometerDataFromDate:startDate toDate:endDate withHandler:^(CMPedometerData *pedometerData, NSError *error) {
            self.remainingQueries--;
            NSLog(@"pedData: %@, remQueries: %d, error: %@", pedometerData, self.remainingQueries, error);
            [self.managedObjectContext performBlock:^{
                if (error == nil && [pedometerData.numberOfSteps intValue] > 0) {
                    [self logPedometerData:pedometerData];
                    //                [self performSelectorOnMainThread:@selector(logPedometerData:) withObject:pedometerData waitUntilDone:NO];
                }
                if (self.remainingQueries == 0) {
                    [self archive];
                    [self.managedObjectContext save:nil];
                    [self.model saveManagedContext];
                    //                [self.model performSelectorOnMainThread:@selector(saveManagedContext) withObject:nil waitUntilDone:NO];
                }
            }];
        }];
    }
    
    self.lastQueryDate = [self.lastQueryDate dateByAddingTimeInterval:numQueries*QUERY_INTERVAL];
}

- (void)logPedometerData:(CMPedometerData *)pd
{
    [self.model uniquePedometerDataWithCMPedometerData:pd moc:self.managedObjectContext];
}


#pragma mark - iOS 7
#else

- (CMStepCounter *)stepCounter
{
    if (_stepCounter == nil) {
        _stepCounter = [[CMStepCounter alloc] init];
    }
    return _stepCounter;
}

- (void)queryPedometer
{
    if (![CMStepCounter isStepCountingAvailable]) return;
    if (self.remainingQueries > 0) return;
    
    [self backgroundQuery];
}

- (void)backgroundQuery
{
    NSTimeInterval totalQueryInterval = -[self.lastQueryDate timeIntervalSinceNow];
    int numQueries = totalQueryInterval / QUERY_INTERVAL;
    self.remainingQueries = numQueries;
    NSLog(@"query step counter, count: %d", self.remainingQueries);
    
    for (int i = 0; i < numQueries; i++) {
        __block NSDate *startDate = [self.lastQueryDate dateByAddingTimeInterval:i*QUERY_INTERVAL];
        __block NSDate *endDate = [self.lastQueryDate dateByAddingTimeInterval:(i+1)*QUERY_INTERVAL];
        
        [self.stepCounter queryStepCountStartingFrom:startDate to:endDate toQueue:self.operationQueue withHandler:^(NSInteger numberOfSteps, NSError *error) {
            self.remainingQueries--;
            NSLog(@"numberOfSteps: %d, remQueries: %d, error: %@", (int)numberOfSteps, self.remainingQueries, error);
            
            [self.managedObjectContext performBlock:^{
                if (error == nil && numberOfSteps > 0) {
                    [self.model uniquePedometerDataWithStepCount:numberOfSteps startDate:startDate endDate:endDate moc:self.managedObjectContext];
                }
                if (self.remainingQueries == 0) {
                    [self archive];
                    [self.managedObjectContext save:nil];
                    [self.model saveManagedContext];
                }
                
            }];
        }];
    }
    
    self.lastQueryDate = [self.lastQueryDate dateByAddingTimeInterval:numQueries*QUERY_INTERVAL];
}

#endif



@end
