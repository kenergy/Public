//
//  SummaryWindowController.m
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 8/17/11.
//  Copyright 2011 Genentech. All rights reserved.
//

#import "SummaryWindowController.h"
#import "GlobalStatus.h"
#import "StatusIconCell.h"
#import "PleaseWaitController.h"
#import "Constants.h"
#import "RunAppleScript.h"


@implementation SummaryWindowController

//@synthesize aBuffer;

- (id)init
{	
	[super init];
	[self readInSettings];
	if (debugEnabled) NSLog(@"init OK in SummaryWindowController");
	// Setup notifications for window closure
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowClosed)
												 name:NSWindowWillCloseNotification
											   object:window];
	// StatusUpdateNotification
	// Register for notifications on Global Status Array updates
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadTableBufferNow:) 
                                                 name:StatusUpdateNotification
                                               object:nil];
	// ReconCompleteNotification reconIsCompleted
	// Stop the progress bar when the recon is complete
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reconIsCompleted:) 
                                                 name:ReconCompleteNotification
                                               object:nil];
	//RequestAttemptToRepairNotification
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(attemptToRepairStarted:) 
                                                 name:RequestAttemptToRepairNotification
                                               object:nil];
	//RequestAttemptToRepairNotification
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(attemptToRepairCompleted:) 
                                                 name:AttemptToRepairCompleteNotification
                                               object:nil];
	
	

	
	// Ask for an update to the global status array on init
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:RequestStatusUpdateNotification
	 object:self];
	return self;
}

- (void)awakeFromNib {
	if (debugEnabled) NSLog(@"Summary Window did load");
	// Hide the Dock
	[self makeWindowFullScreen];
	// Close the progress bar initally
	windowNeedsResize = YES;
	[self closeProgressBar:self];
	StatusIconCell *statusIconCell = [[StatusIconCell alloc] init];
	
	[discriptionCol setDataCell:statusIconCell];
	// Having an issue with making this a key window
	[window makeKeyAndOrderFront:self];
	[NSApp arrangeInFront:self];
	[NSApp activateIgnoringOtherApps:YES];
	// Set the menu to blank
	[toggleSummaryPredicateButton setTitle:@""];
	// Enable our button on launch
	[ attemptToRepairButton setEnabled:NO];

	[tableView reloadData];
	[ [self window] makeKeyAndOrderFront:self];

}

#pragma mark Notification Observered Methods

- (void)windowClosing:(NSNotification*)aNotification {
	if (debugEnabled) NSLog(@"Received window close notification");
	if (aBuffer) {
		if (debugEnabled) NSLog(@"Clearing the current table buffer");
		[aBuffer removeAllObjects];
	}
}


-(void)attemptToRepairStarted:(NSNotification *) notification
{
	if (debugEnabled) NSLog(@"Summary Window Recieved Close Window Notification");
	[[self window] performSelectorOnMainThread:@selector(performClose:)
									withObject:self
								 waitUntilDone:false];
}

-(void)attemptToRepairCompleted:(NSNotification *) notification
{
	if (debugEnabled) NSLog(@"Received notification that repair is complete");
	[ attemptToRepairButton setEnabled:YES];
}

-(void)reconIsCompleted:(NSNotification *) notification
{
	if (debugEnabled) NSLog(@"Was notified that recon is completed");
	// Start the User Progress Indicator
	[self performSelectorOnMainThread:@selector(stopUserProgressIndicator:)
						   withObject:self
						waitUntilDone:false];
	if (lastGlobalStatusUpdate) {
		[self reloadTableBuffer:lastGlobalStatusUpdate];

	}	
}

- (void) reloadTableBufferNow:(NSNotification *) notification
{	
	lastGlobalStatusUpdate = [notification userInfo];
	[self reloadTableBuffer:lastGlobalStatusUpdate];
}

