//
//  Recon.m
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 8/23/11.
//  Copyright 2011 Genentech. All rights reserved.
//

#import "Recon.h"
#import "Constants.h"


@implementation Recon


- (id)init
{	
	[super init];
	[self readInSettings];
	if (debugEnabled) NSLog(@"init OK in SummaryWindowController");
	// StatusUpdateNotification
	// Register for notifications on Global Status Array updates
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reconRequested:) 
                                                 name:RequestReconNotification
                                               object:nil];
	// StatusUpdateNotification
	return self;

}
- (void)readInSettings 
{ 	
	mainBundle = [NSBundle bundleForClass:[self class]];
	NSString *settingsPath = [mainBundle pathForResource:SettingsFileResourceID ofType:@"plist"];
	settings = [[NSDictionary alloc] initWithContentsOfFile:settingsPath];
}

-(void)reconRequested:(NSNotification*)aNotification
{
	if (reconIsRunning) {
		if (debugEnabled) NSLog(@"Recon is already running, ignoring request");
	}
	else {
		if (debugEnabled) NSLog(@"Starting Recon Thread");
		[NSThread detachNewThreadSelector:@selector(runCasperRecon)
								 toTarget:self
							   withObject:nil];
	}

}

-(void)runCasperRecon
{
	reconIsRunning = YES;
	if (_task) {
		if (debugEnabled) NSLog(@"Found existing task...releasing");
		[_task release];
	}
	_task = [[NSTask alloc] init];
	
	NSData *data;
	// Start
	NSPipe *pipe = [NSPipe pipe];
	
	//_fileHandle = [pipe fileHandleForReading];
	//[_fileHandle readInBackgroundAndNotify];
	// Grab both our system profile outputs
	//[_task setLaunchPath:@"/usr/sbin/jamf"];
	//[_task setArguments:[NSArray arrayWithObjects:@"recon",
	//					 nil]];
    [_task setLaunchPath:@"/Users/arek/Desktop/MacDNA.app"];
	[_task setStandardOutput: pipe];
	//Set to help with Xcode debug log issues
	[_task setStandardInput:[NSPipe pipe]];
	[_task setStandardError: pipe];
	[_task launch];
	NSData *readData;
	while ((readData = [_fileHandle availableData]) && [readData length]) {
		if (debugEnabled) NSLog(@"DEBUG: Waiting for command to finish...");
	}
	NSFileHandle *file;
	file = [pipe fileHandleForReading];
	data = [file readDataToEndOfFile];
	// We now have our full results in a NSString
	NSString *text = [[NSString alloc] initWithData:data 
										   encoding:NSASCIIStringEncoding];
	
	if (debugEnabled) NSLog(@"DEBUG: Completed runCasperRecon: %@",text);
	
	// Let Any Observers know we are finished with Recon
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ReconCompleteNotification
	 object:self];
	reconIsRunning = NO;
}

@end
