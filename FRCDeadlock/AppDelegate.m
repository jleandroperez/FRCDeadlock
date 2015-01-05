//
//  AppDelegate.m
//  FRCDeadlock
//
//  Created by Jorge Leandro Perez on 1/5/15.
//  Copyright (c) 2015 Lantean. All rights reserved.
//

#import "AppDelegate.h"
#import "MasterViewController.h"
#import "ContextManager.h"


@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return true;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[ContextManager sharedInstance] saveContext];
}

@end