-(void)reloadTableBuffer:(NSDictionary *)globalStatusUpdate
{
	if(debugEnabled)NSLog(@"DEBUG: Was Told to Reload Table Buffer...");
	if (aBuffer) {
		[aBuffer release];
	}
	if(debugEnabled)NSLog(@"DEBUG: Notification Array: %@",[globalStatusUpdate objectForKey:@"globalStatusArray"]);
	
	globalStatusArray = [[NSMutableArray alloc] initWithArray:[globalStatusUpdate objectForKey:@"globalStatusArray"]];
	
	//NSPredicate *warningPredicate = [NSPredicate predicateWithFormat:@"(status ==[c] Warning) AND (status ==[c] Critical)"];
	// If no predicate then filter the Passed Results
	NSPredicate *summaryPredicate;
	if (!statusPredicate) {
		summaryPredicate = [NSPredicate predicateWithFormat:@"status != %@",@"Passed"];
		[toggleSummaryPredicateButton setTitle:@""];
		
	}
	else {
		summaryPredicate = [NSPredicate predicateWithFormat:@"status = %@",statusPredicate];
	}
	NSArray *matchingObjects;
	if ([[globalStatusArray filteredArrayUsingPredicate:summaryPredicate] count] >0) {
		matchingObjects = [[NSArray alloc] initWithArray:[globalStatusArray filteredArrayUsingPredicate:summaryPredicate]];
	}
	else {
		matchingObjects = [[NSArray alloc] init];
	}
	
	
	if (debugEnabled)NSLog(@"Predicate Matching Objects:%@",matchingObjects);
	
	
	//[globalStatusArray removeObjectsInArray:matchingObjects];
	if ([matchingObjects count] > 0) {
		aBuffer = [[NSMutableArray alloc] initWithArray:matchingObjects];
	}
	else {
		if (debugEnabled)NSLog(@"ERROR: No matching objects found with predicate");
		aBuffer = [[NSMutableArray alloc] init];
	}
	
	
	
	
	//[NSPredicate predicateWithFormat:@"title ==[c] %@", @"Passed"];
	//NSPredicate *warningPredicate = [NSPredicate predicateWithFormat:@"(status ==[c] Warning) AND (status ==[c] Critical)"];
	//NSDictionary *targetDictionary = [[array filteredArrayUsingPredicate:finder] lastObject];
	
	// Reload the table
	if (statusPredicate) {
		[toggleSummaryPredicateButton setTitle:statusPredicate];
		[statusPredicate release];
	}
	[tableView performSelectorOnMainThread:@selector(reloadData)
								withObject:nil
							 waitUntilDone:false];
	[self performSelectorOnMainThread:@selector(stopSummaryProgressIndicator)
						   withObject:nil
						waitUntilDone:false];	
}

-(IBAction)toggleSummaryPredicate:(id)sender
{
	// Start Progress Indicator 
	[self performSelectorOnMainThread:@selector(startSummaryProgressIndicator)
						   withObject:nil
						waitUntilDone:false];
	
	statusPredicate = [ toggleSummaryPredicateButton title];
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:RequestStatusUpdateNotification
	 object:self];
}


- (NSMutableArray*)aBuffer
{
	return aBuffer;
}


-(void)dealloc 
{ 
	// Remove observer for window close
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	// Release Array buffer
	[aBuffer release];
	//[self.globalStatusArray release];
	[super dealloc]; 
}

// Table View Protocol
- (int)numberOfRowsInTableView:(NSTableView *)tableView{
	if ([aBuffer count] != 0) {
		return ([aBuffer count]);

	}
	else {
		return ([aBuffer count] -1);
	}
}

