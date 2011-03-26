//
//  GoogleSpreadSheet.m
//  XSpendGoogle
//
//  Created by Stephane Brossier on 1/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GoogleSpreadSheetHelper.h"

NSString * const ColumnsForIndex = @"ABCDEFGHIJKLMNOPQRST";

NSString * const SpendingTable = @"Spending";
NSString * const CategoryTable = @"Category";


typedef enum _selectFetchTableAction {
	sInitCategory,  // Initialization phase (non readOnly) for category table
	sInitSpending,  // Initialization phase (non readOnly) for current spending table
	sFetchDisplay, // SecondController for displayed spendingTable
	sUpdateEntryCompletion,  // FirstController for entry update refresh
	sAddEntryCompletion  // FirstController for entry update refresh
} SelectFetchTableAction;

@interface GoogleSpreadSheetHelper (PrivateMethods)


- (GDataServiceGoogleSpreadsheet *)spreadsheetService;


- (NSString *) getSpendingTableName;
- (NSString *) getSpendingTableName: (NSString *) spendingTablePrefix withMonth: (NSUInteger) month;

- (GDataEntrySpreadsheetTable *) extractTableFromFeed: (NSString *) tableName;

- (NSArray *) getSpendingRecords: (GDataFeedSpreadsheetRecord *) feed;

- (void) populateCategoryTable;

- (void)fetchAllForSpreadSheet: (GDataEntrySpreadsheet *) spreadsheet;


-(void) initializeSpreadsheetIfReady;

- (void)lookupBaseTables:(NSString*) tableName withWorksheet: (GDataEntryWorksheet*) worksheet;
- (void) createBaseTables:(NSString *)tableName withWorksheet:(GDataEntryWorksheet *)selectedWorksheet;

- (void)fetchSelectedTable:(GDataEntrySpreadsheetTable *)table withAction: (SelectFetchTableAction) action;	

- (NSString *) getWorksheetName:(NSString*) prefix withMonth:(NSUInteger) month;


- (void)addTable: (NSString *) tableName
toSelectedWorksheet: (GDataEntryWorksheet *) selectedWorksheet 
	 withHeaders: (NSArray *) headers
   startRowIndex: (NSInteger) rowIndex
startColumnIndex: (NSInteger) startColumnIndex;


- (void) addRecordToTable:(GDataEntrySpreadsheetTable *) table
			   withFields: (NSArray *) fields withCallback: (BOOL) callback;




- (void) updateRecordToTable:(GDataEntrySpreadsheetTable *) table
				  withRecord: (GDataEntrySpreadsheetRecord *) updatedRecord;


- (void) updateRecordTicket:(GDataServiceTicket *)ticket
		  finishedWithEntry:(GDataEntrySpreadsheetTable *)entry
					  error:(NSError *)error;


- (void) createNewWorksheet: (NSString *) worksheetName;
- (void) createNewWorksheetTicket:(GDataServiceTicket *)ticket
				 finishedWithFeed:(GDataFeedWorksheet *)feed
							error:(NSError *)error;



- (void)deleteTable:(GDataEntrySpreadsheetTable *) selectedTable;
- (void)deleteTableTicket:(GDataServiceTicket *)ticket
		  finishedWithNil:(GDataObject *)nilObj
					error:(NSError *)error;

@end


@implementation GoogleSpreadSheetHelper


@synthesize readOnly;
@synthesize userName;
@synthesize password;
@synthesize categories;
@synthesize allCategories;
@synthesize firstViewController;
@synthesize secondViewController;

@synthesize year;
@synthesize spreadsheetName;


@synthesize spreadsheetEntry;

@synthesize curSpendingEntryDate;
@synthesize curSpendingEntryAmount;
@synthesize curSpendingEntryDesc;
@synthesize curSpendingEntryBeneficiary;
@synthesize curSpendingEntryCategory;

@synthesize worksheetEntry;
@synthesize firstWorksheetEntry;
@synthesize worksheetFeed;
@synthesize worksheetFeedTicket;
@synthesize worksheetFetchError;

@synthesize tableFeed;
@synthesize tableFeedTicket;
@synthesize tableFetchError;

@synthesize recordCategoryFeed;
@synthesize recordCategoryFeedTicket;
@synthesize recordCategoryFetchError;

@synthesize recordSpendingFeed;
@synthesize recordSpendingFeedTicket;
@synthesize recordSpendingFetchError;


@synthesize categoryTable;
@synthesize spendingTable;

@synthesize displayedMonth;
@synthesize displayRecords;


#pragma mark -
#pragma mark inline static methods
static inline BOOL IsEmpty(id thing) {
	return thing == nil
	|| ([thing respondsToSelector:@selector(length)]
		&& [(NSData *)thing length] == 0)
	|| ([thing respondsToSelector:@selector(count)]
		&& [(NSArray *)thing count] == 0);
}
static inline NSString* SelectFetchTableToString(SelectFetchTableAction action) {
	switch (action) {
		case sInitCategory:
			return @"sInitCategory";
		case sInitSpending:
			return @"sInitSpending";
		case sFetchDisplay:
			return @"sFetchDisplay";
		case sUpdateEntryCompletion:
			return @"sUpdateEntryCompletion";
		case sAddEntryCompletion:
			return @"sAddEntryCompletion";
		default:
			NSLog(@"Wouppsss something wrong;");
			return -1;
	}
}

