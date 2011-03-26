//
//  XSpendGoogleAppDelegate.h
//  XSpendGoogle
//
//  Created by Stephane Brossier on 8/4/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FirstViewController.h"
#import "SecondViewController.h"


@interface XSpendGoogleAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
    UIWindow *window;
    UITabBarController *tabBarController;
	FirstViewController *firstViewController;
	SecondViewController *secondViewController;	
	BOOL initialized;
}

@property (nonatomic) BOOL initialized;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) IBOutlet FirstViewController *firstViewController;
@property (nonatomic, retain) IBOutlet SecondViewController *secondViewController;


- (void) updateEntry: (NSString*) entryId withCategory: (NSString *) category withDate:(NSString *) date withAmount: (NSString*)
	amount withDesc: (NSString*) desc withBenef: (NSString*) benef;
@end
