//
//  SecondViewController.h
//  XSpendGoogle
//
//  Created by Stephane Brossier on 10/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//



#import <UIKit/UIKit.h>

#import "GoogleDataSheetHelper.h"

@class XSpendGoogleAppDelegate;

@class UISearchDisplayControllerWithBackground;

@interface SecondViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UISearchDisplayDelegate> {

	UILabel *footerLabel;
	UILabel *sfooterLabel;	

	UITextView *date;
	UITableView *tableEntries;
	UIImageView *imageView;
	
	UISearchBar *searchBar;
	UISearchDisplayControllerWithBackground *searchDC;
	
	NSString *displayDate;
	
	NSArray *dataEntries;
	NSString *selectedRow;
	XSpendGoogleAppDelegate *appDelegate;
	
	NSArray *filteredEntries;

	NSUInteger displayedMonth;
	NSUInteger displayedYear;
	
	GoogleDataSheetHelper *datasheetHelper;
}

@property (nonatomic, retain) IBOutlet UITableView *tableEntries;
@property (nonatomic, retain) IBOutlet UITextView *date;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) NSArray *dataEntries;
@property (nonatomic, retain) NSString* displayDate;
@property (nonatomic, retain) GoogleDataSheetHelper *datasheetHelper;
@property (nonatomic, retain) NSString * selectedRow;
@property (nonatomic) NSUInteger displayedMonth;
@property (nonatomic) NSUInteger displayedYear;
@property (nonatomic,retain) XSpendGoogleAppDelegate *appDelegate;
@property (nonatomic, retain) UILabel *footerLabel;

@property (nonatomic, retain) UILabel *sfooterLabel;

@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) UISearchDisplayControllerWithBackground *searchDC;

@property (nonatomic, retain)  NSArray* filteredEntries;

- (void) initialize: (GoogleDataSheetHelper *) dataSheetHelper withAppDelegate: (XSpendGoogleAppDelegate *) appDelegate;
- (IBAction) prevMonth:(id)sender;
- (IBAction) nextMonth:(id)sender;


- (void) onRecordsAdded: (NSArray*) records withMonth: (NSUInteger) month withYear: (NSUInteger) year;
- (void) onSwitchTab;

@end