static inline SelectFetchTableAction SelectFetchTableToEnum(NSString * action) {
	if ([action isEqualToString: @"sInitCategory"]) {
		return sInitCategory;
	} else if ([action isEqualToString: @"sInitSpending"]) {
		return sInitSpending;
	} else if ([action isEqualToString: @"sFetchDisplay"]) {
		return sFetchDisplay;
	} else if ([action isEqualToString: @"sUpdateEntryCompletion"]) {
		return sUpdateEntryCompletion;
	} else if ([action isEqualToString: @"sAddEntryCompletion"]) {
		return sAddEntryCompletion;
	} else {
		NSLog(@"Wouppsss something wrong;");
		return -1;
	}
}


+ (NSString *) GetMonthFromIndex:(NSInteger) index {
	switch (index) {
		case 1:
			return @"Jan"; 
		case 2:
			return @"Feb"; 
		case 3:
			return @"Mar"; 
		case 4:
			return @"Apr"; 
		case 5:
			return @"May"; 
		case 6:
			return @"Jun"; 
		case 7:
			return @"Jul"; 
		case 8:
			return @"Aug"; 
		case 9:
			return @"Sep"; 
		case 10:
			return @"Oct"; 
		case 11:
			return @"Nov"; 
		case 12:
			return @"Dec"; 
		default:
			return nil;
	}
}



#pragma mark -
#pragma mark public methods
- (GoogleSpreadSheetHelper*) initialize : (NSInteger) theYear 
			withSpreadsheetName: (NSString*) theSpreadsheetName
		    withSpreadsheet: (GDataEntrySpreadsheet *) theSpreadsheet
			withUsername: (NSString*) username	
			withPwd:(NSString*) pwd
			withCategories:(NSArray*) theCategories
			withFirstController:(FirstViewController *) theFirstController
			withSecondController: (SecondViewController *) theSecondController 
			withCurMonth: (NSInteger) theMonth
			readOnly:(BOOL) isReadOnly
	{
	
	[self setYear: theYear];
	[self setSpreadsheetName:theSpreadsheetName];
	[self setSpreadsheetEntry:theSpreadsheet];
	[self setUserName: username];
	[self setPassword: pwd];
	[self setCategories: theCategories];
	[self setFirstViewController: theFirstController];
	[self setSecondViewController: theSecondController];
	[self setReadOnly:isReadOnly];	
	[self setDisplayedMonth:theMonth];		

	[self  setWorksheetEntry:nil];
	[self  setFirstWorksheetEntry:nil];
	[self  setWorksheetFeed:nil];
	[self  setWorksheetFeedTicket:nil];
	[self  setWorksheetFetchError:nil];

	[self  setTableFeed:nil];
	[self  setTableFeedTicket:nil];
	[self  setTableFetchError:nil];
	
	[self  setRecordCategoryFeed:nil];
	[self  setRecordCategoryFeedTicket:nil];
	[self  setRecordCategoryFetchError:nil];
	
	[self  setRecordSpendingFeed:nil];
	[self  setRecordSpendingFeedTicket:nil];
	[self  setRecordSpendingFetchError:nil];
	
	[self setAllCategories:nil];
	[self setCategoryTable:nil];
	[self setSpendingTable:nil];
	
	[self fetchAllForSpreadSheet:theSpreadsheet];
		
	return self;	
}


- (void) initiateFetchRecordsForTable: (NSUInteger) theMonth {
	

	NSString * tableName = [self getSpendingTableName: SpendingTable withMonth: theMonth];
	
	NSLog(@"Initiating fetching tabke records for table : %@", tableName);
	
	GDataEntrySpreadsheetTable * table = [self extractTableFromFeed: tableName];
	if (table == nil) {
		/*
		 // This is because our current table is called 'Spending' for Spending-2010-10
		 if (year == 2010 && month == 10) {
		 GDataEntrySpreadsheetTable * table = [self extractTableFromFeed: SpendingTable];
		 }
		 */
		if (table == nil) {
			NSLog(@"Could not find table %@", tableName);
			return;
		}
	}
	[self fetchSelectedTable: table withAction: sFetchDisplay];
	[self setDisplayedMonth:theMonth];
}

