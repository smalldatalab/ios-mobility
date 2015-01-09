//
//  DebugLogEntry.h
//  Mobility
//
//  Created by Charles Forkish on 1/9/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface DebugLogEntry : NSManagedObject

@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * text;

@end
