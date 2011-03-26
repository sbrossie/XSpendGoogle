//
//  GoogleDocumentListHelper.m
//  XSpendGoogle
//
//  Created by Stephane Brossier on 9/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GoogleDocumentListHelper.h"

#import "GDataHTTPFetcherLogging.h"

@interface GoogleDocumentListHelper (PrivateMethods) 

- (GDataServiceGoogleDocs *)docsService;
- (void)fetchDocList;
- (void)docListFetchTicket:(GDataServiceTicket *)ticket 
          finishedWithFeed:(GDataFeedDocList *)feed 
                     error:(NSError *)error;
- (void)uploadBlankSpreadsheetToDocListFeed:(GDataFeedDocList *)docListFeed withName: (NSString*) name;
- (void)createSpreadsheetTicket:(GDataServiceTicket *)ticket 
			  finishedWithEntry:(GDataEntrySpreadsheetDoc *)entry 
						  error:(NSError *)error;


- (void) setUsername: (NSString *) username;
- (NSString *) getUsername;
- (void) setPassword: (NSString *) pwd;
- (NSString *) getPassword;

@end

@implementation GoogleDocumentListHelper

@synthesize docListFetchTicket;
@synthesize docListFeed;
@synthesize docListFetchError;
@synthesize newSpreadsheetName;
@synthesize dataSheetHelper;

static GDataServiceGoogleDocs* service = nil; 


- (GoogleDocumentListHelper *) initialize: (NSString *) username withPwd: (NSString *) pwd withDataSheetHelper: (GoogleDataSheetHelper *) helper {
	
	// STEPH
	// LOGGING ON...
	[GDataHTTPFetcher setIsLoggingEnabled:YES];

	[self setUsername: username];
	[self setPassword: pwd];
	[self setNewSpreadsheetName: nil];
	[self setDataSheetHelper: helper];
	[self fetchDocList];
	return self;
}

- (void) createEmptySpreadsheet:(NSString *) spreadsheetName {
	if ([self docListFeed] == nil) {
		[self setNewSpreadsheetName: spreadsheetName];
	} else {
		[self uploadBlankSpreadsheetToDocListFeed: [self docListFeed] withName: spreadsheetName];
		
	}
}




- (GDataServiceGoogleDocs *)docsService { 
	if (!service) { 
		service = [[GDataServiceGoogleDocs alloc] init]; 
		[service setShouldCacheDatedData:YES]; 
		[service setServiceShouldFollowNextLinks:YES]; 
		[service setIsServiceRetryEnabled:YES]; 
	} 
	[service setUserCredentialsWithUsername:mUserName 
										password:mPassword];
	
	return service; 
} 


- (void)fetchDocList { 
	
	[self setDocListFeed:nil]; 
	[self setDocListFetchError:nil]; 
	[self setDocListFetchTicket:nil]; 

	GDataServiceGoogleDocs *service = [self docsService]; 
	GDataServiceTicket *ticket; 
	
	NSURL *feedURL = [GDataServiceGoogleDocs docsFeedURLUsingHTTPS:YES]; 
	GDataQueryDocs *query = [GDataQueryDocs 
							 documentQueryWithFeedURL:feedURL]; 
	[query setMaxResults:100]; 
	[query setShouldShowFolders:NO]; 
	ticket = [service fetchFeedWithQuery:query 
								delegate:self 
					   didFinishSelector:@selector(docListFetchTicket:finishedWithFeed:error:)]; 
	[self setDocListFetchTicket:ticket]; 

} 


- (void)docListFetchTicket:(GDataServiceTicket *)ticket 
          finishedWithFeed:(GDataFeedDocList *)feed 
                     error:(NSError *)error { 

	[self setDocListFeed:feed]; 
	[self setDocListFetchError:error]; 
	[self setDocListFetchTicket:nil]; 
						 
	if ([self newSpreadsheetName] != nil) {
		[self uploadBlankSpreadsheetToDocListFeed: [self docListFeed] withName: [self newSpreadsheetName] ];
		[self setNewSpreadsheetName: nil];
	}
} 


- (void)uploadBlankSpreadsheetToDocListFeed:(GDataFeedDocList *) feed withName: (NSString *) name
{ 
	GDataEntrySpreadsheetDoc *newEntry = [GDataEntrySpreadsheetDoc 
										  documentEntry]; 
	[newEntry setTitleWithString:name]; 
	NSURL *postURL = [[feed postLink] URL]; 

	GDataServiceGoogleDocs *service = [self docsService];
	GDataServiceTicket *ticket = nil;
	
	// STEPH
	NSData * xmlData = [[newEntry XMLDocument] XMLData];
	NSString* aStr = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
	NSLog(@"xml = %@", aStr);
	[aStr release];
	
	ticket = [service fetchEntryByInsertingEntry:newEntry 
							 forFeedURL:postURL 
							   delegate:self 
					  didFinishSelector:@selector 
	 (createSpreadsheetTicket:finishedWithEntry:error:)]; 
	
	[ticket setProperty:name
				 forKey:@"title"];
} 

- (void)createSpreadsheetTicket:(GDataServiceTicket *)ticket 
			  finishedWithEntry:(GDataEntrySpreadsheetDoc *)entry 
						  error:(NSError *)error { 
	NSLog(@"new spreadsheet entry: %@ \nerror:%@", entry, error); 
	if (error == nil) {
		[[self dataSheetHelper] onNewSpreadsheetCreated: [ticket propertyForKey:@"title"]];
	}
								  
}


#pragma mark Setters and Getters

- (void) setUsername: (NSString *) username {
	[mUserName autorelease];
	mUserName = [username retain];
}

- (NSString *) getUsername {
	return mUserName;
}

- (void) setPassword: (NSString *) pwd {
	[mPassword autorelease];
	mPassword = [pwd retain];
}

- (NSString *) getPassword {
	return mPassword;
}


- (void)dealloc {

	
	[self setUsername:nil];
	[self setPassword:nil];
    self.dataSheetHelper = nil;
	
	self.docListFetchTicket = nil;
	self.docListFeed = nil;
	self.docListFetchError = nil;
	
	self.newSpreadsheetName = nil;
	[super dealloc];
}
@end