- (void) addSpendingEntry: (NSString *) date
			   withAmount: (NSString *) amount
				 withDesc: (NSString *) desc
		  withBeneficiary: (NSString *) benef
			 withCategory: (NSString *) category
		  pendingUpToDate: (BOOL) isPendingUpToDate {
	

	if (isPendingUpToDate) {
		
		NSLog(@"Waiting for reinitialization to complete before adding entry");
		
		[self setCurSpendingEntryDate: date];
		[self setCurSpendingEntryAmount: amount];
		[self setCurSpendingEntryDesc: desc];
		[self setCurSpendingEntryBeneficiary: benef];
		[self setCurSpendingEntryCategory: category];

		return;
	};
	
	
	
	GDataSpreadsheetField *field1 = [[GDataSpreadsheetField alloc] init];
	[field1 setValue: date];
	[field1 setName: @"Date"];		
	
	GDataSpreadsheetField *field2 = [[GDataSpreadsheetField alloc] init];
	[field2 setValue: amount];
	[field2 setName: @"Amount"];		
	
	GDataSpreadsheetField *field3 = [[GDataSpreadsheetField alloc] init];
	[field3 setValue: desc];
	[field3 setName: @"Description"];		
	
	GDataSpreadsheetField *field4 = [[GDataSpreadsheetField alloc] init];
	[field4 setValue: benef];
	[field4 setName: @"Beneficiary"];		
	
	GDataSpreadsheetField *field5 = [[GDataSpreadsheetField alloc] init];
	[field5 setValue: category];
	[field5 setName: @"Category"];		
	
	
	NSArray * fields = [[NSArray alloc] initWithObjects:field1, field2, field3, field4, field5, nil];
    [self addRecordToTable: spendingTable withFields: fields withCallback:YES];
	[field1 release];
	[field2 release];
	[field3 release];
	[field4 release];
	[field5 release];
	[fields release];
	
}



- (void) updateSpendingEntry: (NSString *) recordId
				  withAmount: (NSString *) amount
					withDesc: (NSString *) desc
			 withBeneficiary: (NSString *) benef
				withCategory: (NSString *) category {

	
	NSString * tableName = [self getSpendingTableName: SpendingTable withMonth: [self displayedMonth]];
	
	NSLog(@"entryId = %@ amount = %@", recordId, amount);
	
	NSLog(@"Initiating updating record for table : %@", tableName);
	
	GDataEntrySpreadsheetTable * table = [self extractTableFromFeed: tableName];
	if (table == nil) {
		NSLog(@"Could not find table %@", tableName);
		return;
	}
	
	NSArray * records = [self displayRecords];
	
	NSUInteger count  = [records count];
	GDataEntrySpreadsheetRecord *record = nil;
	for (NSUInteger i = 0; i < count; i++) {
		record = [records objectAtIndex:i];
		NSString * theId = [record identifier];
		if ([theId isEqualToString:recordId]) {
			
			NSArray * fields = [record fields];
			NSUInteger c = [fields count];
			
			int countUpdate = 0;
			for (NSUInteger j = 0; j < c; j++) {
				
				GDataSpreadsheetField *field = [fields objectAtIndex:j];
				NSString * fieldName = [field name];
				
				if (fieldName != nil && [fieldName isEqualToString:@"Beneficiary"]) {
					[field setValue:benef];
					countUpdate++;
				}
				else if (fieldName != nil && [fieldName isEqualToString:@"Amount"]) {
					[field setValue:amount];
					countUpdate++;
				}
				else if (fieldName != nil && [fieldName isEqualToString:@"Category"]) {
					[field setValue:category];
					countUpdate++;
				}
				else if (fieldName != nil && [fieldName isEqualToString:@"Description"]) {
					[field setValue:desc];
					countUpdate++;
				}
				if (countUpdate == 4) {
					NSLog(@"Found record %@ to update, will start the update process..", recordId);
					[self updateRecordToTable: table withRecord: record];
					return;
				}
			}
			NSLog(@"Found record %@ to update but failed to update all the fields ??", recordId);
			break;
		}
	}	
	NSLog(@"Failed to update record id = %@", recordId);
}

#pragma mark -
#pragma mark private helper methods


- (NSString *) getWorksheetName:(NSString*) prefix withMonth: (NSUInteger) month {
	
	NSString *thePrefix = nil;
	
	if (prefix == nil) {
		thePrefix = @"";
	} else {
		thePrefix = prefix;
	}
	
	NSString * monthStr = [GoogleSpreadSheetHelper GetMonthFromIndex: month];
	
	NSMutableString *result = [NSMutableString stringWithString:thePrefix];
	[result appendFormat:@"%@-%d", monthStr, [self year]];
	
	return result;
}


- (NSString *) getSpendingTableName: (NSString *) spendingTablePrefix withMonth: (NSUInteger) month {
	// This is because early version wher using different table names.
	if ([ self year] == 2010 && month == 10) {
		return SpendingTable;
	} else {
		
		NSString * result = [[[NSString alloc] initWithFormat: @"%@-%d-%d", spendingTablePrefix, [self year], month] autorelease];
		return result;
	}
}

- (NSString *) getSpendingTableName {
	return [self getSpendingTableName: SpendingTable withMonth:[self displayedMonth]];		
}




#pragma mark -
#pragma mark google initialization

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


///
/// TODO : check resuse of spreadsheetService (and pass as a parameter?)

#pragma mark -
#pragma mark google initialization

