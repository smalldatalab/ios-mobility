//
//  MobilityModel.m
//  Mobility
//
//  Created by Charles Forkish on 12/24/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "MobilityModel.h"
#import <CoreData/CoreData.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#import "OMHClient.h"

@interface MobilityModel ()

@property(nonatomic, strong) NSURL *persistentStoreURL;
@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property(nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, copy) NSString *userEmail;

@end

@implementation MobilityModel

+ (instancetype)sharedModel
{
    static MobilityModel *_sharedModel = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedModel = [[self alloc] initPrivate];
    });
    
    return _sharedModel;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[MobilityModel sharedModel]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        
        // fetch logged-in user
        NSString *userEmail = [self persistentStoreMetadataTextForKey:@"userEmail"];
        NSLog(@"model setup with userEmail: %@", userEmail);
        if (userEmail != nil) {
            _userEmail = [userEmail copy];
        }
    }
    return self;
}

- (void)logMessage:(NSString *)message
{
#ifdef LOG_TABLE
    NSLog(@"logging message: %@", message);
    [self.managedObjectContext performBlock:^{
        DebugLogEntry *entry = (DebugLogEntry *)[self insertNewObjectForEntityForName:@"DebugLogEntry" moc:self.managedObjectContext];
        entry.timestamp = [NSDate date];
        entry.text = message;
    }];
#endif
}

- (void)saveState
{
    NSLog(@"saving model state");
    [self saveManagedContext];
    
    NSData *encodedClient = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:encodedClient forKey:@"MobilityModel"];
    [userDefaults synchronize];
}

- (void)setUserEmail:(NSString *)userEmail
{
    _userEmail = [userEmail copy];
    [self setPersistentStoreMetadataText:userEmail forKey:@"userEmail"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kMobilityModelUserChangedNotification object:self];
}


#pragma mark - Property Accessors (Core Data)

/**
 *  persistentStoreURL
 */
- (NSURL *)persistentStoreURL {
    if (_persistentStoreURL == nil) {
        NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = [documentDirectories firstObject];
        NSString *path = [documentDirectory stringByAppendingPathComponent:@"MobilityModel.data"];
        _persistentStoreURL = [NSURL fileURLWithPath:path];
    }
    
    return _persistentStoreURL;
}

/**
 *  managedObjectContext
 */
- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext == nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setUndoManager:nil];
        [_managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    }
    
    return _managedObjectContext;
}

