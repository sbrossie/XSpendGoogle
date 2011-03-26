//
//  GoogleDataSheetHelper.m
//  XSpendGoogle
//
//  Created by Stephane Brossier on 8/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GoogleDataSheetHelper.h"

// creds: steph/bobo stephboboiphone stephboboiphone7

NSString * const SpreadsheetPrefix = @"TSpending-";


@interface GoogleDataSheetHelper (PrivateMethods) 

- (NSArray *) getDateComponents:(NSDate *) date;
- (NSString *) getSpreadsheetName:(NSString*) prefix withYear:(NSUInteger) year;
- (void)fetchFeedOfSpreadsheets;

- (void)spreadsheetsTicket:(GDataServiceTicket *)ticket
          finishedWithFeed:(GDataFeedSpreadsheet *)feed
                     error:(NSError *)error;

- (GDataServiceGoogleSpreadsheet *)spreadsheetService;


- (GDataEntrySpreadsheet *) lookupSpreadsheet: (NSString *) name; 

- (BOOL) isUpToDate;

@end

//#define SET_CUR_DATE 1

#ifdef SET_CUR_DATE
#define CUR_MONTH 12
#define CUR_YEAR 2010
#else
#define CUR_MONTH
#define CUR_YEAR
#endif


@implementation GoogleDataSheetHelper



@synthesize userName;
@synthesize password;
@synthesize categories;
@synthesize curMonth;
@synthesize curYear;
@synthesize firstViewController;
@synthesize secondViewController;


@synthesize spreadsheetFeed;
@synthesize spreadsheetFeedTicket;
@synthesize spreadsheetFetchError;

	
@synthesize documentListHelper;
@synthesize waitForNewSpreadsheetName;
@synthesize displayedYear;

@synthesize activeSpreadsheet;
@synthesize displayedSpreadsheet;



- (GoogleDataSheetHelper *) initialize: (NSString *) username withPwd: (NSString *) pwd withCategories: (NSArray*) theCategories
				   withFirstController:(FirstViewController *) theFirstController withSecondController: (SecondViewController *) theSecondController {
	
	if ([self userName] != nil) {
		NSLog(@"Already initialized the app");
		return self;
	}
	
	[self setUserName: username];
	[self setPassword: pwd];
	[self setCategories: theCategories];
	[self setFirstViewController: theFirstController];
	[self setSecondViewController: theSecondController];	
	[self setWaitForNewSpreadsheetName:nil];
	
	[self setActiveSpreadsheet:nil];
	[self setDisplayedSpreadsheet:nil];
	[self setDisplayedYear:-1];
	
	GoogleDocumentListHelper *docHelper = [[[GoogleDocumentListHelper alloc] initialize:username withPwd:pwd withDataSheetHelper: self] autorelease];
	[self setDocumentListHelper: docHelper];
	[self fetchFeedOfSpreadsheets];
	return self;
}


- (void) onNewSpreadsheetCreated: (NSString *) spreadsheetName {
	
	
	if (spreadsheetName == nil) {
		NSLog(@"Unexpected callback from List API for new spreadsheet : nil");
		return;
	}
	
	
	if ([self waitForNewSpreadsheetName] == nil) {
		NSLog(@"Unexpected callback from List API for new spreadsheet %@", spreadsheetName);
		return;
	}
	
	if ([[self waitForNewSpreadsheetName] isEqualToString:spreadsheetName]) {
		[self fetchFeedOfSpreadsheets];
	} else {
		NSLog(@"newSpreadsheetCreated : Unexpected spreadsheetName %@", spreadsheetName);
	}
}


- (void) initiateFetchRecordsForTable: (NSUInteger) year andMonth: (NSUInteger) month {
	
	
	NSString *spreadsheetName = [self getSpreadsheetName: SpreadsheetPrefix withYear: year];
	
	NSLog(@"Looking for spreadsheet %@", spreadsheetName);
	
	GDataEntrySpreadsheet * theSpreadsheet = [self lookupSpreadsheet: spreadsheetName];
	if (!theSpreadsheet) {
		NSLog(@"Missing spreadsheet %@, nothing to display for year %d", year);
		return;
	} 		
	

	NSLog(@"Initalizing spreadsheet %@ ", spreadsheetName);
	if (![self displayedSpreadsheet] || [[self displayedSpreadsheet] year] != year) {
			
		GoogleSpreadSheetHelper * tmp =  [[[GoogleSpreadSheetHelper alloc] initialize:year 
																 withSpreadsheetName:spreadsheetName 
																	 withSpreadsheet:theSpreadsheet
																		withUsername: [self userName]
																			 withPwd: [self password]
																	  withCategories: [self categories]
																 withFirstController: [self firstViewController]
																withSecondController: [self secondViewController]
																		withCurMonth: month
																			 readOnly: YES] autorelease];	
		[self setDisplayedSpreadsheet:tmp];
		
	} else {
		[[self displayedSpreadsheet] initiateFetchRecordsForTable: month];
	}
	[self setDisplayedYear: year];
	
}


