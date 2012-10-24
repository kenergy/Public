//
//  Plugins.m
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 2/13/12.
//  Copyright 2012 Genentech. All rights reserved.
//

#import "Plugins.h"
#import "GNE_Mac_Status_AppDelegate.h"
#import "Constants.h"


@implementation Plugins


-(id)init
{
    [ super init];
	[ self readInSettings];
    return self;
}

- (void)readInSettings 
{ 	
	mainBundle = [NSBundle bundleForClass:[self class]];
	NSString *settingsPath = [mainBundle pathForResource:SettingsFileResourceID
												  ofType:@"plist"];
	settings = [[NSDictionary alloc] initWithContentsOfFile:settingsPath];
	debugEnabled = [[settings objectForKey:@"debugEnabled"] boolValue];
}


-(IBAction)updatePluginMenus:(id)sender
{
	if(debugEnabled) NSLog(@"User clicked the plugins button...");
	//[self runPluginScripts];
}

-(void)runPluginScripts:(id)sender
{
	if(debugEnabled) NSLog(@"Running Plugin Scripts...");
	[self addConfigScriptArguments];
	NSDictionary * scriptPlugins = [ settings objectForKey:@"scriptPlugins"];
	NSDictionary * nonPrivilegedScripts = [ scriptPlugins objectForKey:@"nonPrivilegedScripts"];
	
	// Enumerate our Script headers (Menu Headers)
	for(NSString *headerGUID in nonPrivilegedScripts){
		NSDictionary *scriptHeader = [nonPrivilegedScripts objectForKey:headerGUID];
		
		// Grab the Header Menu Item Title
		NSString *headerTitle = [scriptHeader objectForKey:@"headerTitle"];
		if(debugEnabled)NSLog(@"Found Script Title: %@",headerTitle);
		
		// Add the header item to the Menu
		NSInteger menuHeaderTag = [ sender addPluginMenuHeader:headerTitle];
		
		NSArray * itemScripts = [scriptHeader objectForKey:@"itemScripts"];
		
		// Enumerate through the items array to add items below our header
		for (id scriptDictionary in itemScripts) {
			[ self runScript:scriptDictionary
			   withArguments:configScriptArguments
					 forMenu:menuHeaderTag
				  controller:sender];
		 }		
	}
	// Notifiy our observers that plugins have loaded 
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:PluginsHaveLoadedNotfication
	 object:self];
	
}


- (void) addConfigScriptArguments
{
	configScriptArguments = [[NSMutableArray alloc] init];
	[ configScriptArguments addObject:@"-v"];
}


- (BOOL)runScript:(NSDictionary *)scriptDictionary
	withArguments:(NSMutableArray *)scriptArguments
		  forMenu:(NSInteger)menuTag
	   controller:(id)sender

{	
	// Check for any scripts running at the moment
	[self waitForLastScriptToFinish];
	// Take control of the run lock
	scriptIsRunning = YES;
	
	/*[self setScriptIsRunning:scriptDictionary forMenu:myMenuItem];*/
	// Create a pool so we don't leak on our NSThread
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *scriptPath = [scriptDictionary objectForKey:@"scriptPath"];
	
	NSString *scriptExtention = [scriptDictionary objectForKey:@"scriptExtention"];
	
	if ([[scriptDictionary objectForKey:@"scriptIsInBundle"] boolValue]){
		scriptPath = [mainBundle pathForResource:scriptPath ofType:scriptExtention];
		// Z1 an't get this to work without build phase addtions to copy the directory
		//scriptPath = [mainBundle pathForResource:scriptPath	ofType:scriptExtention inDirectory:@"bin"];
		if (!scriptPath) {
			if (debugEnabled)NSLog(@" No Script path found");
			
		}
		else {
			if(debugEnabled) NSLog(@"Found script path:%@",scriptPath);
		}
		
	}
	// Validate script exits and is executable
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:scriptPath]){
		if(debugEnabled) NSLog(@"Script exists at path:%@",scriptPath);
	}
	else {
		NSException    *anException;
		if (debugEnabled)NSLog(@"Script does NOT exist at path:%@",scriptPath);
		NSString *aReason = [ NSString stringWithFormat:@"Script missing: %@",scriptPath];
		anException = [NSException exceptionWithName:@"Missing Script" 
											  reason:aReason
											userInfo:nil];
		return NO;
	}
	// Check script is executable
	if ([[NSFileManager defaultManager]isExecutableFileAtPath:scriptPath]) {
		if (debugEnabled)NSLog(@"Validated script is executable");
		
	}
	else {
		NSException    *anException;
		if (debugEnabled)NSLog(@"Script is NOT executable at path:%@",scriptPath);
		NSString *aReason = [ NSString stringWithFormat:@"Script not executable: %@",scriptPath];
		anException = [NSException exceptionWithName:@"Script Attributes" 
											  reason:aReason
											userInfo:nil];
		return NO;
	}
	
	// Run the Task - Z1: Needs to be broken out
	
	NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: scriptPath];
	
	
	
	[task setArguments: scriptArguments];
	
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
	//Set to help with Xcode debug log issues
	[task setStandardInput:[NSPipe pipe]];
	
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    [task launch];
    NSData *data;
    data = [file readDataToEndOfFile];
	
    NSString *scriptOutput;
	[task waitUntilExit];
    scriptOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	if (!scriptOutput) {
		scriptOutput = @"Error";
	}
	int status = [task terminationStatus];
	scriptIsRunning = NO;
	//[ self stopMainProgressIndicator];
	if ( status > 0 ){
		[self setFailedEndStatusFromScript:scriptDictionary
								 withError:scriptOutput
							  withExitCode:status
								   forMenu:menuTag
								controller:sender];
		return NO;

	}
	else {
	// exit 0
	[self setEndStatusFromScript:scriptDictionary
					  withOutPut:scriptOutput
						 forMenu:menuTag
					  controller:sender];
		return YES;
	}
	[pool drain];
	
}


