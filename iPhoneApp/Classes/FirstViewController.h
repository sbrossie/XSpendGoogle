//
//  FirstViewController.h
//  XSpendGoogle
//
//  Created by Stephane Brossier on 8/4/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GoogleDataSheetHelper.h"

@interface FirstViewController : UIViewController<UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate> {

	UIImageView *imageView;
	UITextField *beneficiary;
	UITextField *amount;
	UITextField *description;
	UITableView *category;
	UIButton *button;
	
	NSArray *spendingCategories;
	NSArray *allCategories;	
	NSString *currentCategory;
	
	BOOL updateMode;
	
	NSString * updateEntryId;
	
	GoogleDataSheetHelper *datasheetHelper;
}

@property (nonatomic, retain) IBOutlet UITextField *beneficiary;
@property (nonatomic, retain) IBOutlet UITextField *amount;
@property (nonatomic, retain) IBOutlet UITextField *description;
@property (nonatomic, retain) IBOutlet UITableView *category;
@property (nonatomic, retain) IBOutlet UIButton *button;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;

@property (nonatomic) BOOL updateMode;
@property (nonatomic, retain) NSString * updateEntryId;
@property (nonatomic, retain) NSArray *spendingCategories;
@property (nonatomic, retain) NSArray *allCategories;
@property (nonatomic, retain) NSString *currentCategory;
@property (nonatomic, retain) GoogleDataSheetHelper * datasheetHelper;


- (IBAction)submit:(id)sender;
- (void) initialize: (NSArray*) categories withDataSheetHelper:(GoogleDataSheetHelper *) dataSheetHelper;


- (void) onCategoryCompletion: (NSArray *) allCategories;
- (void) onSubmitCompletion: (BOOL) success isUpdate: (BOOL) update;

- (void) updateEntry: (NSString*) entryId withCategory:(NSString *) category withDate:(NSString *) date withAmount: (NSString*) amount withDesc: (NSString*) desc withBenef: (NSString*) benef;

- (void) onSwitchTab;

@end
