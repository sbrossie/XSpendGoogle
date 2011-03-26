//
//  XSpendGoogleAppDelegate.m
//  XSpendGoogle
//
//  Created by Stephane Brossier on 8/4/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "XSpendGoogleAppDelegate.h"


@interface XSpendGoogleAppDelegate (PrivateMethods) 
- (void)defaultsChanged:(NSNotification *)notification;
- (void) doInitialization;
@end


@implementation XSpendGoogleAppDelegate

@synthesize initialized;
@synthesize window;
@synthesize tabBarController;
@synthesize firstViewController;
@synthesize secondViewController;



NSString * const DEFAULT_USERNAME = nil; //
NSString * const DEFAULT_PASSWORD = nil; //

static NSArray * CategoryTableEntries = nil;



#pragma mark -
#pragma mark Application lifecycle




- (void)defaultsChanged:(NSNotification *)notification {
	
	NSLog(@"Got notification that defaults changed notification = %@", [notification description] );
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *username = [defaults stringForKey:@"username"];
	NSString *password = [defaults stringForKey:@"password"];
	if ([self initialized] == NO && username != nil && password != nil) {
		[ self doInitialization];
	}
}

- (void) doInitialization {
	
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *username = [defaults stringForKey:@"username"];
	NSString *password = [defaults stringForKey:@"password"];

	NSString *categories = [defaults stringForKey:@"categories"];
	NSLog(@"categories = %@", categories);
	
	NSArray * categoriesArg = CategoryTableEntries;
	NSArray* categoriesList = [categories componentsSeparatedByRegex:@"(?:,|\\s)+"];
	if (categoriesList != nil && [categoriesList count] > 1) {
		categoriesArg = categoriesList;
	}
	
	GoogleDataSheetHelper * dataSheetHelper = [GoogleDataSheetHelper alloc];
	
	// Man, took ne while to figure the controllers instances are already allocated. Just need to parse
	// the list and extract those entries
	
	
	NSArray *knownControllers = [tabBarController viewControllers];
	for (int i = 0; i < [knownControllers count]; i++) {
		NSString *className = [[[knownControllers objectAtIndex:i] class] description];
		NSLog(@"ViewController %@", className);
		if ([className isEqualToString:@"FirstViewController"]) {
			[self setFirstViewController:[knownControllers objectAtIndex:i]];
			[firstViewController initialize:categoriesArg withDataSheetHelper:dataSheetHelper];
		} else if ([className isEqualToString:@"SecondViewController"]) {
			[self setSecondViewController:[knownControllers objectAtIndex:i]];
			[secondViewController initialize:dataSheetHelper withAppDelegate: self];
		}
	}
	
	[dataSheetHelper initialize:username withPwd: password withCategories: categoriesArg 
			withFirstController: [self firstViewController] withSecondController: [self secondViewController] ];
	
	[self setInitialized:YES];
	
	
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
	NSLog(@"got didFinishApplicationLaunchingWithOptions");
	
	[self setInitialized:NO];
	
	CategoryTableEntries = [[NSArray alloc] initWithObjects:
							@"rent",
							@"utilities",
							@"restaurant",
							@"groceries",
							@"car",
							@"travelling",
							@"health",
							@"sports",
							@"entertainment",
							@"misc",
							nil];
							
    // Override point for customization after application launch.


    // Add the tab bar controller's view to the window and display.
    [window addSubview:tabBarController.view];
	
	
	// Register Observer for change in UserDefaults values.
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self
			   selector:@selector(defaultsChanged:)  
				   name:NSUserDefaultsDidChangeNotification
				 object:nil];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *username = [defaults stringForKey:@"username"];
	NSString *password = [defaults stringForKey:@"password"];
	if (username == nil || password == nil) {
		UIAlertView *someError = [[UIAlertView alloc] initWithTitle: @"Credentials error" message: @"Please provide user/pwd and category list in the settings." delegate: self cancelButtonTitle: @"Ok" otherButtonTitles: nil];
		[someError show];
		[someError release];
	} else {
		[self doInitialization];
	}

	[window makeKeyAndVisible];
    return YES;
}

- (void) updateEntry: (NSString*) entryId withCategory:(NSString *) category withDate:(NSString *) date withAmount: (NSString*) amount withDesc: (NSString*) desc withBenef: (NSString*) benef {
	[tabBarController setSelectedIndex:0];
	// STEPH
	NSLog(@"entryId = %@, refCount = %d", entryId, [entryId retainCount]);
	
	[firstViewController updateEntry: entryId withCategory: category withDate:date withAmount:amount withDesc:desc withBenef:benef];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark UITabBarControllerDelegate methods


- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
	NSLog(@"didSelectViewController controller %@", [viewController description]);
	NSString *viewControllerName = [[viewController class] description];
	//([className isEqualToString:@"SecondViewController"]) {
	if ([viewControllerName isEqualToString:@"FirstViewController"]) {
		[viewController onSwitchTab];		
	} else if ([viewControllerName isEqualToString:@"SecondViewController"]) {
		[viewController onSwitchTab];
	}
}


/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
}
*/


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
	self.tabBarController = nil;
	self.window = nil;
	self.firstViewController = nil;
    [super dealloc];
}

@end

