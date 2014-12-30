//
//  AppDelegate.m
//  Mobility
//
//  Created by Charles Forkish on 12/15/14.
//  Copyright (c) 2014 Open mHealth. All rights reserved.
//

#import "AppDelegate.h"
#import "MobilityViewController.h"
#import "LocationTableViewController.h"
#import "LoginViewController.h"
#import "OMHClient.h"
#import "ActivityLogger.h"


NSString * const kMobilityGoogleClientID = @"48636836762-ba1jcrir6sft063gkvpav0e3o9p4mtb5.apps.googleusercontent.com";
NSString * const kOMHServerGoogleClientID = @"48636836762-mulldgpmet2r4s3f16s931ea9crcc64m.apps.googleusercontent.com";
NSString * const kMobilityDSUClientID = @"com.openmhealth.ios.mobility";
NSString * const kMobilityDSUClientSecret = @"Rtg43jkLD7z76c";

@interface AppDelegate ()

@property (nonatomic, strong) LoginViewController *loginViewController;
@property (nonatomic, strong) UITabBarController *tabBarController;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [self setupOMHClient];
    
    if (![OMHClient sharedClient].isSignedIn) {
        self.window.rootViewController = self.loginViewController;
    }
    else {
        self.window.rootViewController = self.tabBarController;
    }
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)setupOMHClient
{
    OMHClient *client = [OMHClient sharedClient];
    client.appGoogleClientID = kMobilityGoogleClientID;
    client.serverGoogleClientID = kOMHServerGoogleClientID;
    client.appDSUClientID = kMobilityDSUClientID;
    client.appDSUClientSecret = kMobilityDSUClientSecret;
}

- (void)userDidLogin
{
    UITabBarController *newRoot = self.tabBarController;
    [UIView transitionFromView:self.loginViewController.view toView:newRoot.view duration:0.35 options:UIViewAnimationOptionTransitionCrossDissolve completion:^(BOOL finished) {
        self.window.rootViewController = newRoot;
        self.loginViewController = nil;
    }];
}

- (LoginViewController *)loginViewController
{
    if (_loginViewController == nil) {
        _loginViewController = [[LoginViewController alloc] init];
    }
    return _loginViewController;
}

- (UITabBarController *)tabBarController
{
    if (_tabBarController == nil) {
        MobilityViewController *mvc = [[MobilityViewController alloc] init];
        UINavigationController *navconM = [[UINavigationController alloc] initWithRootViewController:mvc];
        
        LocationTableViewController *lvc = [[LocationTableViewController alloc] init];
        UINavigationController *navconL = [[UINavigationController alloc] initWithRootViewController:lvc];
        
        UITabBarController *tbc = [[UITabBarController alloc] init];
        tbc.viewControllers = @[navconM, navconL];
        
        _tabBarController = tbc;
    }
    return _tabBarController;
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
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//    [[ActivityLogger sharedLogger] enterBackgroundMode];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//    [[ActivityLogger sharedLogger] exitBackgroundMode];
    [[ActivityLogger sharedLogger] startLogging];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
