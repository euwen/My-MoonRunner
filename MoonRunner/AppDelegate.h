//
//  AppDelegate.h
//  MoonRunner
//
//  Created by Youwen Yi on 1/16/15.
//  Copyright (c) 2015 Youwen Yi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end

