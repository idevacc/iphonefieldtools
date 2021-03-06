// Copyright 2011 Brad Sokol
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
// http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//
//  SubjectDistanceRangesViewController.m
//  FieldTools
//
//  Created by Brad Sokol on 2011-08-23.
//  Copyright 2011 by Brad Sokol. All rights reserved.
//

#import "SubjectDistanceRangesViewController.h"

#import "Notifications.h"
#import "UserDefaults.h"

@interface SubjectDistanceRangesViewController ()

- (void)cancelWasSelected;
- (void)saveWasSelected;

@property(nonatomic, retain) UIBarButtonItem* saveButton;
@property(nonatomic) int newSubjectDistanceRangeIndex;

@end

@implementation SubjectDistanceRangesViewController

@synthesize newSubjectDistanceRangeIndex, saveButton, tableViewDataSource;

// The designated initializer.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (nil == self) 
    {
		return nil;
    }
	
	UIBarButtonItem* cancelButton = 
	[[[UIBarButtonItem alloc] 
	  initWithBarButtonSystemItem:UIBarButtonSystemItemCancel									 
	  target:self
	  action:@selector(cancelWasSelected)] autorelease];
	[self setSaveButton:[[[UIBarButtonItem alloc] 
                          initWithBarButtonSystemItem:UIBarButtonSystemItemSave	 
                          target:self
                          action:@selector(saveWasSelected)] autorelease]];
	
	[[self navigationItem] setLeftBarButtonItem:cancelButton];
	[[self navigationItem] setRightBarButtonItem:saveButton];
	
	[self setTitle:NSLocalizedString(@"SUBJECT_DISTANCE_RANGES_VIEW_TITLE", "subject distance ranges view")];
    
    newSubjectDistanceRangeIndex = [[NSUserDefaults standardUserDefaults] integerForKey:FTSubjectDistanceRangeKey];
    
	return self;
}

- (void)cancelWasSelected
{
	[[self navigationController] popViewControllerAnimated:YES];
}

- (void)saveWasSelected
{
    int oldSubjectDistanceRangeIndex = [[NSUserDefaults standardUserDefaults] integerForKey:FTSubjectDistanceRangeKey];
    if (newSubjectDistanceRangeIndex != oldSubjectDistanceRangeIndex)
    {
        [[NSUserDefaults standardUserDefaults] setInteger:newSubjectDistanceRangeIndex
                                                   forKey:FTSubjectDistanceRangeKey];
        
        [[NSNotificationCenter defaultCenter] 
            postNotification:[NSNotification notificationWithName:SUBJECT_DISTANCE_RANGE_CHANGED_NOTIFICATION object:nil]];
        
        NSError *error;
        if (![[GANTracker sharedTracker] trackEvent:kCategorySubjectDistanceRange
                                             action:kActionChanged
                                              label:kLabelSettingsView
                                              value:newSubjectDistanceRangeIndex
                                          withError:&error]) 
        {
            NSLog(@"Error recording analytics page view: %@", error);
        }

    }
    
	[[self navigationController] popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    NSError *error;
    if (![[GANTracker sharedTracker] trackPageview:kSettingsSubjectDistanceRanges withError:&error]) 
    {
        NSLog(@"Error recording analytics page view: %@", error);
    }
	
	[[self view] setBackgroundColor:[UIColor viewFlipsideBackgroundColor]];
	
    UITableView* tv = [self tableView];
    SubjectDistanceRangesViewTableDataSource* sdrvtds = 
        (SubjectDistanceRangesViewTableDataSource*) [tv dataSource];
    [self setTableViewDataSource:sdrvtds];
	[self setTableViewDataSource:(SubjectDistanceRangesViewTableDataSource*)[[self tableView] dataSource]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath
							 animated:YES];

	NSIndexPath* oldIndexPath = [NSIndexPath indexPathForRow:newSubjectDistanceRangeIndex
												   inSection:[indexPath section]];
	
	if ([oldIndexPath row] == [indexPath row])
	{
		// User selected the currently selected units - take no action
		return;
	}
	
	UITableViewCell* newCell = [tableView cellForRowAtIndexPath:indexPath];
	if ([newCell accessoryType] == UITableViewCellAccessoryNone)
	{
		// Selected row is not the current distance rabge so change the selection
		[newCell setAccessoryType:UITableViewCellAccessoryCheckmark];
		
        newSubjectDistanceRangeIndex = [indexPath row];
	}
	
	UITableViewCell* oldCell = [tableView cellForRowAtIndexPath:oldIndexPath];
	if ([oldCell accessoryType] == UITableViewCellAccessoryCheckmark)
	{
		[oldCell setAccessoryType:UITableViewCellAccessoryNone];
	}
}

- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self setSaveButton:nil];
    [self setTableViewDataSource:nil];
	
    [super dealloc];
}

@end