-(void)setFailedEndStatusFromScript:(NSDictionary *)scriptDictionary
						  withError:(NSString *)errorMessage
					   withExitCode:(int)exitStatus
							forMenu:(NSInteger)menuTag
						 controller:(id)sender
{
	NSString *scriptFailedTitle;
	NSString *scriptFailedDescription;
	BOOL isAlternate;
	// Set if the menu is alternate or not
	isAlternate = [[scriptDictionary objectForKey:@"isAlternate"]boolValue];

	
	if (exitStatus == 1) {
		// Use Generic Message for non custom statuses
		scriptFailedTitle = [scriptDictionary valueForKey:@"scriptFailedTitle"];
		if (debugEnabled)NSLog(@"Found Script Failed message: %@",scriptFailedTitle);
		
		
		if (debugEnabled)NSLog(@"Script: %@ exited 1 setting warning icon",scriptFailedTitle);
		
		[ sender setPluginHeaderYellow:menuTag];
		
	}
	scriptFailedDescription = @"Script Output Supressed";
	/*
	 if (!scriptFailedDescription) {
	 if (errorMessage = NULL) {
	 scriptFailedDescription = @"Unkown";
	 }
	 else {
	 scriptFailedDescription = errorMessage;
	 }
	 
	 }*/
	if (exitStatus > 1) {
		NSString *exitStatusKey = [ NSString stringWithFormat:@"%d",exitStatus ];
		if(debugEnabled)NSLog(@"Found exit status:%@",exitStatusKey);
		// Read in our exit status info from keys
		NSDictionary *exitCodes = [ scriptDictionary objectForKey:@"exitCodes" ];
		NSDictionary *exitCode	= [ exitCodes objectForKey:exitStatusKey ];
		// Red status for exit codes that are greater then 1
		if (exitStatus >= 192){
			if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[NO]--");
			[ sender setPluginHeaderRed:menuTag];
		}
		
		// Grab Our Specific Error code
		scriptFailedTitle = [ exitCode objectForKey:@"scriptFailedTitle"];
		scriptFailedDescription = [exitCode objectForKey:@"scriptFailedDescription"];

		// Just in case we forgot to add an exit code string
		if (!exitCode) {
			scriptFailedTitle = [ scriptDictionary objectForKey:@"scriptFailedTitle"];
			scriptFailedDescription = [scriptDictionary objectForKey:@"scriptFailedDescription"];
			// Set Red in all other cases
			[ sender setPluginHeaderRed:menuTag];
		}
		
	}
	if (exitStatus == 192) {
		// Grey status for Exit 192
		[sender setPluginHeaderGrey:menuTag];
		
	}
	
	[self setStatus:scriptFailedTitle
		withMessage:scriptFailedDescription
			forMenu:menuTag
		 controller:sender
		asAlternate:isAlternate];

}

-(void)setStatus:(NSString *)scriptTitle
	 withMessage:(NSString *)scriptDescription 
		 forMenu:(NSInteger)menuTag
	  controller:(id)sender
	 asAlternate:(BOOL)alternate
{
	if (debugEnabled)NSLog(@"Finished script: %@",scriptTitle);
	// Set the menu items Tool Tip
	// Set the menu Items text
	[ sender addPluginMenuChild:scriptTitle
					withToolTip:scriptDescription
					asAlternate:alternate];
}

-(void)waitForLastScriptToFinish
{
	while (scriptIsRunning) {
		[NSThread sleepForTimeInterval:0.5f];
		if (debugEnabled)NSLog(@"Waiting for last script to run...");
	}
}

-(void)setEndStatusFromScript:(NSDictionary *)scriptDictionary
				   withOutPut:scriptOutput
					  forMenu:(NSInteger)menuTag
					controller:(id)sender
{
	// Check if we were passed an empty value.
	NSString *scriptTitle;
	if (![scriptOutput isEqualToString:@""]) {
		scriptTitle = scriptOutput;
	}
	else {
		scriptTitle = [scriptDictionary objectForKey:@"scriptEndTitle"];
	}

	NSString *scriptDescription = [scriptDictionary objectForKey:@"scriptEndDescription"];
	BOOL isAlternate = [[scriptDictionary objectForKey:@"isAlternate"]boolValue];

	if(debugEnabled)NSLog(@"Successful Script run:%@",scriptTitle);
	if(debugEnabled)NSLog(@"Successful Script Description:%@",scriptDescription);
	
	// Update the menu to Green
	[sender setPluginHeaderGreen:menuTag];
	if(debugEnabled) NSLog(@"%@: Shell Script exited 0",scriptTitle);
	// Add the Child Menu on Successful Exits
	[ sender addPluginMenuChild:scriptTitle
					withToolTip:scriptDescription 
					asAlternate:isAlternate];

}

@end
