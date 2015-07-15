//
//  AppDelegate.h
//  DrWatson
//
//  Created by Andrew Trice on 6/15/15.
//  Copyright (c) 2015 Andrew Trice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IMFCore/IMFClient.h"
#import "IMFCore/IMFLogger.h"
#import "IMFCore/IMFAnalytics.h"
#import "IMFCore/IMFAuthorizationManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    IMFLogger *logger;
}

@property (strong, nonatomic) UIWindow *window;


@end

