//
//  LoginViewController.m
//  PAM
//
//  Created by Charles Forkish on 11/23/14.
//  Copyright (c) 2014 Charlie Forkish. All rights reserved.
//

#import "LoginViewController.h"
#import "UIView+AutoLayoutHelpers.h"
#import "AppDelegate.h"
#import "OMHClient.h"
#import "MobilityLogger.h"
#import "MobilityModel.h"
#import "DSUURLViewController.h"

@interface LoginViewController () <OMHSignInDelegate>

@property (nonatomic, weak) UIButton *signInButton;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UILabel *signInFailureLabel;

@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIColor* bgColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ipad-BG-pattern"]];
    [self.view setBackgroundColor:bgColor];
    
    UILabel *header = [[UILabel alloc] init];
    header.text = @"Mobility";
    header.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:65.0];
    header.textAlignment = NSTextAlignmentCenter;
    
    [self.view addSubview:header];
    [self.view constrainChildToDefaultHorizontalInsets:header];
    [header constrainToTopInParentWithMargin:80];
    
    UIButton *settings = [UIButton buttonWithType:UIButtonTypeSystem];
    [settings setImage:[UIImage imageNamed:@"settings"] forState:UIControlStateNormal];
    [settings addTarget:self action:@selector(presentSettingsViewController) forControlEvents:UIControlEventTouchUpInside];
    [settings constrainSize:CGSizeMake(25, 25)];
    [self.view addSubview:settings];
    [settings constrainToLeftInParentWithMargin:10];
    [settings constrainToBottomInParentWithMargin:10];
    
    [self setupSignInButton];
}

- (void)setupSignInButton
{
    if (self.signInButton) {
        [self.signInButton removeFromSuperview];
        self.signInButton = nil;
    }
    
    UIButton *googleButton = [OMHClient googleSignInButton];
    [googleButton addTarget:self action:@selector(signInButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:googleButton];
    [self.view constrainChildToDefaultHorizontalInsets:googleButton];
    [googleButton constrainToBottomInParentWithMargin:80];
    
    [OMHClient sharedClient].signInDelegate = self;
    self.signInButton = googleButton;
}

- (void)signInButtonPressed:(id)sender
{
    if (self.signInFailureLabel != nil) {
        [self.signInFailureLabel removeFromSuperview];
        self.signInFailureLabel = nil;
    }
    
    self.signInButton.userInteractionEnabled = NO;
    self.signInButton.alpha = 0.7;
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:indicator];
    [indicator centerInView:self.view];
    [indicator startAnimating];
    self.activityIndicator = indicator;
}

- (void)presentSignInFailureMessage
{
    UILabel *label = [[UILabel alloc] init];
    label.text = @"Sign in failed";
    [label sizeToFit];
    [self.view addSubview:label];
    [label centerInView:self.view];
    self.signInFailureLabel = label;
}

- (void)presentSettingsViewController
{
    DSUURLViewController *vc = [[DSUURLViewController alloc] init];
    UINavigationController *navcon = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navcon animated:YES completion:nil];
}

- (void)OMHClient:(OMHClient *)client signInFinishedWithError:(NSError *)error
{
    [self.activityIndicator stopAnimating];
    
    if (error != nil) {
        NSLog(@"OMHClientLoginFinishedWithError: %@", error);
        [self setupSignInButton];
        [self presentSignInFailureMessage];
        return;
    }
    
    [[MobilityModel sharedModel] setUserEmail:[OMHClient signedInUserEmail]];
    [[MobilityLogger sharedLogger] startLogging];
    [[MobilityLogger sharedLogger] enteredForeground];
    
    if (self.presentingViewController != nil) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        [(AppDelegate *)[UIApplication sharedApplication].delegate userDidLogin];
    }
}




@end