- (void)fetchAllForSpreadSheet: (GDataEntrySpreadsheet *) spreadsheet {
	
	if (spreadsheet) {
		
		GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
		
		// fetch the feed of worksheets
		NSURL *worksheetsFeedURL = [spreadsheet worksheetsFeedURL];
		if (worksheetsFeedURL) {
			
			[self setWorksheetFeed:nil];
			[self setWorksheetFetchError:nil];
			
			GDataServiceTicket *ticket;
			ticket = [service fetchFeedWithURL:worksheetsFeedURL
									  delegate:self
							 didFinishSelector:@selector(worksheetsTicket:finishedWithFeed:error:)];
			[self setWorksheetFeedTicket:ticket];
		}
		
		// fetch the feed of tables
		NSURL *tablesFeedURL = [[spreadsheet tablesFeedLink] URL];
		
		// TODO - temporary code -
		// rely just on the link to the tables feed once that finally is available
		if (tablesFeedURL == nil) {
			NSString *key = [[spreadsheet identifier] lastPathComponent];
			NSString *template = @"http://spreadsheets.google.com/feeds/%@/tables";
			NSString *tableFeedURLString = [NSString stringWithFormat:template, key];
			tablesFeedURL = [NSURL URLWithString:tableFeedURLString];
		}
		
		if (tablesFeedURL) {
			
			[self setTableFeed:nil];
			[self setTableFetchError:nil];
			
			// clear the record feed, since the user will need to select a table again
			// and the record feed will be refetched
			[self setRecordCategoryFeed:nil];
			[self setRecordCategoryFetchError:nil];
			[self setRecordSpendingFeed:nil];
			[self setRecordSpendingFetchError:nil];
			
			GDataServiceTicket *ticket;
			ticket = [service fetchFeedWithURL:tablesFeedURL
									  delegate:self
							 didFinishSelector:@selector(tablesTicket:finishedWithFeed:error:)];
			[self setTableFeedTicket:ticket];
		}
		
	}
}


// worksheets feed fetch callback
- (void)worksheetsTicket:(GDataServiceTicket *)ticket
		finishedWithFeed:(GDataFeedWorksheet *)feed
				   error:(NSError *)error {
	
	NSLog(@"Got worksheetsTicket...");
	
	if (error != nil) {
		NSLog(@"Failed to retrieve the list of worksheet, error %@", error);
		return;
	}
	
	[self setWorksheetFeed:feed];
	[self setWorksheetFetchError:error];
	[self setWorksheetFeedTicket:nil];
	[self setFirstWorksheetEntry:nil];
	[self setWorksheetEntry:nil];
	
	[self initializeSpreadsheetIfReady];
}

// tables feed fetch callback
- (void)tablesTicket:(GDataServiceTicket *)ticket
	finishedWithFeed:(GDataFeedSpreadsheetTable *)feed
			   error:(NSError *)error {
	
	NSLog(@"Got tablesTicket...");
	if (error != nil) {
		NSLog(@"Failed to retrieve the list of tables, error %@", error);
		return;
	}
	
	[self setTableFeed:feed];
	[self setTableFetchError:error];
	[self setTableFeedTicket:nil];

	[self initializeSpreadsheetIfReady];
}

-(void) initializeSpreadsheetIfReady {
	
	if ([self readOnly]) {
		[self lookupBaseTables: [self getSpendingTableName] withWorksheet: nil];
		[self lookupBaseTables: CategoryTable withWorksheet: nil];
	} else {
		//
		// If we already got the worksheet entries, check for table creation
		//
		if ([self worksheetEntry]) {
			[self lookupBaseTables: [self getSpendingTableName] withWorksheet: [self worksheetEntry]];
		}
		if ([self firstWorksheetEntry]) {			   
			[self lookupBaseTables: CategoryTable withWorksheet: [self firstWorksheetEntry]];
		}
		//
		// If not, go through the feed and set the entries if exists. 
		//
		if (![self worksheetEntry] || ![self firstWorksheetEntry]) {
			NSString * worksheetName = [self getWorksheetName:nil  withMonth: [self displayedMonth]];
			
			NSLog(@"Looking for worksheet %@", worksheetName);
			
			NSArray *worksheets = [[self worksheetFeed] entries];
			NSUInteger i, count = [worksheets count];
			
			BOOL foundFirstWorksheet = NO;
			BOOL foundWorksheet = NO;	
			for (i = 0; i < count; i++) {
				
				GDataEntryWorksheet *worksheet = [worksheets objectAtIndex:i];
				NSString *title = [[worksheet title] contentStringValue];
				NSLog(@"worksheet title = %@", title);
				if ([title isEqualToString: @"Sheet 1"]) { // || [title isEqualToString: @"Sheet 1"]) {
					[self setFirstWorksheetEntry:worksheet];
					[self lookupBaseTables: CategoryTable withWorksheet: worksheet];
					foundFirstWorksheet = YES;
				}
				
				if ([title isEqualToString: worksheetName]) {
					[self setWorksheetEntry:worksheet];
					[self lookupBaseTables: [self getSpendingTableName] withWorksheet: worksheet];			
					foundWorksheet = YES;
				}
				if (foundWorksheet && foundFirstWorksheet) {
					break;
				}
			}
			//
			// If we need a new spending worksheet entry, create it
			//
			if (!foundWorksheet) {
				[self createNewWorksheet: worksheetName];
			}
			
		}
	}
}