#pragma mark Method Overrides
- (id)tableView:(NSTableView *)tableView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
			row:(NSInteger)row{
	if (![aBuffer count]) {
		statusPredicate = @"Passed";
		//Disable the Attempt to Repair Button
		return nil;
	}
	else {
		statusPredicate = nil;
	}

	/*if (row == [aBuffer count]) {
		return nil;
	}*/
	if (row > [aBuffer count] -1) {
		if (debugEnabled)NSLog(@"ERROR: We Have run out of rows?");
		return nil;
	}
	if(debugEnabled)NSLog(@"DEBUG:Processing row: %ld of %ld",row,[aBuffer count] -1);
	NSImage *lrg_green = [[NSImage alloc] initWithContentsOfFile: [ mainBundle
															   pathForResource:@"lrg_green" ofType:@"png"]];
	NSImage *lrg_yellow = [[NSImage alloc] initWithContentsOfFile: [ mainBundle
															   pathForResource:@"lrg_yellow" ofType:@"png"]];
	NSImage *lrg_red = [[NSImage alloc] initWithContentsOfFile: [ mainBundle
															   pathForResource:@"lrg_red" ofType:@"png"]];
		if (statusCol == tableColumn) {
			NSString *status = [[aBuffer objectAtIndex:row] objectForKey:@"status"];
			if ([status isEqualToString:@"Passed"]) {
				if (row != -1) return lrg_green;
			}
			if ([status isEqualToString:@"Warning"]) {
				if (row != -1) return lrg_yellow;
			}
			if ([status isEqualToString:@"Critical"]) {
				if (row != -1) return lrg_red;
			}
		}
		if (discriptionCol == tableColumn) {
			NSString * discription =  [[aBuffer objectAtIndex:row] objectForKey:@"discription"];
			NSString * reason =  [[aBuffer objectAtIndex:row] objectForKey:@"reason"];

			NSMutableDictionary *displayDictionary = [[NSMutableDictionary alloc] init];
			if ([discription isEqualToString:@"DiskUsage"]) {
				NSMutableDictionary *valDict = [ settings objectForKey:@"DiskUsage"];
				[valDict setValue:reason forKey:@"summaryReason"];
				//if(debugEnabled)NSLog(@"DEBUG: Merged Dicts:%@",valDict);
				return valDict; 
			}
			if ([discription isEqualToString:@"Updates"]) {
				NSMutableDictionary *valDict = [ settings objectForKey:@"Updates"];
				[valDict setValue:reason forKey:@"summaryReason"];
				return valDict;			}
			if ([discription isEqualToString:@"UpdatesDate"]) {
				NSMutableDictionary *valDict = [ settings objectForKey:@"UpdatesDate"];
				[valDict setValue:reason forKey:@"summaryReason"];
				return valDict;			}
			if ([discription isEqualToString:@"CrashPlanDate"]) {
				NSMutableDictionary *valDict = [ settings objectForKey:@"CrashPlanDate"];
				[valDict setValue:reason forKey:@"summaryReason"];
				return valDict; 			}
			if ([discription isEqualToString:@"CrashPlanPercentage"]) {
				NSMutableDictionary *valDict = [ settings objectForKey:@"CrashPlanPercentage"];
				[valDict setValue:reason forKey:@"summaryReason"];
				return valDict; 			
			}
			if ([discription isEqualToString:@"Smart"]) {
				NSMutableDictionary *valDict = [ settings objectForKey:@"Smart"];
				[valDict setValue:reason forKey:@"summaryReason"];
				return valDict; 
			}
			if ([discription isEqualToString:@"Casper"]) {
				NSMutableDictionary *valDict = [ settings objectForKey:@"Casper"];
				[valDict setValue:reason forKey:@"summaryReason"];
				return valDict;
			}
			if ([discription isEqualToString:@"Battery"]) {
				NSMutableDictionary *valDict = [ settings objectForKey:@"Battery"];
				[valDict setValue:reason forKey:@"summaryReason"];
				return valDict;
			}
			if ([discription isEqualToString:@"HDsize"]) {
				NSMutableDictionary *valDict = [ settings objectForKey:@"HDsize"];
				[valDict setValue:reason forKey:@"summaryReason"];
				return valDict;
			}
			else {
				NSString *nameValue = @"Generic Test";
				[displayDictionary setValue:nameValue forKey:@"summaryTitle"];
				NSString *image = @"generic_sm";
				[displayDictionary setValue:image forKey:@"summaryImage"];
				return displayDictionary;
			}

		}
		if (statusTxtCol == tableColumn) {
			if ([aBuffer objectAtIndex:row] !=nil) {
				NSString * discription = @"";
				NSString * status = @"";
				NSString * metric = @"";
				NSString * nsStr = @"";
				// Passed Text
				NSString *passedText = @"";
				NSString *warningText = @"";
				NSString *criticalText = @"";
				
				if ([[aBuffer objectAtIndex:row] objectForKey:@"discription"] !=nil) {
					discription =  [[aBuffer objectAtIndex:row] objectForKey:@"discription"];
					if(debugEnabled)NSLog(@"Processed Description: %@",discription);
					
				}
				if ([[aBuffer objectAtIndex:row] objectForKey:@"status"] !=nil) {
					status =  [[aBuffer objectAtIndex:row] objectForKey:@"status"];
					if(debugEnabled)NSLog(@"Processed Status: %@",status);
					
				}
				if ([[aBuffer objectAtIndex:row] objectForKey:@"metric"] !=nil) {
					metric =  [[aBuffer objectAtIndex:row] objectForKey:@"metric"];
					if(debugEnabled)NSLog(@"Metric Status: %@",metric);
					
				}
				
				
				if ([status isEqualToString:@"Passed"]) {
					passedText = [[ settings objectForKey:discription] objectForKey:@"passedText"];
					if(metric && passedText){
						nsStr =[NSString stringWithFormat: passedText, metric];
					}
					else {
						nsStr = passedText;
					}
					[ toggleSummaryPredicateButton addItemWithTitle:@"Passed"];
					if (statusPredicate) {
						[toggleSummaryPredicateButton setTitle:statusPredicate];
					}
				}
				if (debugEnabled)NSLog(@"Found Passed Text: %@",passedText);
				if ([status isEqualToString:@"Warning"]) {
					warningText = [[ settings objectForKey:discription] objectForKey:@"warningText"];
					if(metric && warningText){
						nsStr =[NSString stringWithFormat: warningText, metric];
					}
					else{
						nsStr = warningText;
					}
					[ attemptToRepairButton setEnabled:YES];
					[ toggleSummaryPredicateButton setEnabled:YES];
					[ toggleSummaryPredicateButton addItemWithTitle:@"Warning"];
					if (statusPredicate) {
						[toggleSummaryPredicateButton setTitle:statusPredicate];
					}
				}
				if ([status isEqualToString:@"Critical"]) {
					criticalText = [[ settings objectForKey:discription] objectForKey:@"criticalText"];
					if(metric && criticalText){
						nsStr =[NSString stringWithFormat: criticalText, metric];
					}
					else {
						nsStr = criticalText;
					}
					[ attemptToRepairButton setEnabled:YES];
					[ toggleSummaryPredicateButton setEnabled:YES];
					[ toggleSummaryPredicateButton addItemWithTitle:@"Critical"];
					if (statusPredicate) {
						[toggleSummaryPredicateButton setTitle:statusPredicate];
					}
					
				}
				
				NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
				
				[paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
				
				
				NSMutableAttributedString * attributedStr = [[[NSMutableAttributedString alloc] initWithString:nsStr] autorelease];
				[attributedStr
				 addAttribute:NSParagraphStyleAttributeName
				 value:paragraphStyle
				 range:NSMakeRange(0,[attributedStr length])];
				
				if(debugEnabled)NSLog(@"Generated Attribute String:%@",attributedStr);
				if (row != -1) return attributedStr;
			}
			
			}
	else {
		return nil;

	}
	return nil;
}

- (void)readInSettings 
{ 	
	mainBundle = [NSBundle bundleForClass:[self class]];
	NSString *settingsPath = [mainBundle pathForResource:SettingsFileResourceID
												  ofType:@"plist"];
	settings = [[NSDictionary alloc] initWithContentsOfFile:settingsPath];
}


-(void)displayAlertDialog
{
	// Activate Our Application
	[NSApp arrangeInFront:self];
	[NSApp activateIgnoringOtherApps:YES];
	// Display a standard alert
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:@"No Issues"];
	[alert setInformativeText:@"There are currently no issues"];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert runModal];
	[alert release];
}

