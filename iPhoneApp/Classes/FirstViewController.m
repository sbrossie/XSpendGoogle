//
//  FirstViewController.m
//  XSpendGoogle
//
//  Created by Stephane Brossier on 8/4/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "FirstViewController.h"


//
// Private methods
//
@interface FirstViewController()

- (BOOL) validateForm;
- (NSString *) getDate:(NSDate *) date;
- (void) toggleSubmitUpdate:(BOOL) update;
@end


@implementation FirstViewController

@synthesize beneficiary;
@synthesize amount;
@synthesize description;
@synthesize category;
@synthesize button;
@synthesize imageView;
@synthesize spendingCategories;
@synthesize allCategories;
@synthesize currentCategory;
@synthesize datasheetHelper;
@synthesize updateMode;
@synthesize updateEntryId;



- (void) initialize: (NSArray*) categories withDataSheetHelper:(GoogleDataSheetHelper *) helper {

	[self setDatasheetHelper: helper];
	[self setSpendingCategories: categories];
	[self setAllCategories:nil];
	[self setUpdateMode:NO ];
}


static inline BOOL IsEmpty(id thing) {
	return thing == nil
	|| ([thing respondsToSelector:@selector(length)]
		&& [(NSData *)thing length] == 0)
	|| ([thing respondsToSelector:@selector(count)]
		&& [(NSArray *)thing count] == 0);
}

- (BOOL) validateForm {
	/*
	NSLog(@"validate form");
	NSLog(@"beneficiary = %@ [%@]", [beneficiary description], [beneficiary text]);
	NSLog(@"desc = %@ [%@]", [description description], [description text]);
	NSLog(@"amount = %@ [%@]", [amount description], [amount text]);
	NSLog(@"currentCategory = %@", currentCategory);
	*/
	if (IsEmpty(beneficiary.text) ||
		IsEmpty(description.text) ||
		IsEmpty(amount.text) ||
		IsEmpty(currentCategory)) {
		UIAlertView *someError = [[UIAlertView alloc] initWithTitle: @"Form validation" message: @"Need to fill all the fields!" delegate: self cancelButtonTitle: @"Ok" otherButtonTitles: nil];
		[someError show];
		[someError release];
		return NO;
	}
	
	
	NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
	

	NSNumber *number = [formatter numberFromString:amount.text];
	NSLog(@"Number is %@", number);
	
	if (number == nil) {
		UIAlertView *someError = [[UIAlertView alloc] initWithTitle: @"Form validation" message: @"Need to specify a valid amount" delegate: self cancelButtonTitle: @"Ok" otherButtonTitles: nil];
		[someError show];
		[someError release];
		return NO;
	}
	return YES;
}


- (void) onSwitchTab {
	
	[beneficiary setText:@""];
    [amount setText:@""];
    [description setText:@""];
	
	[self toggleSubmitUpdate:NO];
}

- (IBAction)submit:(id)sender {
	
	BOOL valid = [self validateForm];
	if (!valid) {
		return;
	}
	NSMutableString * tmp = [[NSMutableString alloc] initWithFormat: @"Combined "];
	[tmp appendString: beneficiary.text];
	[tmp appendString: @", "];
	[tmp appendString: description.text];
	[tmp appendString: @", "];
	[tmp appendString: amount.text];
	[tmp appendString: @", "];
	[tmp appendString: self.currentCategory];
	NSLog(@"Submit string is %@", tmp);
	[tmp release];
	
	NSDate *date = [NSDate date];
	NSString *formattedDate = [self getDate:date];
	
	if ([self updateMode]) {

		NSLog(@"entryId = %@ amount = %@ ", [self updateEntryId], amount.text);
		
		[datasheetHelper updateSpendingEntry: [self updateEntryId]
								  withAmount: amount.text
									withDesc: description.text
							 withBeneficiary: beneficiary.text
								withCategory: self.currentCategory];
		
	} else {
		[datasheetHelper addSpendingEntry: formattedDate
						   withAmount: amount.text
							 withDesc: description.text
					  withBeneficiary: beneficiary.text
						 withCategory: self.currentCategory];
	}

	
}

- (NSString *) getDate:(NSDate *) date {
	unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSCalendar * gregorian = [NSCalendar currentCalendar];
	NSDateComponents *comps = [gregorian components:unitFlags fromDate:date];
	
	NSInteger year = [comps year];
	NSInteger month = [comps month];
	NSInteger day = [comps day];
	
	NSMutableString *result = [NSMutableString stringWithString:@""];
	[result appendFormat:@"%d/%d/%d", month, day, year];
	
	return result;
}

- (void) updateEntry: (NSString*) entryId withCategory:(NSString *) cat withDate:(NSString *) date withAmount: (NSString*) amnt withDesc: (NSString*) desc withBenef: (NSString*) benef {

	[beneficiary setText:benef];
    [amount setText: amnt];
    [description setText: desc];
	self.currentCategory = cat;

	[self setUpdateEntryId:entryId];
	
	NSArray *categoryList = (self.allCategories == nil) ? [ self spendingCategories] : [self allCategories];
	NSUInteger count = [categoryList count];
	
	int index = -1;
	for (int i = 0; i < count; i++) {
		NSString *cur = [categoryList objectAtIndex:i];
		if ([cur isEqualToString:cat]) {
			index = i;
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow: index inSection:0];
			[category selectRowAtIndexPath: indexPath animated: NO scrollPosition: UITableViewScrollPositionMiddle];
			break;
		}
	}
	
	[self toggleSubmitUpdate:YES];
}