- (void) createNewWorksheet: (NSString *) worksheetName {
	
	NSLog(@"createNewWorksheet %@ worksheetName", worksheetName);
	
	NSURL *postURL = [[[self worksheetFeed] postLink] URL];
	if (worksheetName != nil && postURL != nil) {
		
		GDataEntryWorksheet * newEntry = [[GDataEntryWorksheet alloc] init];
		
		[newEntry setTitleWithString:worksheetName];
		
		GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
		GDataServiceTicket *ticket;
		
		ticket = [service fetchEntryByInsertingEntry:newEntry
										  forFeedURL:postURL
											delegate:self
								   didFinishSelector:@selector(createWorksheetTicket:finishedWithEntry:error:)];
		[newEntry release];
	}
}

- (void) createWorksheetTicket:(GDataServiceTicket *)ticket
			 finishedWithEntry:(GDataEntryWorksheet *)entry
						 error:(NSError *)error {
	
	NSLog(@"Got createWorksheetTicket ");
	if (error != nil) {
		NSLog(@"Failed to add the new worksheet, error %@", error);
		return;
	}
	
	[self setWorksheetEntry:entry];
	[self lookupBaseTables: [self getSpendingTableName]
						  withWorksheet: entry];
}



- (void)lookupBaseTables : (NSString *) tableName
						 withWorksheet: (GDataEntryWorksheet*) selectedWorksheet {
	

	NSLog(@"lookupBaseTables tableName = %@", tableName);
	
	if ([self tableFeed] != nil && [self worksheetFeed] != nil) {
		
		GDataEntrySpreadsheetTable * table = [self extractTableFromFeed:tableName];
		if (table != nil) {
			if ([tableName isEqualToString: CategoryTable]) {
				[self setRecordCategoryFeed:nil];
				[self setRecordCategoryFetchError:nil];				
				[self fetchSelectedTable:table withAction: sInitCategory];
				[self setCategoryTable:table];
			} else {
				[self setRecordSpendingFeed:nil];
				[self setRecordSpendingFetchError:nil];
				[self fetchSelectedTable:table withAction: sInitSpending];				
				[self setSpendingTable: table];
			}
		} else if (selectedWorksheet){
			NSLog(@"createTablesIfNonExistent tableName = %@, worksheet = %@", tableName, [[selectedWorksheet title] contentStringValue]);
			[self createBaseTables: tableName withWorksheet: selectedWorksheet];
		}		
	}
}



- (void) createBaseTables:(NSString *)tableName withWorksheet:(GDataEntryWorksheet *)selectedWorksheet {
	
	
	NSLog(@"createTablesIfNonExistent will create table for tableName = %@, worksheet = %@", tableName, [[selectedWorksheet title] contentStringValue]);
	
	if ([tableName isEqualToString: CategoryTable]) {
		NSArray * headers = [[NSArray alloc] initWithObjects:@"Category", @"Description", nil];
		[self addTable: CategoryTable
   toSelectedWorksheet: selectedWorksheet
		   withHeaders: headers
		 startRowIndex: 1
	  startColumnIndex: 0];
		// Populate table;
		[headers release];
		
	} else {
		
		NSArray * headers = [[NSArray alloc] initWithObjects:@"Date", @"Amount", @"Description", @"Beneficiary", @"Category", nil];
		[self addTable: [self getSpendingTableName]
   toSelectedWorksheet: selectedWorksheet
		   withHeaders: headers
		 startRowIndex: 20
	  startColumnIndex: 4];
		// Populate table;
		[headers release];
		
	}
	
}

- (void)fetchSelectedTable: (GDataEntrySpreadsheetTable *) table withAction: (SelectFetchTableAction) action {
	
	if (table) {
		
		GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
		
		// fetch the feed of records
		NSURL *recordFeedURL = [table recordFeedURL];
		if (recordFeedURL) {
			
			GDataServiceTicket * ticket = [service fetchFeedWithURL:recordFeedURL
														   delegate:self
												  didFinishSelector:@selector(recordsTicket:finishedWithFeed:error:)];
			
			NSString * tableName = [[table title] stringValue];
			[ticket setProperty:tableName
						 forKey:@"tableName"];
			[ticket setProperty: SelectFetchTableToString(action)
						 forKey:@"fetchAction"];

			
			if ([tableName isEqualToString: [self getSpendingTableName]]) {
				[self setRecordSpendingFeedTicket:ticket];
			}
			if ([tableName isEqualToString: CategoryTable]) {
				[self setRecordCategoryFeedTicket:ticket];
			}
		}
	}
}