-(void)windowClosed
{
	if (debugEnabled)NSLog(@"Recieved window close notification");
}

# pragma mark Button Methods
//- (IBAction)refreshButtonClicked:(id)sender
//{
    
//	windowNeedsResize = YES;
	// Start the User Progress Indicator
//	[self performSelectorOnMainThread:@selector(startUserProgressIndicator:)
//						   withObject:sender
//						waitUntilDone:false];
//	NSLog(@"The user has clicked the update button");
	// Ask for Recon Update
	
        
//        NSString *reconToolPath  = [settings objectForKey:@"reconToolPath"];
//        NSString *reconToolBundleID = [settings objectForKey:@"reconToolBundleID"];
//        NSLog(@"Using MacDNA Refresh path %@",reconToolPath);
//        NSFileManager *myFileManager = [NSFileManager defaultManager];
//        BOOL supportToolExists = [ myFileManager fileExistsAtPath:reconToolPath];
        
//        if (supportToolExists){
//            NSLog(@"Found MacDNA Refresh path %@",reconToolPath);
//            NSBundle *bundle = [NSBundle bundleWithPath:reconToolPath];
//            NSString *path = [bundle executablePath];
//            NSTask *task = [[NSTask alloc] init];
//            [task setLaunchPath:path];
//            [task launch];
//            [task release];
//            task = nil;
//        }
//        else {
//            NSLog(@"MacDNA Refresh missing using bundle id %@",reconToolBundleID);
//            NSWorkspace *ws = [NSWorkspace sharedWorkspace];
//            NSString *appPath = [ws absolutePathForAppBundleWithIdentifier:reconToolBundleID];
//            [ws launchApplication:appPath];
//            NSLog(@"Launched MacDNA Refresh Tool");
//        }

	
//	if(debugEnabled)NSLog(@"Buffer is currently:%@",aBuffer);
	// Request Global Status Update via notification center
