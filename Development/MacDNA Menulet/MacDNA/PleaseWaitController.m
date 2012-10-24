//
//  PleaseWaitController.m
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 7/19/11.
//  Copyright 2011 Genentech. All rights reserved.
//

#import "PleaseWaitController.h"
#import "Constants.h"


@implementation PleaseWaitController

# pragma mark Method Overrides


- (id) init {
	// NSLog(@"init OK in PleaseWaitController");
	//AttemptToRepairStartedNotification
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(repairStarted:) 
                                                 name:AttemptToRepairStartedNotification
                                               object:nil];
	//ShowPleaseWaitNotification
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(repairStarted:) 
                                                 name:ShowPleaseWaitNotification
                                               object:nil];
	//AttemptToRepairCompleteNotification
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(repairComplete:) 
                                                 name:AttemptToRepairCompleteNotification
                                               object:nil];
	[self initWithWindowNibName:@"PleaseWait" owner:self];

	return self;
} // end init

- (void)dealloc {
	// Remove ourself from Notification Center
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)awakeFromNib {
	[NSApp arrangeInFront:self];
	[NSApp activateIgnoringOtherApps:YES];
	[ [self window] makeKeyAndOrderFront:self];
}

# pragma mark Class Method


-(void)repairStarted:(NSNotification *)notification
{
	//NSLog(@"Notified of repair starting...");
	[NSApp arrangeInFront:self];
	[NSApp activateIgnoringOtherApps:YES];
	[ [self window] makeKeyAndOrderFront:self];

}

- (void) repairComplete:(NSNotification *) notification
{
	//NSLog(@"Recieived Repair Complete Notification");
	//NSLog(@"Attempting to closing Please Wait Window");
	[[self window] performSelectorOnMainThread:@selector(orderOut:)
									withObject:self
								 waitUntilDone:false];
	[[self window] performSelectorOnMainThread:@selector(performClose:)
									withObject:self
								 waitUntilDone:false];
}

@end
