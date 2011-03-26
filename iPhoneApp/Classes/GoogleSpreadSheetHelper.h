//
//  GoogleSpreadSheet.h
//  XSpendGoogle
//
//  Created by Stephane Brossier on 1/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GData.h"


@class FirstViewController;
@class SecondViewController;

@interface GoogleSpreadSheetHelper : NSObject {

	BOOL readOnly;
	
	NSString *userName;
	NSString *password;
	
	NSArray *categories;
	NSArray *allCategories;
	
	
	FirstViewController *firstViewController;
	SecondViewController *secondViewController;
	
	
	NSInteger year;
    NSString* spreadsheetName;
	
	NSUInteger displayedMonth;
	NSArray *displayRecords;
	
	GDataEntrySpreadsheet *spreadsheetEntry;
	
	// Current spending entry
	NSString * curSpendingEntryDate;
	NSString * curSpendingEntryAmount;
	NSString * curSpendingEntryDesc;
	NSString * curSpendingEntryBeneficiary;
	NSString * curSpendingEntryCategory;
	
	GDataEntryWorksheet *worksheetEntry;
	GDataEntryWorksheet *firstWorksheetEntry;	
	GDataFeedWorksheet *worksheetFeed;
	GDataServiceTicket *worksheetFeedTicket;
	NSError *worksheetFetchError;
	
	GDataEntrySpreadsheetTable *categoryTable;
	GDataEntrySpreadsheetTable *spendingTable;	
	
	GDataFeedSpreadsheetTable *tableFeed;
	GDataServiceTicket *tableFeedTicket;
	NSError *tableFetchError;
	
	GDataFeedSpreadsheetRecord *recordCategoryFeed;
	GDataServiceTicket *recordCategoryFeedTicket;
	NSError *recordCategoryFetchError;
	
	GDataFeedSpreadsheetRecord *recordSpendingFeed;
	GDataServiceTicket *recordSpendingFeedTicket;
	NSError *recordSpendingFetchError;

}


@property (nonatomic, retain) NSString *userName;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSArray *categories;
@property (nonatomic, retain) NSArray *allCategories;


@property (nonatomic, retain) FirstViewController *firstViewController;
@property (nonatomic, retain) SecondViewController *secondViewController;

@property (nonatomic) BOOL readOnly;
@property (nonatomic) NSInteger year;

@property (nonatomic) NSUInteger displayedMonth;
@property (nonatomic, retain) NSArray *displayRecords;


@property (nonatomic, retain) NSString* spreadsheetName;

@property (nonatomic, retain) GDataEntrySpreadsheet *spreadsheetEntry;

@property (nonatomic, retain) NSString * curSpendingEntryDate;
@property (nonatomic, retain) NSString * curSpendingEntryAmount;
@property (nonatomic, retain) NSString * curSpendingEntryDesc;
@property (nonatomic, retain) NSString * curSpendingEntryBeneficiary;
@property (nonatomic, retain) NSString * curSpendingEntryCategory;

@property (nonatomic, retain) GDataEntryWorksheet *worksheetEntry;
@property (nonatomic, retain) GDataEntryWorksheet *firstWorksheetEntry;	
@property (nonatomic, retain) GDataFeedWorksheet *worksheetFeed;
@property (nonatomic, retain) GDataServiceTicket *worksheetFeedTicket;
@property (nonatomic, retain) NSError *worksheetFetchError;

@property (nonatomic, retain) GDataEntrySpreadsheetTable *categoryTable;
@property (nonatomic, retain) GDataEntrySpreadsheetTable *spendingTable;
@property (nonatomic, retain) NSError *spreadsheetFetchError;

@property (nonatomic, retain) GDataFeedSpreadsheetTable *tableFeed;
@property (nonatomic, retain) GDataServiceTicket *tableFeedTicket;
@property (nonatomic, retain) NSError *tableFetchError;

@property (nonatomic, retain) GDataFeedSpreadsheetRecord *recordCategoryFeed;
@property (nonatomic, retain) GDataServiceTicket *recordCategoryFeedTicket;
@property (nonatomic, retain) NSError *recordCategoryFetchError;

@property (nonatomic, retain) GDataFeedSpreadsheetRecord *recordSpendingFeed;
@property (nonatomic, retain) GDataServiceTicket *recordSpendingFeedTicket;
@property (nonatomic, retain) NSError *recordSpendingFetchError;

- (GoogleSpreadSheetHelper*) initialize : (NSInteger) year 
					 withSpreadsheetName: (NSArray*) spreadsheetName
						 withSpreadsheet: (GDataEntrySpreadsheet *) spreadsheet
							withUsername: (NSString*) username	
								 withPwd:(NSString*) pwd
						  withCategories:(NSArray*) categories
					 withFirstController:(FirstViewController *) theFirstController
					withSecondController: (SecondViewController *) theSecondController
							withCurMonth: (NSInteger) theMonth
								readOnly:(BOOL) isReadOnly;


- (void) initiateFetchRecordsForTable: (NSUInteger) month;

- (void) addSpendingEntry: (NSString *) date
			   withAmount: (NSString *) amount
				 withDesc: (NSString *) desc
		  withBeneficiary: (NSString *) benef
			 withCategory: (NSString *) category
		  pendingUpToDate: (BOOL) isPendingUpToDate;

- (void) updateSpendingEntry: (NSString *) recordId
				  withAmount: (NSString *) amount
					withDesc: (NSString *) desc
			 withBeneficiary: (NSString *) benef
				withCategory: (NSString *) category;


@end
