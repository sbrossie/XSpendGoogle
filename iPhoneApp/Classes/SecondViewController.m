//
//  SecondViewController.m
//  XSpendGoogle
//
//  Created by Stephane Brossier on 10/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SecondViewController.h"

#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@interface UISearchDisplayControllerWithBackground : UISearchDisplayController {
	UIImageView * schImage;
}

@end

@interface SecondViewController (PrivateMethods)
- (float) totalSpendingForDisplayedMonth: (BOOL) fromSearch;
- (void) refreshTotalSpending: (BOOL) fromSearch;
- (void) performFiltering;
- (void) initSearch;
- (void) reInitSearchAttributes;

@end



@implementation UISearchDisplayControllerWithBackground


- (void)viewDidLoad
{
	[super viewDidLoad];
	schImage = [[UIImageView alloc] initWithImage: [UIImage imageNamed:@"gradientBackground.png"]];
}

@end


@implementation SecondViewController

@synthesize footerLabel;
@synthesize date;
@synthesize tableEntries;
@synthesize imageView;
@synthesize dataEntries;
@synthesize datasheetHelper;
@synthesize selectedRow;
@synthesize appDelegate;
@synthesize displayDate;
@synthesize displayedMonth;
@synthesize displayedYear;

@synthesize searchBar;
@synthesize searchDC;
@synthesize filteredEntries;
@synthesize sfooterLabel;

const CGFloat LABEL_HEIGHT = 20;
const CGFloat LABEL_X = 50;
const CGFloat ROW_HEIGHT = 60;
const CGFloat FOOTER_HEIGHT = 38;


- (void) initialize: (GoogleDataSheetHelper *) dataSheetHelper withAppDelegate: (XSpendGoogleAppDelegate *) theAppDelegate {
	[self setDatasheetHelper:dataSheetHelper];
	[self setAppDelegate: theAppDelegate];
	[self setFilteredEntries:nil];
}

