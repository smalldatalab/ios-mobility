//
//  WebViewController.m
//  Mobility
//
//  Created by Charles Forkish on 11/6/15.
//  Copyright © 2015 Open mHealth. All rights reserved.
//

#import "WebViewController.h"
#import "UIView+AutoLayoutHelpers.h"
#import "MobilityModel.h"
#import "OMHClient.h"
#import "LoginViewController.h"
#import "MobilityLogger.h"
#import "AppDelegate.h"
#import "AppConstants.h"
#import "ActivityTableViewController.h"
#import "LocationTableViewController.h"
#import "PedometerTableViewController.h"
#import "LogTableViewController.h"


@interface WebViewController () <UIWebViewDelegate, OMHSignInDelegate, OMHReachabilityDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UITabBarController *tabBarController;

@end

@implementation WebViewController

- (void)loadView {
    UIWebView *wv = [[UIWebView alloc] init];
    wv.delegate = self;
    wv.scalesPageToFit = YES;
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [wv addSubview:activityIndicator];
    [activityIndicator centerInView:wv];
    self.activityIndicator = activityIndicator;
    
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    [wv addSubview:label];
    [wv constrainChildToDefaultHorizontalInsets:label];
    [label positionAboveElement:activityIndicator margin:20];
    [label constrainToTopInParentWithMargin:100];
    label.textAlignment = NSTextAlignmentCenter;
    self.label = label;
    
    self.webView = wv;
    self.view = wv;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Mobility";
    
    UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(logout)];
    
    self.navigationItem.leftBarButtonItem = logoutButton;
    
    UIBarButtonItem *dataButton = [[UIBarButtonItem alloc] initWithTitle:@"Data"
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(presentDataTabs)];
    
    self.navigationItem.rightBarButtonItem = dataButton;
    
    [OMHClient sharedClient].signInDelegate = self;
    [OMHClient sharedClient].reachabilityDelegate = self;
    
    [self loadVisualizer];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.activityIndicator startAnimating];
    [self updateLabel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateLabel
{
    if ([OMHClient sharedClient].accessTokenExpiresIn < 0) {
        self.label.text = @"Authenticating...";
    }
    else {
        self.label.text = @"Loading Visualizer...";
    }
}

- (void)logout
{
    [[MobilityLogger sharedLogger] stopLogging];
    [[OMHClient sharedClient] signOut];
    [[MobilityModel sharedModel] setUserEmail:nil];
    
    [(AppDelegate *)[UIApplication sharedApplication].delegate userDidLogout];
}

- (void)presentDataTabs {
    [self.navigationController presentViewController:self.tabBarController animated:YES completion:nil];
}

- (void)dismissDataTabs {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        self.tabBarController = nil;
    }];
}

- (UITabBarController *)tabBarController
{
    if (_tabBarController == nil) {
        ActivityTableViewController *avc = [[ActivityTableViewController alloc] init];
        UINavigationController *navconA = [[UINavigationController alloc] initWithRootViewController:avc];
        
        LocationTableViewController *lvc = [[LocationTableViewController alloc] init];
        UINavigationController *navconL = [[UINavigationController alloc] initWithRootViewController:lvc];
        
        PedometerTableViewController *pvc = [[PedometerTableViewController alloc] init];
        UINavigationController *navconP = [[UINavigationController alloc] initWithRootViewController:pvc];
        
        UITabBarController *tbc = [[UITabBarController alloc] init];
        tbc.viewControllers = @[navconA, navconL, navconP];
        
#ifdef LOG_TABLE
        LogTableViewController *logvc = [[LogTableViewController alloc] init];
        UINavigationController *navconLog = [[UINavigationController alloc] initWithRootViewController:logvc];
        tbc.viewControllers = [tbc.viewControllers arrayByAddingObject:navconLog];
#endif
        
        _tabBarController = tbc;
    }
    return _tabBarController;
}

- (void)loadVisualizer {
    if ([OMHClient sharedClient].accessTokenExpiresIn < 0) return;
    NSURL *url = [self visualizerURL];
    NSLog(@"url: %@", url);
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (NSURL *)visualizerURL {
    NSString *accessToken = [OMHClient sharedClient].dsuAccessToken;
    if (accessToken == nil) return nil;
    
    NSURL *baseURL = [NSURL URLWithString:kMobilityVisualizerURL];
    NSTimeInterval expiration = [OMHClient sharedClient].accessTokenExpiresIn;
    NSString *access = [NSString stringWithFormat:@"#access_token=%@&token_type=bearer&expires_in=%d&scope=read_data_points", accessToken, (int)expiration];
    return [NSURL URLWithString:access relativeToURL:baseURL];
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"web view finished load");
    [self.activityIndicator removeFromSuperview];
    self.activityIndicator = nil;
    [self.label removeFromSuperview];
    self.label = nil;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"web view failed to load: %@", error.debugDescription);
    if (error.code != -999) {
        self.activityIndicator.alpha = 0.0;
        self.label.text = @"Failed to load visualizer";
    }
}

#pragma mark - OMH Delegate

- (void)OMHClient:(OMHClient *)client reachabilityStatusChanged:(BOOL)isReachable {
    NSLog(@"reachability changed: %d", isReachable);
    [self updateLabel];
    if (isReachable) {
        [self loadVisualizer];
    }
    else {
        self.label.text = @"No network connection";
    }
}

- (void)OMHClient:(OMHClient *)client signInFinishedWithError:(NSError *)error {
    NSLog(@"sign in finished, error: %@", error.debugDescription);
    if (error == nil) {
        [self loadVisualizer];
    }
    else {
        self.label.text = @"Authentication error";
    }
}

- (void)OMHClientSignInCancelled:(OMHClient *)client
{
    NSLog(@"sign in cancelled");
}

@end