- (void) updateSpendingEntry: (NSString *) recordId
			   withAmount: (NSString *) amount
				 withDesc: (NSString *) desc
		  withBeneficiary: (NSString *) benef
			 withCategory: (NSString *) category {
	
	
	
	if (![ self displayedSpreadsheet]) {
		NSLog(@"Missing displayed spreadsheet ??");
		return;
	}
	
	[[self displayedSpreadsheet] updateSpendingEntry: recordId
								   withAmount: amount
									 withDesc: desc
							  withBeneficiary: benef
							withCategory: category];

}


- (void) addSpendingEntry: (NSString *) date
			   withAmount: (NSString *) amount
				 withDesc: (NSString *) desc
		  withBeneficiary: (NSString *) benef
			 withCategory: (NSString *) category {
	
	if (![self activeSpreadsheet]) {
		NSLog(@"Missing active spreadsheet ??");
		return;
	}
	
	
	[[self activeSpreadsheet] addSpendingEntry: date
							 withAmount: amount
							   withDesc: desc
						withBeneficiary: benef
						   withCategory: category
						pendingUpToDate: ![self isUpToDate]];
	
	if (![self isUpToDate]) {
		// Re-init the whole thing
		[self fetchFeedOfSpreadsheets];
	}
}

			
//
//
//  Private methods
//
//



- (BOOL) isUpToDate {
	
#ifdef SET_CUR_DATE
	return TRUE;
#else
	NSInteger knownMonth = [self curMonth];
	NSInteger knownYear = [self curYear];
	
	NSArray *dateComponents = [self getDateComponents:  [NSDate date]];
	NSInteger year = [[dateComponents objectAtIndex:0] intValue];
	NSInteger month = [[dateComponents objectAtIndex:1] intValue];
	
	if (knownYear == year && knownMonth == month) {
		return YES;
	} else {
		return FALSE;
	}
#endif /* SET_CUR_DATE */
}

- (NSArray *) getDateComponents:(NSDate *) date {
	unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit;
	NSCalendar * gregorian = [NSCalendar currentCalendar];
	NSDateComponents *comps = [gregorian components:unitFlags fromDate:date];
	
	NSInteger year = [comps year];
	NSInteger month = [comps month];
	
	NSArray * result = [[[NSArray alloc] initWithObjects: [NSNumber numberWithInt:year], [NSNumber numberWithInt:month], nil] autorelease];
	return result;
}



- (NSString *) getSpreadsheetName:(NSString*) prefix withYear: (NSUInteger) year {
	
	NSString *thePrefix = nil;
	
	if (prefix == nil) {
		thePrefix = @"";
	} else {
		thePrefix = prefix;
	}
	
	NSMutableString *result = [NSMutableString stringWithString:thePrefix];
	[result appendFormat:@"%d", year];
	
	// STEPH
	NSLog(@"[result retainCount] = %d", [result retainCount]);
	return result;
}


#pragma mark google interaction

- (GDataServiceGoogleSpreadsheet *)spreadsheetService {
	
	static GDataServiceGoogleSpreadsheet* service = nil;
	
	if (!service) {
		service = [[GDataServiceGoogleSpreadsheet alloc] init];
		
		[service setShouldCacheDatedData:YES];
		[service setServiceShouldFollowNextLinks:YES];
		
		// iPhone apps will typically disable caching dated data or will call
		// clearLastModifiedDates after done fetching to avoid wasting
		// memory.
	}
	
	
	[service setUserAgent:@"My-UserAgent"]; // set this to yourName-appName-appVersion
	[service setUserCredentialsWithUsername: [self userName]
								   password: [self password]];
	
	return service;
}