/**
 *  managedObjectModel
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel == nil) {
        _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    
    return _managedObjectModel;
}

/**
 *  persistentStoreCoordinator
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator == nil) {
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.persistentStoreURL options:nil error:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            NSLog(@"Error opening persistent store, deleting persistent store\n%@\n%@", error, [error userInfo]);
            [self deletePersistentStore];
            [[OMHClient sharedClient] signOut];
            _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
            if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.persistentStoreURL options:nil error:&error]) {
                NSLog(@"Error opening persistent store after reset. abort.");
                abort();
            }
            
        }
    }
    
    return _persistentStoreCoordinator;
}

- (NSString *)persistentStoreMetadataTextForKey:(NSString *)key
{
    NSPersistentStore *store = [self.persistentStoreCoordinator persistentStoreForURL:self.persistentStoreURL];
    NSDictionary *metadata = [self.persistentStoreCoordinator metadataForPersistentStore:store];
    return metadata[key];
}

- (void)setPersistentStoreMetadataText:(NSString *)text forKey:(NSString *)key
{
    NSPersistentStore *store = [self.persistentStoreCoordinator persistentStoreForURL:self.persistentStoreURL];
    NSMutableDictionary *metadata = [[self.persistentStoreCoordinator metadataForPersistentStore:store] mutableCopy];
    if (text) {
        metadata[key] = text;
    }
    else {
        [metadata removeObjectForKey:key];
    }
    [self.persistentStoreCoordinator setMetadata:metadata forPersistentStore:store];
}


#pragma mark - Model

//- (MobilityActivity *)uniqueActivityWithMotionActivity:(CMMotionActivity *)motionActivity moc:(NSManagedObjectContext *)moc
- (MobilityActivity *)insertActivityWithMotionActivity:(CMMotionActivity *)motionActivity moc:(NSManagedObjectContext *)moc
{
    assert(self.userEmail != nil);
//    MobilityActivity *existingActivity = (MobilityActivity *)[self fetchObjectWithEntityName:@"MobilityActivity" uniqueTimestamp:motionActivity.startDate moc:moc];
//    if (existingActivity) return existingActivity;
    
    MobilityActivity *newActivity = (MobilityActivity *)[self insertNewObjectForEntityForName:@"MobilityActivity" moc:moc];
    newActivity.userEmail = self.userEmail;
    newActivity.timestamp = motionActivity.startDate;
    newActivity.confidence = motionActivity.confidence;
    newActivity.stationary = motionActivity.stationary;
    newActivity.walking = motionActivity.walking;
    newActivity.running = motionActivity.running;
    newActivity.automotive = motionActivity.automotive;
    if ([motionActivity respondsToSelector:@selector(cycling)]) {
        newActivity.cycling = (BOOL)[motionActivity performSelector:@selector(cycling)];
    }
    newActivity.unknown = motionActivity.unknown;
    
    return newActivity;
}

- (MobilityLocation *)uniqueLocationWithCLLocation:(CLLocation *)clLocation moc:(NSManagedObjectContext *)moc
{
    assert(self.userEmail != nil);
    MobilityLocation *existingLocation = (MobilityLocation *)[self fetchObjectWithEntityName:@"MobilityLocation" uniqueTimestamp:clLocation.timestamp moc:moc];
    if (existingLocation) return existingLocation;
    
    MobilityLocation *newLocation = (MobilityLocation *)[self insertNewObjectForEntityForName:@"MobilityLocation" moc:moc];
    newLocation.userEmail = self.userEmail;
    newLocation.timestamp = clLocation.timestamp;
    newLocation.latitude = clLocation.coordinate.latitude;
    newLocation.longitude = clLocation.coordinate.longitude;
    newLocation.altitude = clLocation.altitude;
    newLocation.bearing = clLocation.course;
    newLocation.speed = clLocation.speed;
    newLocation.horizontalAccuracy = clLocation.horizontalAccuracy;
    newLocation.verticalAccuracy = clLocation.verticalAccuracy;
    
    return newLocation;
}

- (MobilityPedometerData *)uniquePedometerDataWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate moc:(NSManagedObjectContext *)moc
{
    assert(self.userEmail != nil);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"startDate == %@ && endDate == %@ && userEmail == %@",
                              startDate, endDate, self.userEmail];
    MobilityPedometerData *existingPD = (MobilityPedometerData *)[self fetchObjectWithEntityName:@"MobilityPedometerData" uniquePredicate:predicate moc:moc];
    if (existingPD) return existingPD;
    
    MobilityPedometerData *newPD = (MobilityPedometerData *)[self insertNewObjectForEntityForName:@"MobilityPedometerData" moc:moc];
    newPD.userEmail = self.userEmail;
    newPD.startDate = startDate;
    newPD.endDate = endDate;
    
    return newPD;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (MobilityPedometerData *)uniquePedometerDataWithCMPedometerData:(CMPedometerData *)cmPedometerData moc:(NSManagedObjectContext *)moc
{
    MobilityPedometerData *pd = [self uniquePedometerDataWithStartDate:cmPedometerData.startDate endDate:cmPedometerData.endDate moc:moc];
    pd.stepCount = cmPedometerData.numberOfSteps;
    pd.distance = cmPedometerData.distance;
    pd.floorsAscended = cmPedometerData.floorsAscended;
    pd.floorsDescended = cmPedometerData.floorsDescended;
    
    return pd;
}

#else

- (MobilityPedometerData *)uniquePedometerDataWithStepCount:(NSInteger)stepCount startDate:(NSDate *)startDate endDate:(NSDate *)endDate moc:(NSManagedObjectContext *)moc
{
    MobilityPedometerData *pd = [self uniquePedometerDataWithStartDate:startDate endDate:endDate moc:moc];
    pd.stepCount = @(stepCount);
    
    return pd;
}

#endif

- (NSArray *)activitiesSinceDate:(NSDate *)startDate moc:(NSManagedObjectContext *)moc
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"timestamp >= %@", startDate];
    return [self fetchObjectsWithEntityName:@"MobilityActivity" predicate:predicate moc:moc];
}

- (NSArray *)oldestPendingActivitiesWithLimit:(NSInteger)fetchLimit
{
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
    return [self fetchPendingObjectsWithEntityName:@"MobilityActivity" sortDescriptor:descriptor fetchLimit:fetchLimit];
}

- (NSArray *)oldestPendingLocationsWithLimit:(NSInteger)fetchLimit
{
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
    return [self fetchPendingObjectsWithEntityName:@"MobilityLocation" sortDescriptor:descriptor fetchLimit:fetchLimit];
}

- (NSArray *)oldestPendingPedometerDataWithLimit:(NSInteger)fetchLimit
{
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES];
    return [self fetchPendingObjectsWithEntityName:@"MobilityPedometerData" sortDescriptor:descriptor fetchLimit:fetchLimit];
}

- (NSArray *)fetchPendingObjectsWithEntityName:(NSString *)entityName sortDescriptor:(NSSortDescriptor *)descriptor fetchLimit:(NSInteger)limit
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"submitted == NO && userEmail == %@", self.userEmail];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext]];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:@[descriptor]];
    [fetchRequest setFetchLimit:limit];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"error fetching pending objects for entity: %@", entityName);
    }
    
    return fetchedObjects;
}

- (NSManagedObject *)fetchObjectWithEntityName:(NSString *)entityName uniqueTimestamp:(NSDate *)timestamp moc:(NSManagedObjectContext *)moc
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"timestamp == %@ && userEmail == %@ ", timestamp, self.userEmail];
    return [self fetchObjectWithEntityName:entityName uniquePredicate:predicate moc:moc];
}

- (NSManagedObject *)fetchObjectWithEntityName:(NSString *)entityName uniquePredicate:(NSPredicate *)predicate moc:(NSManagedObjectContext *)moc
{
    NSArray *fetchedObjects = [self fetchObjectsWithEntityName:entityName predicate:predicate moc:moc];
    if (fetchedObjects.count > 0) {
        if (fetchedObjects.count > 1) {
            NSLog(@"found more than one %@ with predicate %@", entityName, predicate);
        }
        return fetchedObjects.firstObject;
    }
    else {
        return nil;
    }
}

- (NSArray *)fetchObjectsWithEntityName:(NSString *)entityName predicate:(NSPredicate *)predicate moc:(NSManagedObjectContext *)moc
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:moc]];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"error fetching entity: %@, predicate: %@", entityName, predicate);
    }
    return fetchedObjects;
}

- (NSManagedObject *)insertNewObjectForEntityForName:(NSString *)entityName moc:(NSManagedObjectContext *)moc
{
    return [NSEntityDescription insertNewObjectForEntityForName:entityName
                                         inManagedObjectContext:moc];
}

- (NSFetchedResultsController *)fetchedActivitesController
{
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userEmail == %@", self.userEmail];
    return [self fetchedResultsControllerWithEntityName:@"MobilityActivity" predicate:predicate sortDescriptor:descriptor cacheName:nil];
//    return [self fetchedResultsControllerWithEntityName:@"MobilityActivity" predicate:predicate sortDescriptor:descriptor cacheName:@"MobilityActivities"];
}

- (NSFetchedResultsController *)fetchedLocationsController
{
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userEmail == %@", self.userEmail];
    return [self fetchedResultsControllerWithEntityName:@"MobilityLocation" predicate:predicate sortDescriptor:descriptor cacheName:nil];
//    return [self fetchedResultsControllerWithEntityName:@"MobilityLocation" predicate:predicate sortDescriptor:descriptor cacheName:@"MobilityLocations"];

}

- (NSFetchedResultsController *)fetchedPedometerDataController
{
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:NO];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userEmail == %@", self.userEmail];
    return [self fetchedResultsControllerWithEntityName:@"MobilityPedometerData" predicate:predicate sortDescriptor:descriptor cacheName:nil];
//    return [self fetchedResultsControllerWithEntityName:@"MobilityPedometerData" predicate:predicate sortDescriptor:descriptor cacheName:@"MobilityPedometerData"];
}

- (NSFetchedResultsController *)fetchedLogEntriesController
{
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
    return [self fetchedResultsControllerWithEntityName:@"DebugLogEntry" predicate:nil sortDescriptor:descriptor cacheName:nil];
//    return [self fetchedResultsControllerWithEntityName:@"DebugLogEntry" predicate:nil sortDescriptor:descriptor cacheName:@"DebugLogEntries"];
}

- (NSFetchedResultsController *)fetchedResultsControllerWithEntityName:(NSString *)entityName
                                                             predicate:(NSPredicate *)predicate
                                                        sortDescriptor:(NSSortDescriptor *)descriptor
                                                             cacheName:(NSString *)cacheName
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors:@[descriptor]];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchBatchSize:100];
    [fetchRequest setFetchLimit:10000];
    
    // Build a fetch results controller based on the above fetch request.
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:self.managedObjectContext
                                                                                                 sectionNameKeyPath:nil
                                                                                                          cacheName:cacheName];
    
    
    [self.managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        [fetchedResultsController performFetch:&error];
        if (error != nil) {
            NSLog(@"Error performing fetch: %@", [error debugDescription]);
        }
    }];
    
    return fetchedResultsController;
}


/**
 *  saveManagedContext
 */
- (void)saveManagedContext
{
    [self.managedObjectContext performBlock:^{
        NSError *error = nil;
        [self.managedObjectContext save:&error];
        if (error) {
            NSLog(@"Error saving context: %@", [error localizedDescription]);
        }
    }];
}

/**
 *  deletePersistentStore
 */
- (void)deletePersistentStore
{
    NSLog(@"Deleting persistent store.");
    self.managedObjectContext = nil;
    self.managedObjectModel = nil;
    self.persistentStoreCoordinator = nil;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtURL:self.persistentStoreURL error:nil];
    
    self.persistentStoreURL = nil;
}

- (NSManagedObjectContext *)newChildMOC
{
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    moc.parentContext = self.managedObjectContext;
    return moc;
}

@end
