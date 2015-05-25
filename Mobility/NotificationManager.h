//
//  NotificationManager.h
//  Mobility
//
//  Created by Charles Forkish on 5/23/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kNotificationActionIdentifierResume;
extern NSString * const kNotificationActionIdentifierSettings;
extern NSString * const kNotificationCategoryIdentifierResume;
extern NSString * const kNotificationCategoryIdentifierSettings;

@interface NotificationManager : NSObject

+ (BOOL)hasNotificationPermissions;
+ (void)requestNotificationPermissions;

//+ (void)presentNotification:(NSString *)message;
+ (void)presentSettingsNotification;
+ (void)scheduleResumeNotificationWithFireDate:(NSDate *)fireDate;

+ (instancetype)sharedManager;
- (void)presentSettingsAlert;


@end
