//
//  ActivityLogger.h
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobilityLogEntry.h"

@interface ActivityLogger : NSObject

+ (instancetype)sharedLogger;

@property (nonatomic, readonly) NSArray *logEntries;
@property (copy) void (^newLogEntryBlock)(MobilityLogEntry *logEntry);

- (void)startLogging;

@end
