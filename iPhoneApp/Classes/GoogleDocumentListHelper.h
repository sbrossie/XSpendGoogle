//
//  GoogleDocumentListHelper.h
//  XSpendGoogle
//
//  Created by Stephane Brossier on 9/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "GData.h"

@class GoogleDataSheetHelper;
	
@interface GoogleDocumentListHelper : NSObject {
	
	NSString *mUserName;
	NSString *mPassword;
	GoogleDataSheetHelper * dataSheetHelper;
	
	GDataServiceTicket * docListFetchTicket;
	GDataFeedDocList * docListFeed;
	NSError * docListFetchError;
	
	NSString * newSpreadsheetName;
}

@property (nonatomic, retain) GDataServiceTicket * docListFetchTicket;
@property (nonatomic, retain) GDataFeedDocList * docListFeed;
@property (nonatomic, retain) NSError * docListFetchError;
@property (nonatomic, retain) NSString * newSpreadsheetName;
@property (nonatomic, retain) GoogleDataSheetHelper * dataSheetHelper;

- (GoogleDocumentListHelper *) initialize: (NSString *) username withPwd: (NSString *) pwd withDataSheetHelper: (GoogleDataSheetHelper *) dataSheetHelper;
- (void) createEmptySpreadsheet:(NSString *) spreadsheetName;

@end