// records feed fetch callback
- (void)recordsTicket:(GDataServiceTicket *)ticket
     finishedWithFeed:(GDataFeedSpreadsheetRecord *)feed
                error:(NSError *)error {
	
	NSString *tableName = [ticket propertyForKey:@"tableName"];
	SelectFetchTableAction fetchAction = SelectFetchTableToEnum([ticket propertyForKey:@"fetchAction"]);

	NSArray *records = nil;
	switch (fetchAction) {
		case sInitCategory:
			[self setRecordCategoryFeed:feed];
			[self setRecordCategoryFetchError:error];
			[self setRecordCategoryFeedTicket:nil];
			[self populateCategoryTable];
			break;

		case sFetchDisplay:
			[self setDisplayRecords: [feed entries]];
			records = [self getSpendingRecords: feed];
			[[self secondViewController] onRecordsAdded:records withMonth: [self displayedMonth] withYear: [self year] ];
			break;

		case sInitSpending:			
		case sUpdateEntryCompletion:
		case sAddEntryCompletion:
			[self setRecordSpendingFeed:feed];
			[self setRecordSpendingFetchError:error];
			[self setRecordSpendingFeedTicket:nil];
			[self setDisplayedMonth: [self displayedMonth] ];
			[self setDisplayRecords: [feed entries]];		
			records = [self getSpendingRecords: feed];
			[[self secondViewController] onRecordsAdded:records withMonth: [self displayedMonth] withYear: [self year] ];
			break;
		default:
			NSLog(@"Unexpected enum type %d", fetchAction);
			break;
	}
		
	if (error != nil) {
		NSLog(@"Got record feed error = %d for table %@", error, tableName);
	}
}


- (void)addTable: (NSString *) tableName
toSelectedWorksheet: (GDataEntryWorksheet *) selectedWorksheet 
	 withHeaders: (NSArray *) headers
   startRowIndex: (NSInteger) rowIndex
startColumnIndex: (NSInteger) startColumnIndex  {
	
	if (selectedWorksheet == nil) {
		return;
	}
	
	
	NSString *worksheetName = [[selectedWorksheet title] stringValue];
	
	NSURL *postURL = [[[self tableFeed] postLink] URL];
	
	if (worksheetName != nil && postURL != nil) {
		
		GDataEntrySpreadsheetTable *newEntry;
		newEntry = [GDataEntrySpreadsheetTable tableEntry];
		
		
		[newEntry setTitleWithString:tableName];
		[newEntry setWorksheetNameWithString:worksheetName];
		[newEntry setSpreadsheetHeaderWithRow:rowIndex];
		
		GDataSpreadsheetData *spData;
		spData = [GDataSpreadsheetData spreadsheetDataWithStartIndex:(rowIndex+1)
														numberOfRows:1
													   insertionMode:kGDataSpreadsheetModeInsert];
		
		for (int i = 0; i < [headers count]; i++) {
			
			NSString * column = [ColumnsForIndex substringWithRange:NSMakeRange(i + startColumnIndex, 1)];
			NSString * header = [headers objectAtIndex:i];
			
			[spData addColumn:[GDataSpreadsheetColumn columnWithIndexString:column
																	   name:header]];
		}
		[newEntry setSpreadsheetData:spData];
		
		GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
		GDataServiceTicket *ticket;
		
		ticket = [service fetchEntryByInsertingEntry:newEntry
										  forFeedURL:postURL
											delegate:self
								   didFinishSelector:@selector(addTableTicket:finishedWithEntry:error:)];
	}
}

- (void)addTableTicket:(GDataServiceTicket *)ticket
     finishedWithEntry:(GDataEntrySpreadsheetTable *)entry
                 error:(NSError *)error {
	if (error == nil) {
		NSString *tableName = [[entry title] stringValue];
		
		NSString * curSpendingTableName = [self getSpendingTableName];
		
		if ([tableName isEqualToString: CategoryTable]) {
			[self setCategoryTable:entry];
			[ self populateCategoryTable];
			
		} else if ([tableName isEqualToString: curSpendingTableName]) {
			
			[self setSpendingTable:entry];
			
			if ([self curSpendingEntryDate] != nil) {
				
				[self addSpendingEntry:[self curSpendingEntryDate]
							withAmount: [self curSpendingEntryAmount]
							  withDesc: [self curSpendingEntryDesc]
					   withBeneficiary: [self curSpendingEntryBeneficiary]
						  withCategory: [self curSpendingEntryCategory]
					   pendingUpToDate: NO];
				
				[self setCurSpendingEntryDate: nil];
				[self setCurSpendingEntryAmount: nil];
				[self setCurSpendingEntryDesc: nil];
				[self setCurSpendingEntryBeneficiary: nil];
				[self setCurSpendingEntryCategory: nil];
				
			}
			
			
		} else {
			NSLog(@"Got unexpected table %@", tableName);
		}
	} else {
		NSLog(@"Add Table Error %@", error);
	}
}



