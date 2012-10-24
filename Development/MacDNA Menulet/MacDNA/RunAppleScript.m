//
//  RunAppleScript.m
//  GNE Mac Status
//
//  Created by Zack Smith on 7/20/11.
//  Copyright 2011 318. All rights reserved.
//

#import "RunAppleScript.h"
#import "Constants.h"


@implementation RunAppleScript

#pragma mark Method Overide

- (id)init
{	
	[super init];
	// Register for notifications on Global Status Array updates
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(runAppleScript) 
                                                 name:RequestAttemptToRepairNotification
                                               object:nil];
	//AttemptToRepairStartedNotification
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:AttemptToRepairStartedNotification
	 object:self];
	[self runAppleScript];
	return self;
}


# pragma mark Apple Script Task
-(void)runAppleScript{
	//NSLog(@"Received Request to run AppleScript");
	//Detach thread as we want things running in parralle
	[ NSThread detachNewThreadSelector:@selector(runAppleScriptTask)
							  toTarget:self
							withObject:nil];
}

-(void)runAppleScriptTask
{
	mainBundle = [NSBundle bundleForClass:[self class]];
	NSDictionary* errorDict;
    NSAppleEventDescriptor* returnDescriptor = NULL;
	NSString *scriptPath = [[NSBundle mainBundle] pathForResource: @"AttemptToRepair"
														   ofType: @"scpt"];

	//NSLog(@"Found AppleScript Path:%@",scriptPath);
	
	// Run the Apple Script
	NSAppleScript *scriptObject = [[NSAppleScript alloc]initWithContentsOfURL:[NSURL fileURLWithPath: scriptPath]
																		error:&errorDict];
	returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
	//NSLog(@"Return Discriptor,%@",returnDescriptor);
	
	NSString *returnValue = @"User Canceled";
	NSMutableDictionary *returnDict  = [[NSMutableDictionary alloc] init];

	returnValue = [ returnDescriptor stringValue];
	[ returnDict setValue:returnValue forKey:@"returnValue"];
	
	// Put the Log in the Console Log
	if (errorDict) {
		// Notify 
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:AttemptToRepairCompleteNotification
		 object:self];
		[self performSelectorOnMainThread:@selector(displayDialog:)
									 withObject:returnValue
								  waitUntilDone:false];
	}
	else {
		// Notify
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:AttemptToRepairCompleteNotification
		 object:self];
		[self performSelectorOnMainThread:@selector(displayDialog:)
									 withObject:returnValue
								  waitUntilDone:false];
		
	}

	
}

-(void)displayDialog:(NSString *)message
{
	// Activate Our Application
	[NSApp arrangeInFront:self];
	[NSApp activateIgnoringOtherApps:YES];
	// Display a standard alert
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:@"Repairs Complete"];
	[alert setInformativeText:message];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert runModal];
	[alert release];
}

@end
