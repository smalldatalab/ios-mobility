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

@interface NotificationManager() <UIAlertViewDelegate>

@end

@implementation NotificationManager

+ (void)presentNotification:(NSString *)message
{
    NSLog(@"present notification: %@", message);
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = message;
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

+ (void)presentSettingsNotification
{
    NSLog(@"present settings notification");
//    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
//        [[self sharedManager] presentSettingsAlert];
//        return;
//    }
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = kSettingsAlertBody;
//    notification.alertTitle = @"
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.category = kNotificationCategoryIdentifierSettings;
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

+ (void)scheduleNotificationWithMessage:(NSString *)message fireDate:(NSDate *)fireDate
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = message;
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

+ (UIUserNotificationAction *)resumeAction
{
    UIMutableUserNotificationAction *resumeAction =
    [[UIMutableUserNotificationAction alloc] init];
    
    // Define an ID string to be passed back to your app when you handle the action
    resumeAction.identifier = kNotificationActionIdentifierResume;
    
    // Localized string displayed in the action button
    resumeAction.title = @"Resume";
    
    // If you need to show UI, choose foreground
    resumeAction.activationMode = UIUserNotificationActivationModeBackground;
    
    // Destructive actions display in red
    resumeAction.destructive = NO;
    
    // Set whether the action requires the user to authenticate
    resumeAction.authenticationRequired = NO;
    
    return resumeAction;
}

+ (UIUserNotificationAction *)settingsAction
{
    UIMutableUserNotificationAction *settingsAction =
    [[UIMutableUserNotificationAction alloc] init];
    
    // Define an ID string to be passed back to your app when you handle the action
    settingsAction.identifier = kNotificationActionIdentifierSettings;
    
    // Localized string displayed in the action button
    settingsAction.title = @"Settings";
    
    // If you need to show UI, choose foreground
    settingsAction.activationMode = UIUserNotificationActivationModeBackground;
    
    // Destructive actions display in red
    settingsAction.destructive = NO;
    
    // Set whether the action requires the user to authenticate
    settingsAction.authenticationRequired = NO;
    
    return settingsAction;
}

+ (UIUserNotificationCategory *)resumeCategory
{
    // First create the category
    UIMutableUserNotificationCategory *resumeCategory =
    [[UIMutableUserNotificationCategory alloc] init];
    
    UIUserNotificationAction *resumeAction = [self resumeAction];
    
    // Identifier to include in your push payload and local notification
    resumeCategory.identifier = kNotificationCategoryIdentifierResume;
    
    // Add the actions to the category and set the action context
    [resumeCategory setActions:@[resumeAction]
                    forContext:UIUserNotificationActionContextDefault];
    
    // Set the actions to present in a minimal context
    [resumeCategory setActions:@[resumeAction]
                    forContext:UIUserNotificationActionContextMinimal];
    
    return resumeCategory;
}

+ (UIUserNotificationCategory *)settingsCategory
{
    // First create the category
    UIMutableUserNotificationCategory *settingsCategory =
    [[UIMutableUserNotificationCategory alloc] init];
    
    UIUserNotificationAction *settingsAction = [self settingsAction];
    
    // Identifier to include in your push payload and local notification
    settingsCategory.identifier = kNotificationCategoryIdentifierSettings;
    
    // Add the actions to the category and set the action context
    [settingsCategory setActions:@[settingsAction]
                    forContext:UIUserNotificationActionContextDefault];
    
    // Set the actions to present in a minimal context
    [settingsCategory setActions:@[settingsAction]
                    forContext:UIUserNotificationActionContextMinimal];
    
    return settingsCategory;
}

+ (BOOL)hasNotificationPermissions
{
    
    if (![[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)]) {
        return YES;
    }
    
    UIUserNotificationSettings *settings = [UIApplication sharedApplication].currentUserNotificationSettings;
    NSLog(@"settings: %@", settings);
    
    return NO; // TODO: remove
    return ((settings.types & UIUserNotificationTypeAlert));
}

+ (void)requestNotificationPermissions
{
    [[self sharedManager] requestNotificationPermissions];
}

+ (void)registerNotificationSettings
{
    NSSet *categories = [NSSet setWithObjects:[self resumeCategory], [self settingsCategory], nil];
    UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeSound;
                                               
    UIUserNotificationSettings *settings =
    [UIUserNotificationSettings settingsForTypes:types categories:categories];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
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
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark - iOS 8 Notification Permission

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

#endif


@end