- (void) populateCategoryTable {
	
	NSLog(@"populateCategoryTable");
	
	if (categoryTable == nil) {
		return;
	}
	
	
	NSMutableArray *allTheCategories = [NSMutableArray arrayWithCapacity:10];
	
	NSArray *existingEntries = [ [self recordCategoryFeed] entries];
	NSUInteger existingCount = [existingEntries count];
	
	int nbEntries = [categories count];
	for (int i = 0; i < nbEntries; i++) {
		
		BOOL found = NO;
		NSString *categoryName = [categories objectAtIndex:i];
		
		[allTheCategories addObject:categoryName];
		
		for (int j = 0; j < existingCount; j++) {
			
			//NSString *desc = [[existingEntries objectAtIndex:j] description];
			//NSLog(@"desc = %@", desc);
			
			NSString *existingEntry = [[[existingEntries objectAtIndex:j] title] contentStringValue];			
			
			if ([existingEntry isEqualToString: categoryName]) {
				NSLog(@"Already found category entry %@", categoryName);
				found = YES;
				break;
			}
		}
		if (!found) {	
			
			
			GDataSpreadsheetField *field1 = [[GDataSpreadsheetField alloc] init];
			[field1 setValue: categoryName];
			[field1 setName: @"Category"];		
			
			NSLog(@"field1 = %@", [field1 description]);
			
			GDataSpreadsheetField *field2 = [[GDataSpreadsheetField alloc] init];
			[field2 setValue: @"whatever"];
			[field2 setName: @"Description"];
			
			NSLog(@"field2 = %@", [field2 description]);
			
			NSArray * fields = [[NSArray alloc] initWithObjects:field1, field2, nil];
			[self addRecordToTable: categoryTable withFields: fields withCallback: FALSE];
			
			[field1 release];
			[field2 release];
			[fields release];
		}
	}
	for (int j = 0; j < existingCount; j++) {
		
		NSString *existingEntry = [[[existingEntries objectAtIndex:j] title] contentStringValue];		
		if (existingEntry != nil && ![existingEntry isEqualToString:@""]) {
			if (![allTheCategories containsObject: existingEntry]) {
				[allTheCategories addObject:existingEntry];
			}
		}
	}
	
	[self setAllCategories:allTheCategories];
	[[self firstViewController] onCategoryCompletion: allTheCategories];
}


- (GDataEntrySpreadsheetTable *) extractTableFromFeed: (NSString *) tableName {
	
	NSArray *tables = [[self tableFeed] entries];
	NSUInteger i, count = [tables count];
	
	GDataEntrySpreadsheetTable * table = nil;		
	for (i = 0; i < count; i++) {
		table = [tables objectAtIndex:i];
		NSString *title = [[table title] contentStringValue ];
		NSLog(@"table title = %@", title);
		
		if ([title isEqualToString: tableName]) {
			return table;
		}
	}
	return nil;
}

- (NSArray*) getSpendingRecords: (GDataFeedSpreadsheetRecord *) feed {
	
	NSMutableArray * result = nil;
	
	NSArray *records =[feed entries];
	NSUInteger count  = [records count];
	for (NSUInteger i = 0; i < count; i++) {
		GDataEntrySpreadsheetRecord *record = [records objectAtIndex:i];
		NSArray *fields = [record fields];
		NSUInteger c = [fields count];
		
		
		NSString * fieldBenef = nil;
		NSString * fieldAmount = nil;
		NSString * fieldDesc = nil;
		NSString * fieldDate = nil;
		NSString * fieldCategory = nil;
		NSString * fieldId = nil;		
		
		NSString * myID = [record identifier];
		//NSLog(@"id = %@", myID);
		
		for (NSUInteger j = 0; j < c; j++) {
			
			
			GDataSpreadsheetField *field = [fields objectAtIndex:j];
			NSString * fieldName = [field name];
			NSString * fieldValue = [field value];
			
			if (fieldName != nil && [fieldName isEqualToString:@"Beneficiary"]) {
				fieldBenef = fieldValue;
			}
			else if (fieldName != nil && [fieldName isEqualToString:@"Amount"]) {
				fieldAmount = fieldValue;
			}
			else if (fieldName != nil && [fieldName isEqualToString:@"Date"]) {
				fieldDate = fieldValue;
			}
			else if (fieldName != nil && [fieldName isEqualToString:@"Category"]) {
				fieldCategory = fieldValue;
			}
			else if (fieldName != nil && [fieldName isEqualToString:@"Description"]) {
				fieldDesc = fieldValue;
			}
			
			
			NSLog(@"name = %@, value = %@",[field name], [field value]);
			
			if (! IsEmpty(fieldBenef)  &&
				! IsEmpty(fieldAmount) &&
				! IsEmpty(fieldDesc)  &&
				! IsEmpty(fieldDate)  &&
				! IsEmpty(fieldCategory)) {				
				NSString * entry = [[[NSString alloc] initWithFormat:@"%@$%@$%@$%@$%@$%@",
									 myID, fieldBenef, fieldAmount, fieldDesc, fieldCategory, fieldDate ] autorelease];
				if (result == nil) {
					result = [[[NSMutableArray alloc] initWithObjects: entry, nil] autorelease];
				} else {
					[result addObject:entry ];
				}
				break;
			}
		}
		NSLog(@"record = %@", [records objectAtIndex:i]);
	}
	return result;
}