//	[[NSNotificationCenter defaultCenter]
//	 postNotificationName:RequestStatusUpdateNotification
//	 object:self];
//	// Reload the table
//	statusPredicate = nil;
//	[tableView reloadData];
//}


- (IBAction)attemptToFixButton:(id)sender
{
	// Disable the Button until we are complete
	[ attemptToRepairButton setEnabled:NO];
	// post notification
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:RequestAttemptToRepairNotification
	 object:self];
	//Close the summary Window
	[[self window] performSelectorOnMainThread:@selector(performClose:)
									withObject:self
								 waitUntilDone:false];
}


# pragma mark -
# pragma mark Progress Bar Interactions
# pragma mark -

-(void)startUserProgressIndicator:(id)sender
{
	// Disable the refresh button in the UI
	[ refreshButton setEnabled:NO];
	// Show our Little UI Label
	[ uiLabel setHidden:NO];
	// Setup or progress bar defaults
	[userProgressBar setBezeled:YES];
	[userProgressBar setDisplayedWhenStopped:NO];
	[userProgressBar setIndeterminate:YES];
	[userProgressBar setUsesThreadedAnimation:NO];
	// Start The Adminisation
	[ userProgressBar startAnimation:self];
	[ self expandProgressBar:sender];

	/*[userProgressBar performSelectorOnMainThread:@selector(startAnimation:)
							 withObject:self
						  waitUntilDone:false];*/
}

-(void)stopUserProgressIndicator:(id)sender
{
	// Re-enable the refresh button
	[ refreshButton setEnabled:YES];
	// Hide the UI Label
	[ uiLabel setHidden:YES];
	// Stop the Animation
	[ userProgressBar stopAnimation:self];
	// Hide the progress bar
	[ self closeProgressBar:sender];

}

-(void)stopSummaryProgressIndicator
{
	[ summaryProgressBar stopAnimation:self];
}
-(void)startSummaryProgressIndicator
{
	[ summaryProgressBar startAnimation:self];
}

-(void)expandProgressBar:(id)sender
{
		NSRect frame = [[sender window] frame];
		// The extra +10 accounts for the space between the box and its neighboring views
		CGFloat sizeChange = [ progressBox frame].size.height + 5;
		// Make the window bigger.
		frame.size.height += sizeChange;
		// Move the origin.
		frame.origin.y -= sizeChange;
		[[sender window] setFrame:frame display:YES animate:YES];
		// Show the extra box.
		[progressBox setHidden:NO];

}


- (void)closeProgressBar:(id)sender
{
	if (windowNeedsResize) {
		NSRect frame = [[sender window] frame];
		CGFloat sizeChange = [progressBox frame].size.height + 5;
		
		// Make the window smaller.
		frame.size.height -= sizeChange;
		// Move the origin.
		frame.origin.y += sizeChange;
		[[sender window] setFrame:frame display:YES animate:YES];
		// Hide the extra box.
		[progressBox setHidden:YES];
	}
	windowNeedsResize = NO;
}


# pragma mark Window code

-(void)makeWindowFullScreen
{
	[NSMenu setMenuBarVisible:NO];
	//[window setOpaque:NO];
	//[window setLevel:NSScreenSaverWindowLevel];
}


@end
