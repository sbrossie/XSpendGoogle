//
//  GoogleDataSheetHelper.h
//  XSpendGoogle
//
//  Created by Stephane Brossier on 8/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GData.h"
#import "GoogleDocumentListHelper.h"


@class FirstViewController;
@class SecondViewController;
@class GoogleSpreadSheetHelper;

@interface GoogleDataSheetHelper : NSObject {

	NSString *userName;
	NSString *password;
	
	NSArray *categories;
	
	NSInteger curMonth;
	NSInteger curYear;
	
	FirstViewController *firstViewController;
	SecondViewController *secondViewController;
	
	GDataFeedSpreadsheet *spreadsheetFeed;
	GDataServiceTicket *spreadsheetFeedTicket;
	NSError *spreadsheetFetchError;
	

	GoogleSpreadSheetHelper *activeSpreadsheet;
	GoogleSpreadSheetHelper *displayedSpreadsheet;
	
	
	GoogleDocumentListHelper* documentListHelper;
	
	NSString * waitForNewSpreadsheetName;
	
	// Current displayed table name for tab 2.
	NSUInteger displayedYear;	
}





@property (nonatomic, retain) GoogleSpreadSheetHelper *activeSpreadsheet;
@property (nonatomic, retain) GoogleSpreadSheetHelper *displayedSpreadsheet;

@property (nonatomic, retain) NSString *userName;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSArray *categories;


@property (nonatomic) NSInteger curMonth;
@property (nonatomic) NSInteger curYear;


@property (nonatomic, retain) FirstViewController *firstViewController;
@property (nonatomic, retain) SecondViewController *secondViewController;


@property (nonatomic, retain) GDataEntrySpreadsheet *spreadsheetEntry;
@property (nonatomic, retain) GDataFeedSpreadsheet *spreadsheetFeed;
@property (nonatomic, retain) GDataServiceTicket *spreadsheetFeedTicket;
@property (nonatomic, retain) NSError *spreadsheetFetchError;

@property (nonatomic, retain) GoogleDocumentListHelper* documentListHelper;

@property (nonatomic, retain) NSString * waitForNewSpreadsheetName;

@property (nonatomic) NSUInteger displayedYear;


+ (NSString *) getMonthFromIndex:(NSInteger) index;

- (void) onNewSpreadsheetCreated: (NSString *) spreadsheetName;

- (GoogleDataSheetHelper *) initialize:  (NSString *) username withPwd: (NSString *) pwd withCategories: (NSArray*) categories
				   withFirstController:(FirstViewController *) firstController withSecondController:(SecondViewController *) secondController;

- (void) addSpendingEntry: (NSString *) date
		 withAmount: (NSString *) amount
		 withDesc: (NSString *) desc
		 withBeneficiary: (NSString *) benef
		 withCategory: (NSString *) category;

- (void) updateSpendingEntry: (NSString *) recordId
				  withAmount: (NSString *) amount
					withDesc: (NSString *) desc
			 withBeneficiary: (NSString *) benef
				withCategory: (NSString *) category;

- (void) initiateFetchRecordsForTable: (NSUInteger) year andMonth: (NSUInteger) month;

@end
