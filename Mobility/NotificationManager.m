//
//  NotificationManager.m
//  Mobility
//
//  Created by Charles Forkish on 5/23/15.
//  Copyright (c) 2015 Open mHealth. All rights reserved.
//

#import "NotificationManager.h"

static NSString * const kHasRequestedNotificationPermissionKey =
@"HAS_REQUESTED_NOTIFICATION_PERMISSION";

NSString * const kNotificationActionIdentifierResume =
@"NOTIFICATION_ACTION_IDENTIFIER_RESUME";

NSString * const kNotificationActionIdentifierSettings =
@"NOTIFICATION_ACTION_IDENTIFIER_SETTINGS";

NSString * const kNotificationCategoryIdentifierResume =
@"NOTIFICATION_CATEGORY_IDENTIFIER_RESUME";

NSString * const kNotificationCategoryIdentifierSettings =
@"NOTIFICATION_CATEGORY_IDENTIFIER_SETTINGS";


static NSString * const kSettingsAlertTitle = @"Enable Location";
static NSString * const kSettingsAlertBody = @"To continue tracking in the background, please allow location access for Mobility in your settings.";
static NSString * const kSevenDayWarningText = @"Tracking has been stopped for 7 days. Please launch Mobility to avoid losing activity data.";

@interface NotificationManager() <UIAlertViewDelegate>

@end

@implementation NotificationManager

//+ (void)presentNotification:(NSString *)message
//{
//    NSLog(@"present notification: %@", message);
//    UILocalNotification *notification = [[UILocalNotification alloc] init];
//    notification.alertBody = message;
//    notification.soundName = UILocalNotificationDefaultSoundName;
//    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
//}

+ (UILocalNotification *)notificationWithBody:(NSString *)body fireDate:(NSDate *)fireDate category:(NSString *)category
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.alertBody = body;
    notification.fireDate = fireDate;
    if ([notification respondsToSelector:@selector(category)]) {
        [notification performSelector:@selector(setCategory:) withObject:category];
    }
    
    return notification;
}

+ (void)presentSettingsNotification
{
    NSLog(@"present settings notification");
    UILocalNotification *notification = [self notificationWithBody:kSettingsAlertBody
                                                          fireDate:nil
                                                          category:kNotificationCategoryIdentifierSettings];
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

+ (void)scheduleResumeNotificationWithFireDate:(NSDate *)fireDate
{
    NSLog(@"schedule resume notification with fire date: %@", fireDate);
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *notification = [self notificationWithBody:@"Stopped tracking. Tap to resume"
                                                          fireDate:fireDate
                                                          category:kNotificationCategoryIdentifierResume];
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    
    [self scheduleSevenDayWarningNotification];
}

+ (void)scheduleSevenDayWarningNotification
{
    UILocalNotification *notification = [self notificationWithBody:kSettingsAlertBody
                                                          fireDate:[[NSDate date] dateByAddingDays:7]
                                                          category:nil];
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

+ (void)requestNotificationPermissions
{
    [[self sharedManager] requestNotificationPermissions];
}


#pragma mark - Singleton

+ (instancetype)sharedManager
{
    static NotificationManager *_sharedManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] initPrivate];
    });
    
    return _sharedManager;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[NotificationManager sharedManager]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
{
    return [super init];
}


#pragma mark - iOS 8

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

- (void)requestNotificationPermissions
{
    NSString *title;
    NSString *message;
    BOOL hasRequested = [[NSUserDefaults standardUserDefaults] boolForKey:kHasRequestedNotificationPermissionKey];
    
    if (!hasRequested) {
        title = @"Notification Permissions";
        message = @"To alert you if data tracking stops, Mobility needs permission to display notifications. Please allow notifications for Mobility.";
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kHasRequestedNotificationPermissionKey];
    }
    else {
        title = @"Insufficient Permissions";
        message = @"To alert you if data tracking stops, Mobility needs permission to display notifications. Please enable notifications for Mobility in your device settings.";
        
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)presentSettingsAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kSettingsAlertTitle
                                                    message:kSettingsAlertBody
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Settings", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:kSettingsAlertTitle]) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }
    else {
        [[self class] registerNotificationSettings];
    }
}

+ (UIUserNotificationAction *)resumeAction
{
    UIMutableUserNotificationAction *resumeAction =
    [[UIMutableUserNotificationAction alloc] init];
    
    resumeAction.identifier = kNotificationActionIdentifierResume;
    resumeAction.title = @"Resume";
    resumeAction.activationMode = UIUserNotificationActivationModeBackground;
    resumeAction.destructive = NO;
    resumeAction.authenticationRequired = NO;
    
    return resumeAction;
}

+ (UIUserNotificationAction *)settingsAction
{
    UIMutableUserNotificationAction *settingsAction =
    [[UIMutableUserNotificationAction alloc] init];
    
    settingsAction.identifier = kNotificationActionIdentifierSettings;
    settingsAction.title = @"Settings";
    settingsAction.activationMode = UIUserNotificationActivationModeBackground;
    settingsAction.destructive = NO;
    settingsAction.authenticationRequired = NO;
    
    return settingsAction;
}

+ (UIUserNotificationCategory *)resumeCategory
{
    UIMutableUserNotificationCategory *resumeCategory =
    [[UIMutableUserNotificationCategory alloc] init];
    resumeCategory.identifier = kNotificationCategoryIdentifierResume;
    
    UIUserNotificationAction *resumeAction = [self resumeAction];
    
    [resumeCategory setActions:@[resumeAction]
                    forContext:UIUserNotificationActionContextDefault];
    
    [resumeCategory setActions:@[resumeAction]
                    forContext:UIUserNotificationActionContextMinimal];
    
    return resumeCategory;
}

+ (UIUserNotificationCategory *)settingsCategory
{
    UIMutableUserNotificationCategory *settingsCategory =
    [[UIMutableUserNotificationCategory alloc] init];
    settingsCategory.identifier = kNotificationCategoryIdentifierSettings;
    
    UIUserNotificationAction *settingsAction = [self settingsAction];
    
    [settingsCategory setActions:@[settingsAction]
                      forContext:UIUserNotificationActionContextDefault];
    
    [settingsCategory setActions:@[settingsAction]
                      forContext:UIUserNotificationActionContextMinimal];
    
    return settingsCategory;
}


+ (BOOL)hasNotificationPermissions
{
    UIUserNotificationSettings *settings = [UIApplication sharedApplication].currentUserNotificationSettings;
//    NSLog(@"settings: %@", settings);
    
    return ((settings.types & UIUserNotificationTypeAlert) && settings.categories.count > 0);
}

+ (void)registerNotificationSettings
{
    NSSet *categories = [NSSet setWithObjects:[self resumeCategory], [self settingsCategory], nil];
    UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeSound;
    
    UIUserNotificationSettings *settings =
    [UIUserNotificationSettings settingsForTypes:types categories:categories];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
}


#else
#pragma mark - iOS 7

+ (BOOL)hasNotificationPermissions
{
    return YES;
}

- (void)requestNotificationPermissions {};
- (void)presentSettingsAlert {};

#endif


@end
