//
//  AppDelegate.m
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import "OMHClient.h"
#import "MobilityLogger.h"
#import "MobilityModel.h"
#import "AppConstants.h"
#import "WebViewController.h"

#import "NotificationManager.h"

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>


@interface AppDelegate () <OMHSignInDelegate>

@property (nonatomic, strong) LoginViewController *loginViewController;
@property (nonatomic, strong) UINavigationController *navigationController;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Fabric with:@[CrashlyticsKit]];
    
    [OMHClient setupClientWithAppGoogleClientID:[AppConstants mobilityGoogleClientID]
                                 appDSUClientID:kMobilityDSUClientID
                             appDSUClientSecret:kMobilityDSUClientSecret];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    if (![OMHClient sharedClient].isSignedIn || ![MobilityModel sharedModel].hasUser) {
        self.window.rootViewController = self.loginViewController;
    }
    else {
        [CrashlyticsKit setUserName:[OMHClient signedInUsername]];
        self.window.rootViewController = self.navigationController;
        [OMHClient sharedClient].signInDelegate = self;
        [[MobilityLogger sharedLogger] startLogging];
    }
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [[MobilityModel sharedModel] logMessage:@"APP DID LAUNCH"];
    
    if ([[launchOptions valueForKey:UIApplicationLaunchOptionsLocationKey] boolValue]) {
        [[MobilityModel sharedModel] logMessage:@"app launched for location"];
    }
    
    return YES;
}

- (void)userDidLogin
{
    UINavigationController *newRoot = self.navigationController;
    [UIView transitionFromView:self.loginViewController.view toView:newRoot.view duration:0.35 options:UIViewAnimationOptionTransitionCrossDissolve completion:^(BOOL finished) {
        self.window.rootViewController = newRoot;
        self.loginViewController = nil;
    }];
    
    [CrashlyticsKit setUserName:[OMHClient signedInUsername]];
}


- (void)userDidLogout
{
    LoginViewController *newRoot = self.loginViewController;
    
    UIView *fromView = self.navigationController.view;
    
    [UIView transitionFromView:fromView toView:newRoot.view duration:0.35 options:UIViewAnimationOptionTransitionCrossDissolve completion:^(BOOL finished) {
        NSLog(@"finished:  %d", finished);
        self.window.rootViewController = newRoot;
        self.navigationController = nil;
    }];
    
    [CrashlyticsKit setUserName:nil];
}

- (LoginViewController *)loginViewController
{
    if (_loginViewController == nil) {
        _loginViewController = [[LoginViewController alloc] init];
    }
    return _loginViewController;
}

- (UINavigationController *)navigationController
{
    if (_navigationController == nil) {
        WebViewController *wv = [[WebViewController alloc] init];
        _navigationController = [[UINavigationController alloc] initWithRootViewController:wv];
    }
    return _navigationController;
}



- (BOOL)application: (UIApplication *)application
            openURL: (NSURL *)url
  sourceApplication: (NSString *)sourceApplication
         annotation: (id)annotation {
    NSLog(@"openURL: %@, source: %@, annotation: %@", url, sourceApplication, annotation);
    return [[OMHClient sharedClient] handleURL:url
                             sourceApplication:sourceApplication
                                    annotation:annotation];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[MobilityModel sharedModel] logMessage:@"APP WILL RESIGN"];
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[MobilityModel sharedModel] logMessage:@"APP ENTERED BACKGROUND"];
    [[MobilityLogger sharedLogger] enteredBackground];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//    [[ActivityLogger sharedLogger] enterBackgroundMode];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[MobilityModel sharedModel] logMessage:@"APP WILL ENTER FOREGROUND"];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[MobilityModel sharedModel] logMessage:@"APP BECAME ACTIVE"];
    [[MobilityLogger sharedLogger] enteredForeground];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//    [[ActivityLogger sharedLogger] exitBackgroundMode];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[MobilityModel sharedModel] logMessage:@"APP WILL TERMINATE"];
}




#pragma mark - OMHSignInDelegate

- (void)OMHClient:(OMHClient *)client signInFinishedWithError:(NSError *)error
{
    if (error != nil) {
        [[MobilityModel sharedModel] logMessage:@"SIGN IN ERROR"];
        [self userDidLogout];
        [NotificationManager presentAuthenticationNotification];
    }
    else {
        [[MobilityModel sharedModel] logMessage:@"sign in success"];
    }
}

- (void)OMHClientSignInCancelled:(OMHClient *)client {}
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {}
- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {}


#pragma mark - iOS 8 Notification Handling

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier
forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler
{
    NSLog(@"%s, identifier: %@", __PRETTY_FUNCTION__, identifier);
    if ([identifier isEqualToString:kNotificationActionIdentifierResumeAuthenticated]) {
        [[MobilityLogger sharedLogger] startLogging];
    }
//    else if ([identifier isEqualToString:kNotificationActionIdentifierSettings]) {
//        [application openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
//    }
    
    completionHandler();
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"%s, notification: %@", __PRETTY_FUNCTION__, notification.alertBody);
    if ([notification.category isEqualToString:kNotificationCategoryIdentifierSettings]) {
        [[NotificationManager sharedManager] presentSettingsAlert];
    }
}

#endif

@end
