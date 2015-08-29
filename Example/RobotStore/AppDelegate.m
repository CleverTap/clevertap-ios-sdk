//
//  AppDelegate.m
//  RobotStore
//
//  Created by pwilkniss on 8/14/15.
//  Copyright (c) 2015 CleverTap. All rights reserved.
//

#import "AppDelegate.h"
#import <WizRocketSDK/WizRocket.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#ifdef DEBUG
    [WizRocket setDebugLevel:1];
#endif
    
    [WizRocket notifyApplicationLaunchedWithOptions:launchOptions];
    [WizRocket enablePersonalization];
    NSDate *lastTimeAppLaunched = [[NSDate alloc] initWithTimeIntervalSince1970:[[WizRocket session] getPreviousVisitTime]];
    NSLog(@"last app launch %@", lastTimeAppLaunched);
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end
