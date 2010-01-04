// Copyright 2009 Brad Sokol
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
//  FlipsideTableViewDataSource.m
//  FieldTools
//
//  Created by Brad on 2009/05/28.
//  Copyright 2009 Brad Sokol. All rights reserved.
//

#import "FlipsideTableViewDataSource.h"

#import "Camera.h"
#import "CoC.h"
#import "Lens.h"
#import "Notifications.h"
#import "UserDefaults.h"

const NSInteger SECTION_COUNT = 3;
const NSInteger UNITS_COUNT = 3;

// Enumerate sections in UITable
const NSInteger LENSES_SECTION = 0;
const NSInteger CAMERAS_SECTION = 1;
const NSInteger UNITS_SECTION = 2;

static NSString *CellIdentifier = @"Cell";

// Private methods
@interface FlipsideTableViewDataSource (Private)

- (UITableViewCell*) cellForCameraRowAtIndexPath:(NSIndexPath*)indexPath inTableView:(UITableView*) tableView;
- (UITableViewCell*) cellForLensRowAtIndexPath:(NSIndexPath*)indexPath inTableView:(UITableView*) tableView;
- (UITableViewCell*) cellForUnitsRowAtIndexPath:(NSIndexPath*)indexPath inTableView:(UITableView*)tableView;
- (void)deleteCameraAtIndexPath: (NSIndexPath *) indexPath inTableView:(UITableView*)tableView;
- (void)deleteLensAtIndexPath: (NSIndexPath *) indexPath inTableView:(UITableView*)tableView;
- (UITableViewCell*) standardCellForTableView:(UITableView*)tableView;

@end

@implementation FlipsideTableViewDataSource

@synthesize editing;

#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	// When in edit mode, add one more row for inserting new items.
	int adjustment = [self isEditing] ? 1 : 0;
	
	if (section == CAMERAS_SECTION)
	{
		return [Camera count] + adjustment;
	}
	else if (section == LENSES_SECTION)
	{
		return [Lens count] + adjustment;
	}
	else
	{
		return UNITS_COUNT;
	}
}

// Customize the appearance of table view cells. Cells for the units and
// camera sections are formatted differently and handled by helper methods.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	UITableViewCell* cell;
	if ([indexPath section] == UNITS_SECTION)
	{
		cell = [self cellForUnitsRowAtIndexPath:indexPath inTableView:tableView];
	}
	else if ([indexPath section] == CAMERAS_SECTION)
	{
		cell = [self cellForCameraRowAtIndexPath:indexPath inTableView:tableView];
	}
	else
	{
		// Lenses section
		cell = [self cellForLensRowAtIndexPath:indexPath inTableView:tableView];
	}
	
    return cell;
}
- (void)tableView:(UITableView *)tableView 
	commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
	forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		if ([indexPath section] == CAMERAS_SECTION)
		{
			[self deleteCameraAtIndexPath:indexPath inTableView:tableView];
		}
		else
		{
			[self deleteLensAtIndexPath:indexPath inTableView:tableView];
		}
	}
	else if (editingStyle == UITableViewCellEditingStyleInsert)
	{
		// This only happens when the insert editing control ('+' button on the left side)
		// is tapped, which means add a new camera or lens
		if ([indexPath section] == CAMERAS_SECTION)
		{
			CoC* coc = [CoC findFromPresets:NSLocalizedString(@"DEFAULT_COC", "35 mm")];
			Camera* camera = [[Camera alloc] initWithDescription:@"" coc:coc identifier:[Camera count]];
			
			[[NSNotificationCenter defaultCenter] postNotification:
			 [NSNotification notificationWithName:CAMERA_SELECTED_FOR_EDIT_NOTIFICATION 
										   object:camera]];
			
			[camera release];
		}
		else if ([indexPath section] == LENSES_SECTION)
		{
			Lens* lens = [[Lens alloc] initWithDescription:@""
										   minimumAperture:[NSNumber numberWithFloat:32.0]
										   maximumAperture:[NSNumber numberWithFloat:1.4]
										minimumFocalLength:[NSNumber numberWithInt:50]
										maximumFocalLength:[NSNumber numberWithInt:50] 
												identifier:[Lens count]];
			
			[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:LENS_SELECTED_FOR_EDIT_NOTIFICATION
																								 object:lens]];
			
			[lens release];
		}
	}
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath section] == UNITS_SECTION)
	{
		return NO;
	}
	else if ([indexPath section] == CAMERAS_SECTION)
	{
		return [indexPath row] < [Camera count] ? YES : NO;
	}
	else
	{
		return [indexPath row] < [Lens count] ? YES : NO;
	}
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
	if ([fromIndexPath section] == CAMERAS_SECTION)
	{
		// Camera moved
		[Camera moveFromIndex:[fromIndexPath row]
					  toIndex:[toIndexPath row]];
	}
	else
	{
		// Lens moved
		[Lens moveFromIndex:[fromIndexPath row]
					toIndex:[toIndexPath row]];
	}
}

#pragma mark Helper methods

// Format table cell for rows in the cameras section of the table view.
- (UITableViewCell *) cellForCameraRowAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *) tableView
{
	int cameraCount = [Camera count];
	bool nonCameraRow = [indexPath row] >= cameraCount;
	
	UITableViewCell *cell = [self standardCellForTableView:tableView];
	
	if (nonCameraRow)
	{
		[[cell textLabel] setText:NSLocalizedString(@"ADD_CAMERA", "Add camera")];
	}
	else
	{
		Camera* camera = [Camera findFromDefaultsForIndex:[indexPath row]];
		[[cell textLabel] setText:[camera description]];
	}
	
	// If this is the selected camera, add a check mark
	NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey:FTCameraIndex];
	[cell setAccessoryType:[indexPath row] == index ? UITableViewCellAccessoryCheckmark :UITableViewCellAccessoryNone];
	
	[cell setEditingAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
	return cell;
}
							
