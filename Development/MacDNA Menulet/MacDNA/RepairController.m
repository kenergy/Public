//
//  RepairController.m
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol 9/27/11.
//  Copyright 2011 Genentech. All rights reserved.
//

#import "RepairController.h"
#import "PleaseWaitController.h"
#import "RunAppleScript.h"

@implementation RepairController

- (id) init {
	//AttemptToRepairStartedNotification
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startNewRepair:) 
                                                 name:RequestAttemptToRepairNotification
                                               object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startPleaseWait:) 
                                                 name:StartPleaseWaitNotification
                                               object:nil];
	return self;
} // end init

-(void)startNewRepair:(NSNotification *)notification
{
	// Check if we already 
	if ( pleaseWaitWindow ) {
		[pleaseWaitWindow release];
	} // end if
	pleaseWaitWindow= [[PleaseWaitController alloc] init];
	[pleaseWaitWindow showWindow:self];
	
	if (attemptToRepair) {
		// Show alert
	}
	else {
		attemptToRepair = [[RunAppleScript alloc] init];
	}
}

-(void)startPleaseWait:(NSNotification *)notification
{
	// Check if we already 
	if ( pleaseWaitWindow ) {
		[pleaseWaitWindow release];
	} // end if
	pleaseWaitWindow= [[PleaseWaitController alloc] init];
	[pleaseWaitWindow showWindow:self];
}

@end