- (void) toggleSubmitUpdate:(BOOL) update {

	if (update) {
		[button setTitle:@"Update" forState:UIControlStateNormal];
		[self setUpdateMode: YES];
	} else {
		[button setTitle:@"Submit" forState:UIControlStateNormal];	
		[self setUpdateMode: NO];
		[self setUpdateEntryId:nil];
	}
}


- (void) onCategoryCompletion: (NSArray *) obj {
	
	NSLog(@"Category completion callback");	
	[self setAllCategories:obj];
	[[self category] reloadData];
}

- (void) onSubmitCompletion: (BOOL) success isUpdate: (BOOL) update {

	UIAlertView *someError =  nil;
	
	NSString * postOk = @"Entry has been posted";
	NSString * updateOk = @"Entry has been updated";

	NSString * postErr = @"Failed to post entry, hum...";
	NSString * updateErr = @"Failed to update entry, hum...";
	
	if (success) {
		someError = [[UIAlertView alloc] initWithTitle: @"Entry status"
											   message: (update) ? updateOk : postOk
											  delegate: self
									 cancelButtonTitle: @"Ok" 
									 otherButtonTitles: nil];
	} else {
		someError = [[UIAlertView alloc] initWithTitle: @"Entry status"
											   message: (update) ? updateErr : postErr
											  delegate: self
									 cancelButtonTitle: @"Ok" 
									 otherButtonTitles: nil];
	}
	[someError show];
	[someError release];

	[beneficiary setText:@""];
    [amount setText:@""];
    [description setText:@""];
	
	if (update) {
		[self toggleSubmitUpdate:NO];
	}
}


- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	
	NSLog(@"Got textFieldShouldReturn....");
	
    if (theTextField == beneficiary) {
		[beneficiary resignFirstResponder];
    }
    if (theTextField == amount) {
        [amount resignFirstResponder];
    }
    if (theTextField == description) {
        [description resignFirstResponder];
    }
	
    return YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	//NSLog(@"Got scrollViewDidScroll");
	
}

#pragma mark -
#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	
	
	const NSInteger CONTENT_LABEL_TAG = 1003;

	UILabel *contentLabel;
	
	

	NSArray *categoryList = (self.allCategories == nil) ? [ self spendingCategories] : [self allCategories];

	UITableViewCell *cell = [ tableView dequeueReusableCellWithIdentifier:@"categoryCell"];
	if (!cell) {
		
		cell =
		[[[UITableViewCell alloc]
		  initWithFrame:CGRectZero
		  reuseIdentifier:@"categoryCell"]
		 autorelease];
		
		const CGFloat LABEL_HEIGHT = 20;
		const CGFloat LABEL_X = 10;
		
		
		
		//
		// Create the label for the top row of text
		//
		contentLabel =
		[[[UILabel alloc]
		  initWithFrame:
		  CGRectMake(
					 LABEL_X,
					 0.5 * (tableView.rowHeight - 2 * LABEL_HEIGHT),
					 tableView.bounds.size.width -
					 LABEL_X - 4.0 * cell.indentationWidth,
					 LABEL_HEIGHT)]
		 autorelease];
		[cell.contentView addSubview:contentLabel];
		
		//
		// Configure the properties for the text that are the same on every row
		//
		contentLabel.tag = CONTENT_LABEL_TAG;
		contentLabel.backgroundColor = [UIColor clearColor];
		contentLabel.textColor = [UIColor colorWithRed:0.25 green:0.0 blue:0.0 alpha:1.0];
		contentLabel.highlightedTextColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.9 alpha:1.0];
		contentLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
		
		cell.backgroundView =
		[[[UIImageView alloc] init] autorelease];
		cell.selectedBackgroundView =
		[[[UIImageView alloc] init] autorelease];
		
		
		
		
		
	} else {
		contentLabel = (UILabel *)[cell viewWithTag:CONTENT_LABEL_TAG];

	}
	
	contentLabel.text = [categoryList  objectAtIndex:indexPath.row];
	
	UIImage *rowBackground;
	UIImage *selectionBackground;
	NSInteger sectionRows = [tableView numberOfRowsInSection:[indexPath section]];
	NSInteger row = [indexPath row];
	
	if (row == 0)
	{
		rowBackground = [UIImage imageNamed:@"topRowClear.png"];
		selectionBackground = [UIImage imageNamed:@"topRowSelected.png"];
	}
	else if (row == sectionRows - 1)
	{
		if (row % 2 == 0) {
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


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	NSArray *categoryList = (self.allCategories == nil) ? [ self spendingCategories] : [self allCategories];
	return [categoryList count];
}



#pragma mark -
#pragma mark UITableViewDelegate protocol
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSArray *categoryList = (self.allCategories == nil) ? [ self spendingCategories] : [self allCategories];
	self.currentCategory = [categoryList  objectAtIndex:indexPath.row];
	
	//self.currentCategory =  [[[[tableView	cellForRowAtIndexPath: indexPath] textLabel] text] retain];
	NSLog(@"Did select cell %@", self.currentCategory);
}

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
	    return self;
	}
	return self;
}


/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
	[super viewDidLoad];
	//
	// Change the properties of the imageView and tableView (these could be set
	// in interface builder instead).
	//
	category.separatorStyle = UITableViewCellSeparatorStyleNone;
	category.rowHeight = 50;
	category.backgroundColor = [UIColor clearColor];
	imageView.image = [UIImage imageNamed:@"gradientBackground.png"];
}



/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

/*
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	NSLog(@"textFieldShouldBeginEditing %@", [textField description]);
}
 */


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	self.beneficiary = nil;
	self.amount = nil;
	self.description = nil;
	self.category = nil;
	self.spendingCategories = nil;
	self.currentCategory = nil;
	self.datasheetHelper = nil;
    [super dealloc];
}


@end