// Entry point to refetch everything.
- (void)fetchFeedOfSpreadsheets {
	
	
	NSArray *dateComponents = [self getDateComponents:  [NSDate date]];
	
#ifdef SET_CUR_DATE
	NSInteger year = CUR_YEAR;
	NSInteger month = CUR_MONTH;
#else
	NSInteger year = [[dateComponents objectAtIndex:0] intValue];
	NSInteger month = [[dateComponents objectAtIndex:1] intValue];

#endif

	
	
	
	[self setCurYear: year];
	[self setCurMonth: month];
		
	[self setSpreadsheetFeed:nil];
	[self setSpreadsheetFetchError:nil];
	[self setSpreadsheetFeedTicket:nil];
	
	[self setActiveSpreadsheet:nil];
	[self setDisplayedSpreadsheet:nil];
	
	[self setWaitForNewSpreadsheetName:nil];
	
	
	GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
	NSURL *feedURL = [NSURL URLWithString:kGDataGoogleSpreadsheetsPrivateFullFeed];
	
	GDataServiceTicket *ticket;
	ticket = [service fetchFeedWithURL:feedURL
							  delegate:self
					 didFinishSelector:@selector(spreadsheetsTicket:finishedWithFeed:error:)];
	[self setSpreadsheetFeedTicket:ticket];
	
}


// spreadsheet feed fetch callback
- (void)spreadsheetsTicket:(GDataServiceTicket *)ticket
          finishedWithFeed:(GDataFeedSpreadsheet *)feed
                     error:(NSError *)error {
	

	[self setSpreadsheetFeed:feed];
	[self setSpreadsheetFetchError:error];
	[self setSpreadsheetFeedTicket:nil];
	
	
	NSLog(@"Got callback with feeds error = %d", error.code);
	
	NSString *spreadsheetName = [self getSpreadsheetName: SpreadsheetPrefix withYear: [self curYear]];

	GDataEntrySpreadsheet * theSpreadsheet = [self lookupSpreadsheet: spreadsheetName];
	if (!theSpreadsheet) {
		
		[self setSpreadsheetFeed:nil];
		[self setSpreadsheetFetchError:nil];
		
		NSLog(@"Missing spreadsheet %@, will create it and reinitialze", spreadsheetName);
		
		[self setWaitForNewSpreadsheetName: spreadsheetName];
		[[self documentListHelper] createEmptySpreadsheet:spreadsheetName];
	} else {
		
		NSLog(@"Initalizing spreadsheet %@ ", spreadsheetName);

				
		GoogleSpreadSheetHelper * tmp =  [[[GoogleSpreadSheetHelper alloc] initialize: [self curYear] 
																 withSpreadsheetName:spreadsheetName 
																	 withSpreadsheet:theSpreadsheet
																		withUsername: [self userName]
																			 withPwd: [self password]
																	  withCategories: [self categories]
																 withFirstController: [self firstViewController]
																withSecondController: [self secondViewController]
																		withCurMonth: [self curMonth]
																			 readOnly: NO] autorelease];

		[self setActiveSpreadsheet:tmp];
		[self setDisplayedSpreadsheet:tmp];		
	}
}

- (GDataEntrySpreadsheet *) lookupSpreadsheet: (NSString *) spreadsheetName {
	
	
	NSLog(@"Looking for %@", spreadsheetName);
	if (![self spreadsheetFeed]) {
		NSLog(@"spreadsheet Feed has not been setup ?");
		return nil;
	}
	
	NSArray *spreadsheets = [[self spreadsheetFeed] entries];
	
	NSUInteger i, count = [spreadsheets count];
	for (i = 0; i < count; i++) {
		GDataEntrySpreadsheet * cur = [spreadsheets objectAtIndex:i];
		NSString * title = [[cur title] contentStringValue];
		NSLog(@"got spreadsheet %@", title);
		if ([title isEqualToString:spreadsheetName]) {
			return cur;
		}
	}
	return nil;
}


- (void)dealloc {
	
	self.userName = nil;
	self.password = nil;
	
	self.categories = nil;
	

	self.firstViewController = nil;
	self.secondViewController = nil;
	
	self.spreadsheetFeed = nil;
	self.spreadsheetFeedTicket = nil;
	self.spreadsheetFetchError = nil;
	self.activeSpreadsheet = nil;
	self.displayedSpreadsheet = nil;
	
	
	self.documentListHelper = nil;
	
	self.waitForNewSpreadsheetName = nil;
	
    [super dealloc];
}

@end