#pragma mark -
#pragma mark add records
- (void) addRecordToTable:(GDataEntrySpreadsheetTable *) table
			   withFields: (NSArray *) fields withCallback: (BOOL) callback {
	
	if (table) {
		
		// fetch the feed of records
		NSURL *recordFeedURL = [table recordFeedURL];
		
		GDataEntrySpreadsheetRecord *recordEntry = [[GDataEntrySpreadsheetRecord alloc] init];
		[recordEntry setFields: fields];
		
		
		GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
		GDataServiceTicket *ticket;
		
		ticket = [service fetchEntryByInsertingEntry: recordEntry
										  forFeedURL:recordFeedURL
											delegate:self
								   didFinishSelector:@selector(addRecordTicket:finishedWithEntry:error:)];
		
		[ticket setProperty: callback ? @"YES" : @"NO"
					 forKey:@"callback"];
		
		
		[recordEntry release];
		
	}
}

- (void)addRecordTicket:(GDataServiceTicket *)ticket
	  finishedWithEntry:(GDataEntrySpreadsheetTable *)entry
				  error:(NSError *)error {
	
	NSString *callback = [ticket propertyForKey:@"callback"];
	
	NSLog(@"Added record error = %@", error);
	BOOL success = (error == nil);
	
	if ([callback isEqualToString: @"YES"]) {
		[[self firstViewController] onSubmitCompletion:success isUpdate: NO];
	}
	

	[self setRecordSpendingFeed:nil];
	[self setRecordSpendingFetchError:nil];
	[self fetchSelectedTable: [self spendingTable] withAction:sAddEntryCompletion];
}


#pragma mark -
#pragma mark update records
- (void) updateRecordToTable:(GDataEntrySpreadsheetTable *) table
				  withRecord: (GDataEntrySpreadsheetRecord *) updatedRecord {
	
	
	GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
	GDataServiceTicket *ticket;
	
	
	GDataLink * editLink = [updatedRecord editLink];
	
	ticket = [service  fetchEntryByUpdatingEntry:updatedRecord
									 forEntryURL: [editLink URL]
										delegate: self
							   didFinishSelector: @selector(updateRecordTicket:finishedWithEntry:error:)];
	
	[ticket setProperty:table
				 forKey:@"table"];
	
	
}

- (void) updateRecordTicket:(GDataServiceTicket *)ticket
		  finishedWithEntry:(GDataEntrySpreadsheetRecord *)entry
					  error:(NSError *)error {
	
	NSLog(@"Updated record error = %@", error);
	BOOL success = (error == nil);
	
	GDataEntrySpreadsheetTable * table = [ticket propertyForKey:@"table"];
	
	[[self firstViewController] onSubmitCompletion:success isUpdate: YES];
	
	[self fetchSelectedTable: table withAction:sUpdateEntryCompletion];
}



#pragma mark -
#pragma mark delete table (not used)


- (void)deleteTable:(GDataEntrySpreadsheetTable *) selectedTable {
	
	if (selectedTable) {
		
		GDataServiceGoogleSpreadsheet *service = [self spreadsheetService];
		GDataServiceTicket *ticket;
		
		ticket = [service deleteEntry:selectedTable
							 delegate:self
					didFinishSelector:@selector(deleteTableTicket:finishedWithNil:error:)];
		// save the name in the ticket
		[ticket setProperty:[[selectedTable title] stringValue]
					 forKey:@"tableName"];
	}
}

- (void)deleteTableTicket:(GDataServiceTicket *)ticket
          finishedWithNil:(GDataObject *)nilObj
                    error:(NSError *)error {
	NSLog(@"Deleted table %@ returned %@", [ticket propertyForKey:@"tableName"], error);
}






- (void)dealloc {
	
	
	self.userName = nil;
	self.password = nil;
	
	self.categories = nil;
	self.allCategories = nil;
	
	
	self.firstViewController = nil;
	self.secondViewController = nil;
	
	
    self.spreadsheetName = nil;
	
	self.displayRecords = nil;
	
	self.spreadsheetEntry = nil;
	

	self.curSpendingEntryDate = nil;
	self.curSpendingEntryCategory = nil;
	
	self.worksheetEntry = nil;
	self.firstWorksheetEntry = nil;	
	self.worksheetFeed = nil;
	self.worksheetFeedTicket = nil;
	self.worksheetFetchError = nil;
	
	self.categoryTable = nil;
	self.spendingTable = nil;	
	
	self.tableFeed = nil;
	self.tableFeedTicket = nil;
	self.tableFetchError = nil;
	
	self.recordCategoryFeed = nil;
	self.recordCategoryFeedTicket = nil;
	self.recordCategoryFetchError = nil;
	
	self.recordSpendingFeed = nil;
	self.recordSpendingFeedTicket = nil;
	self.recordSpendingFetchError = nil;
	
    [super dealloc];
}

@end