- (UITableViewCell*) cellForLensRowAtIndexPath:(NSIndexPath*)indexPath inTableView:(UITableView*) tableView
{
	int lensCount = [Lens count];
	bool nonLensRow = [indexPath row] >= lensCount;
	
	UITableViewCell *cell = [self standardCellForTableView:tableView];
	
	if (nonLensRow)
	{
		[[cell textLabel] setText:NSLocalizedString(@"ADD_LENS", "ADD LENS")];
	}
	else
	{
		Lens* lens = [Lens findFromDefaultsForIndex:[indexPath row]];
		[[cell textLabel] setText:[lens description]];
	}
	
	// If this is the selected lens, add a check mark
	NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey:FTLensIndex];
	[cell setAccessoryType:[indexPath row] == index ? UITableViewCellAccessoryCheckmark :UITableViewCellAccessoryNone];
	
	[cell setEditingAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
	return cell;
}

// Format table cell for rows in the units section of the table view
- (UITableViewCell *) cellForUnitsRowAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView*)tableView
{
	UITableViewCell *cell = [self standardCellForTableView:tableView];
	
	switch ([indexPath row])
	{
		case DistanceUnitsFeet:
			[[cell textLabel] setText:NSLocalizedString(@"FEET", "FEET")];
			break;
			
		case DistanceUnitsFeetAndInches:
			[[cell textLabel] setText:NSLocalizedString(@"FEET_AND_INCHES", "FEET_AND_INCHES")];
			break;
			
		case DistanceUnitsMeters:
			[[cell textLabel] setText:NSLocalizedString(@"METRES", "METRES")];
			break;
	}

	DistanceUnits units = [[NSUserDefaults standardUserDefaults] integerForKey:FTDistanceUnitsKey];
	if ([indexPath row] == units)
	{
		[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
	}
	else
	{
		[cell setAccessoryType:UITableViewCellAccessoryNone];
	}

	return cell;
}

- (UITableViewCell *) standardCellForTableView: (UITableView *) tableView  
{
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) 
	{
		cell = [[[UITableViewCell alloc]
				 initWithFrame:CGRectZero
				 reuseIdentifier:CellIdentifier] autorelease];
	}
	return cell;
}

- (void)deleteCameraAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView*)tableView
{
	int currentSelection = [[NSUserDefaults standardUserDefaults] integerForKey:FTCameraIndex];
	Camera* camera = [Camera findFromDefaultsForIndex:[indexPath row]];
	[Camera delete:camera];
	
	[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
					 withRowAnimation:UITableViewRowAnimationFade];
	
	if ([indexPath row] == currentSelection)
	{
		// Camera being deleted is the currently selected one. Choose the one above.
		int newSelection = [indexPath row] - 1;
		if (newSelection < 0)
		{
			// Deleting the first one so the one below becomes the new selection
			newSelection = 0;
		}
		
		[[NSUserDefaults standardUserDefaults] setInteger:newSelection
												   forKey:FTCameraIndex];
		
		NSIndexPath* newSelectedPath = [NSIndexPath indexPathForRow:newSelection
														  inSection:[indexPath section]];
		[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:newSelectedPath]
						 withRowAnimation:UITableViewRowAnimationNone];
		
		[[NSNotificationCenter defaultCenter] 
		 postNotification:[NSNotification notificationWithName:COC_CHANGED_NOTIFICATION object:nil]];
	}
	else if ([indexPath row] < currentSelection)
	{
		// Deleting camera above so adjust current selection
		[[NSUserDefaults standardUserDefaults] setInteger:currentSelection - 1
												   forKey:FTCameraIndex];
	}
}

- (void)deleteLensAtIndexPath: (NSIndexPath *) indexPath inTableView:(UITableView*)tableView
{
	int currentSelection = [[NSUserDefaults standardUserDefaults] integerForKey:FTLensIndex];
	Lens* lens = [Lens findFromDefaultsForIndex:[indexPath row]];
	[Lens delete:lens];

	[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
					 withRowAnimation:UITableViewRowAnimationFade];

	if ([indexPath row] == currentSelection)
	{
		// Lens being deleted is the currently selected one. Choose the one above.
		int newSelection = [indexPath row] - 1;
		if (newSelection < 0)
		{
			// Deleting the first one so the one below becomes the new selection
			newSelection = 0;
		}
		
		// Must adjust which row is the new default as the table has not been updated yet
		[[NSUserDefaults standardUserDefaults] setInteger:newSelection 
												   forKey:FTLensIndex];
		
		NSIndexPath* newSelectedPath = [NSIndexPath indexPathForRow:newSelection
														  inSection:[indexPath section]];
		[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:newSelectedPath]
						 withRowAnimation:UITableViewRowAnimationNone];

		[[NSUserDefaults standardUserDefaults] setInteger:newSelection
												   forKey:FTLensIndex];
	}
	else if ([indexPath row] < currentSelection)
	{
		// Deleting lens above so adjust current selection
		[[NSUserDefaults standardUserDefaults] setInteger:currentSelection - 1
												   forKey:FTLensIndex];
	}
}

@end