- (void)viewDidLoad
{
	//
	// Change the properties of the imageView and tableView (these could be set
	// in interface builder instead).
	//
	tableEntries.separatorStyle = UITableViewCellSeparatorStyleNone;
	tableEntries.rowHeight = ROW_HEIGHT;
	tableEntries.backgroundColor = [UIColor clearColor];
	
	imageView.image = [UIImage imageNamed:@"gradientBackground.png"];
	
	self.footerLabel = 
	[[UILabel alloc]
	  initWithFrame:
	  CGRectMake(
				 LABEL_X,
				 0,
				 200,
				 FOOTER_HEIGHT)];

	footerLabel.backgroundColor =  [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
	[footerLabel setTextColor: UIColorFromRGB(0xe78b14)];
	[tableEntries setTableFooterView:footerLabel];
//	[tableEntries tableHeaderView.backgroundView] 

	UIView * headerView = [tableEntries tableHeaderView];
	headerView.backgroundColor = UIColorFromRGB(0xc2c2c2); //backgroundView =  [UIImage imageNamed:@"middleRow.png"]; //[[[UIImageView alloc] init] autorelease];
	
	
	[self initSearch];

	[self refreshTotalSpending: NO];
}

- (void) initSearch
{
	self.searchBar = [[[UISearchBar alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 44.0f)] autorelease];
	//self.searchBar.tintColor = ;
	self.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.searchBar.keyboardType = UIKeyboardTypeAlphabet;
	
	UISearchDisplayControllerWithBackground * tmp = [UISearchDisplayControllerWithBackground alloc];
	//self.searchDC = [tmp initWithSearchBar:self.searchBar contentsController:self];
	self.searchDC = [[tmp initWithSearchBar:self.searchBar contentsController:self] autorelease];	
	//self.searchDC = [[[[UISearchDisplayControllerWithBackground alloc] initWithSearchBar:self.searchBar contentsController:self] setImage ] autorelease];

	
	sfooterLabel = 
	[[UILabel alloc]
	 initWithFrame:
	 CGRectMake(
				LABEL_X,
				0,
				200,
				FOOTER_HEIGHT)];
	sfooterLabel.backgroundColor =  [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
	[sfooterLabel setTextColor: UIColorFromRGB(0xe78b14)];
	
	[self reInitSearchAttributes];

	self.tableEntries.tableHeaderView = self.searchBar;	
}

- (void) reInitSearchAttributes
{
	
	self.searchDC.searchResultsDataSource = self;
	self.searchDC.searchResultsDelegate = self;	
	self.searchDC.delegate = self;
	
	self.searchDC.searchResultsTableView.backgroundColor = [[[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"gradientBackground.png"]] autorelease];
	self.searchDC.searchResultsTableView.rowHeight = ROW_HEIGHT;
		
	[self.searchDC.searchResultsTableView setTableFooterView:sfooterLabel];
}


- (void) performFiltering
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", self.searchBar.text];
	[self setFilteredEntries:[self.dataEntries filteredArrayUsingPredicate:predicate]];
}

#pragma mark -
#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (UITableViewCell *)tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	

	const NSInteger TOP_LABEL_TAG = 1001;
	const NSInteger BOTTOM_LABEL_TAG = 1002;
	UILabel *topLabel;
	UILabel *bottomLabel;


	BOOL fromSearch = (tableView == self.tableEntries) ? NO : YES;
	
	NSString *tableName = [[[NSString alloc] initWithFormat: @"display-%d-%d", displayedYear, displayedMonth] autorelease];
	UITableViewCell *cell = [ tableView dequeueReusableCellWithIdentifier:tableName];
	if (cell == nil)
	{
		//
		// Create the cell.
		//
		cell =
		[[[UITableViewCell alloc]
		  initWithFrame:CGRectZero
		  reuseIdentifier:tableName]
		 autorelease];
	
		
		//
		// Create the label for the top row of text
		//
		topLabel =
		[[[UILabel alloc]
		  initWithFrame:
		  CGRectMake(
					 LABEL_X,
					 0.5 * (tableView.rowHeight - 2 * LABEL_HEIGHT),
					 tableView.bounds.size.width -
					 LABEL_X - 4.0 * cell.indentationWidth,
					 LABEL_HEIGHT)]
		 autorelease];
		[cell.contentView addSubview:topLabel];
		
		//
		// Configure the properties for the text that are the same on every row
		//
		topLabel.tag = TOP_LABEL_TAG;
		topLabel.backgroundColor = [UIColor clearColor];
		topLabel.textColor = [UIColor colorWithRed:0.25 green:0.0 blue:0.0 alpha:1.0];
		topLabel.highlightedTextColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.9 alpha:1.0];
		topLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
		
		//
		// Create the label for the top row of text
		//
		bottomLabel =
		[[[UILabel alloc]
		  initWithFrame:
		  CGRectMake(
					 LABEL_X,
					 0.5 * (tableView.rowHeight - 2 * LABEL_HEIGHT) + LABEL_HEIGHT,
					 tableView.bounds.size.width -
					 LABEL_X - 4.0 * cell.indentationWidth,
					 LABEL_HEIGHT)]
		 autorelease];
		[cell.contentView addSubview:bottomLabel];
		
		//
		// Configure the properties for the text that are the same on every row
		//
		bottomLabel.tag = BOTTOM_LABEL_TAG;
		bottomLabel.backgroundColor = [UIColor clearColor];
		bottomLabel.textColor = [UIColor colorWithRed:0.25 green:0.0 blue:0.0 alpha:1.0];
		bottomLabel.highlightedTextColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.9 alpha:1.0];
		bottomLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize] - 2];
		
		//
		// Create a background image view.
		//
		cell.backgroundView =
		[[[UIImageView alloc] init] autorelease];
		cell.selectedBackgroundView =
		[[[UIImageView alloc] init] autorelease];
	}
	

	else
	{
		topLabel = (UILabel *)[cell viewWithTag:TOP_LABEL_TAG];
		bottomLabel = (UILabel *)[cell viewWithTag:BOTTOM_LABEL_TAG];
	}

	NSString * rawText = (fromSearch) ? 
	[self.filteredEntries objectAtIndex:indexPath.row] :
	[self.dataEntries objectAtIndex:indexPath.row];	
	

	//fieldId, fieldBenef, fieldAmount, fieldDesc, fieldCategory, fieldDate
	NSArray * splits = [rawText componentsSeparatedByString:@"$"];
	
	topLabel.text = [NSString stringWithFormat:@"%@ ($ %@)", [splits objectAtIndex:1],[splits objectAtIndex:2]];
	bottomLabel.text = [NSString stringWithFormat:@"%@ [%@]", [splits objectAtIndex:5], [splits objectAtIndex:4]];
	
	//
	// Set the background and selected background images for the text.
	// Since we will round the corners at the top and bottom of sections, we
	// need to conditionally choose the images based on the row index and the
	// number of rows in the section.
	//
	UIImage *rowBackground;
	UIImage *selectionBackground;
	NSInteger sectionRows = [tableView numberOfRowsInSection:[indexPath section]];
	NSInteger row = [indexPath row];
	/*
	if (row == 0 && row == sectionRows - 1)
	{
		rowBackground = [UIImage imageNamed:@"topAndBottomRow.png"];
		selectionBackground = [UIImage imageNamed:@"topAndBottomRowSelected.png"];
	}*/
	if (row == 0)
	{
		rowBackground = [UIImage imageNamed:@"topRowClear.png"];
		selectionBackground = [UIImage imageNamed:@"topRowSelected.png"];
	}
	else if (row == sectionRows - 1)
	{
		if (row % 2 == 1) {
			rowBackground = [UIImage imageNamed:@"bottomRow.png"];
		} else {
			rowBackground = [UIImage imageNamed:@"bottomRowClear.png"];
		}
		selectionBackground = [UIImage imageNamed:@"bottomRowSelected.png"];
	}
	else
	{
		if (row % 2 == 0) {
			rowBackground = [UIImage imageNamed:@"middleRowClear.png"];
		} else {
			rowBackground = [UIImage imageNamed:@"middleRow.png"];
		}
		selectionBackground = [UIImage imageNamed:@"middleRowSelected.png"];
	}
	((UIImageView *)cell.backgroundView).image = rowBackground;
	((UIImageView *)cell.selectedBackgroundView).image = selectionBackground;
	
	return cell;
	
}


- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)aSection {

	if (aTableView == self.tableEntries) {
		return [[self dataEntries] count];		
	} else {
		[self performFiltering];
		NSLog(@"Got [%d/%d]", [[self filteredEntries] count], [[self dataEntries] count]);
		[self refreshTotalSpending: YES];
		return [[self filteredEntries] count];
	}
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {    
    return ROW_HEIGHT;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
	NSLog(@"didLoadSearchResultsTableView");
}


- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView {
	NSLog(@"..didShowSearchResultsTableView");
	[self reInitSearchAttributes];
}

- (void) onSwitchTab {
	[self.date setTextColor: UIColorFromRGB(0xe78b14)];
	[self.date setText: self.displayDate];	
	//[self initSearch];
}

#pragma mark -
#pragma mark UITableViewDelegate protocol
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	// fieldId, fieldBenef, fieldAmount, fieldDesc, fieldCategory, fieldDate 
	BOOL fromSearch = (tableView == self.tableEntries) ? NO : YES;
	NSArray * array = (fromSearch) ? self.filteredEntries : self.dataEntries; 

	NSString * rawText = [array objectAtIndex:indexPath.row];
	NSArray * splits = [rawText componentsSeparatedByString:@"$"];
	[appDelegate updateEntry: [splits objectAtIndex:0]
				withCategory: [splits objectAtIndex:4]
					withDate: [splits objectAtIndex:5]
				  withAmount: [splits objectAtIndex: 2]
					withDesc: [splits objectAtIndex: 3]
				   withBenef: [splits objectAtIndex: 1]];
	//[splits release];
}

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
	    return self;
	}
	return self;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void) refreshTotalSpending: (BOOL) fromSearch {
	
	NSLog(@"refreshTotalSpending.....");
	float totalSpending = [self totalSpendingForDisplayedMonth: fromSearch]; 
	NSString * footerText = [[[NSString alloc] initWithFormat: @"Total : %.2f", totalSpending ]  autorelease];

	if (fromSearch) {
		NSLog(@"sfooterLabel %@", [self.sfooterLabel description]);		
		[self.sfooterLabel setText: footerText];
	} else {
		NSLog(@"footerLabel %@", [self.footerLabel description]);
		[self.footerLabel setText: footerText];
	}
}

- (void) onRecordsAdded: (NSArray*) records withMonth: (NSUInteger) month withYear: (NSUInteger) year {
	
	self.displayedMonth = month;
	self.displayedYear = year;
	
	NSString * monthStr = [GoogleSpreadSheetHelper GetMonthFromIndex: month];
	self.displayDate = [[[NSString alloc] initWithFormat: @"%@-%d", monthStr, year]  autorelease];
	[self.date setText: self.displayDate];
	
	[self setDataEntries:records];
	
	
	[self refreshTotalSpending:NO];
	
	// Reload the table
	[[self tableEntries] reloadData];
}

- (IBAction) prevMonth:(id)sender {
	
	NSUInteger prevMonth = (displayedMonth > 1) ? displayedMonth - 1 : 12;
	NSUInteger prevYear = (prevMonth == 12) ? displayedYear - 1 : displayedYear;
	
	[datasheetHelper initiateFetchRecordsForTable: prevYear andMonth: prevMonth];
}

- (IBAction) nextMonth:(id)sender {
	
	NSUInteger nextMonth = (displayedMonth < 12) ? displayedMonth + 1 : 1;
	NSUInteger nextYear = (nextMonth == 1) ? displayedYear + 1 : displayedYear;	

	[datasheetHelper initiateFetchRecordsForTable: nextYear andMonth: nextMonth];
}


- (void)dealloc {
	self.tableEntries = nil;
	self.dataEntries = nil;
	self.datasheetHelper = nil;
	self.filteredEntries = nil;
	self.searchBar = nil;
    [super dealloc];
}


- (float) totalSpendingForDisplayedMonth: (BOOL) fromSearch {
	
	float total = 0;
	
	NSArray * array = (fromSearch) ? self.filteredEntries : self.dataEntries; 
	int count = [array count];

	NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];

	for (int i = 0; i < count; i++) {
		NSString * rawText = [array objectAtIndex:i];
		//fieldId, fieldBenef, fieldAmount, fieldDesc, fieldCategory, fieldDate
		NSArray * splits = [rawText componentsSeparatedByString:@"$"];
		NSNumber *number = [formatter numberFromString: [splits objectAtIndex:2]];
		total += [number floatValue];
	}
	return total;
}

@end
