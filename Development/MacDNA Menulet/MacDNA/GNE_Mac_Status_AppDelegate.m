//
//  GNE_Mac_Status_AppDelegate.m
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 7/5/11.
//  Copyright Genentech 2011 . All rights reserved.
//

#import "GNE_Mac_Status_AppDelegate.h"
// Our Custom Classes
#import "SummaryWindowController.h"
#import "Plugins.h"
#import "GlobalStatus.h"
#import "Constants.h"
#import "Recon.h"
#import "RepairController.h"

// Our NSValueTransformers
#import "RoundNumberTransformer.h"
#import "RoundNumberTransformerNeg.h"
#import "DivideByTen.h"
#import "DivideByTenNeg.h"



// System Configuration used for Computer Name Lookup
#import <SystemConfiguration/SystemConfiguration.h>
// Our includes for FSEvents
#include <CoreFoundation/CoreFoundation.h>
#include <CoreFoundation/CFString.h>


// Our FSEvents Call Back code to Update menus on change of our homeDirectory
static void feCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {
	//NSLog(@"Notified our homeDirectory was changed");
	[(GNE_Mac_Status_AppDelegate *)clientCallBackInfo updateAllMenus];

}



@implementation GNE_Mac_Status_AppDelegate

@synthesize window;
// Updates for our new preferences
@synthesize myDiskSpaceUsedNumber;
@synthesize backupDateString;
@synthesize bundleVersionNumber;

# pragma mark -
# pragma mark ********** Method Overrides **********
# pragma mark -

-(id)init
{
    [ super init];
	if(debugEnabled)NSLog(@"DEBUG: Adding an Observer for %@ on thread:%@",RequestStatusUpdateNotification,[NSThread currentThread]);
	// Add to our notification
	if(debugEnabled)NSLog(@"DEBUG: Using Default Notification Center: %@",[NSNotificationCenter defaultCenter]);
	
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveUpdateRequest:) 
                                                 name:RequestStatusUpdateNotification
                                               object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pluginsHaveLoaded:) 
                                                 name:PluginsHaveLoadedNotfication
                                               object:nil];
	
	// Value Transformers
	
	// create an autoreleased instance of our value transformer
	roundNumberTransformer = [[[RoundNumberTransformer alloc] init]
					   autorelease];
	
	// register it with the name that we refer to it with
	[NSValueTransformer setValueTransformer:roundNumberTransformer
									forName:@"RoundNumberTransformer"];
	
	roundNumberTransformerNeg = [[[RoundNumberTransformerNeg alloc] init]
							  autorelease];
	
	// register it with the name that we refer to it with
	[NSValueTransformer setValueTransformer:roundNumberTransformerNeg
									forName:@"RoundNumberTransformerNeg"];
	
	// create an autoreleased instance of our value transformer
	divideByTenTransformer = [[[DivideByTen alloc] init]
							  autorelease];
	
	
	// create an autoreleased instance of our value transformer
	divideByTenNegTransformer = [[[DivideByTenNeg alloc] init]
							  autorelease];
	
	// register it with the name that we refer to it with
	[NSValueTransformer setValueTransformer:divideByTenNegTransformer
									forName:@"DivideByTenNegTransformer"];
	
	// register it with the name that we refer to it with
	[NSValueTransformer setValueTransformer:divideByTenTransformer
									forName:@"DivideByTenTransformer"];
	
	// Read in our Settings
	[ self readInSettings];
	
	[ self initScripts];
	[ self watchControlDirectory];
	
	// Init our ivar for Global Status Array
	if (!globalStatusArray) {
		globalStatusArray = [[ NSMutableArray alloc] init];
	}
	if (!globalStatusController) {
		globalStatusController = [[GlobalStatus alloc] init];
	}
	recon = [[Recon alloc]init];
	// Setup our non derffered status
	deferedStaus = NO;

	// And Return
	if (!self) return nil;
    return self;
}

- (void) pluginsHaveLoaded:(NSNotification *) notification
{
	// Enable the Status Menu now that plugins have loaded
	[statusItem setEnabled:YES];
	[statusItem setToolTip:@"Mac DNA"];

}

- (void) receiveUpdateRequest:(NSNotification *) notification
{
	if(debugEnabled)NSLog(@"DEBUG: Recieved Request to Update Global Status Array");
	[self updateAllMenus];
}
- (void) repairComplete:(NSNotification *) notification
{
	if(debugEnabled)NSLog(@"NOTICE: Recieived Repair Complete Notification");
	/*if (pleaseWaitWindow) {
		[pleaseWaitWindow release];
	}*/
}

// Set Red
-(void)setPluginHeaderRed:(NSInteger)menuTag
{
	NSMenuItem *myMenu = [statusMenu itemWithTag:menuTag];
	if(debugEnabled) NSLog(@"DEBUG: Setting NSOnstate image to red: %@",[[statusMenu itemWithTag:menuTag] title]);
	
	[myMenu performSelectorOnMainThread:@selector(setOffStateImage:)
													   withObject:[NSImage imageNamed:@"red"]
													waitUntilDone:false];
	[myMenu setState:NSOffState];
}

// Set Green

-(void)setPluginHeaderGreen:(NSInteger)menuTag
{
	NSMenuItem *myMenu = [statusMenu itemWithTag:menuTag];
	
	if(debugEnabled) NSLog(@"DEBUG: Setting NSOnstate image to green: %@",[[statusMenu itemWithTag:menuTag] title]);
	
	[myMenu performSelectorOnMainThread:@selector(setOnStateImage:)
								 withObject:[NSImage imageNamed:@"green"]
							  waitUntilDone:false];
	[myMenu setState:NSOnState];
}

// Set Yellow

-(void)setPluginHeaderYellow:(NSInteger)menuTag
{
	NSMenuItem *myMenu = [statusMenu itemWithTag:menuTag];
	
	if(debugEnabled) NSLog(@"DEBUG: Setting NSMixedstate image to yellow: %@",[[statusMenu itemWithTag:menuTag] title]);
	
	[myMenu performSelectorOnMainThread:@selector(setMixedStateImage:)
													   withObject:[NSImage imageNamed:@"yellow"]
													waitUntilDone:false];
	[myMenu setState:NSMixedState];
}

// Set Grey

-(void)setPluginHeaderGrey:(NSInteger)menuTag
{
	if(debugEnabled) NSLog(@"DEBUG: Setting NSOffstate image to grey: %@",[[statusMenu itemWithTag:menuTag] title]);
	
	[[statusMenu itemWithTag:menuTag] performSelectorOnMainThread:@selector(setOffStateImage:)
													   withObject:[NSImage imageNamed:@"grey"]
													waitUntilDone:false];
	[[statusMenu itemWithTag:menuTag] setState:NSOffState];
}

-(NSInteger)addPluginMenuHeader:(NSString *)myTitle
{
	if(debugEnabled) NSLog(@"DEBUG: Adding Menu Header: %@",myTitle);
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:myTitle
												  action:@selector(updatePluginsButton:) keyEquivalent:@""]; 
	
	// Check where our Updates menu is and add below
	updateMenuIndex = [statusMenu indexOfItem:pluginsPlaceHolder];
	NSInteger menuIndex = updateMenuIndex;
	if(debugEnabled) NSLog(@"Found Updates at Index of %ld",menuIndex);
	
	// Check if the current index already exists
	if (!currentMenuIndex){
		// Find one place above th repair menu option.
		menuIndex = menuIndex -1;
		currentMenuIndex = menuIndex;
		if(debugEnabled) NSLog(@"Found Menu Index of %ld",menuIndex);
		
	}
	[statusMenu insertItem:item atIndex:currentMenuIndex];
	// Create the Sub Menu
	[item setSubmenu:refreshMenu];
	
	
	NSInteger menuTag = menuTag + 1;
	// Set the Menu Tag
	NSMenuItem *myMenuItem = [ statusMenu itemAtIndex:currentMenuIndex];
	[myMenuItem setTag:menuTag];
	//NSInteger seperatorIndex = [statusMenu indexOfItem:[ statusMenu itemAtIndex:currentMenuIndex]] -1;
	//r[statusMenu insertItem:[NSMenuItem separatorItem] atIndex:seperatorIndex];
	return menuTag;
}

-(NSInteger)addPluginMenuChild:(NSString *)myTitle
			  withToolTip:(NSString *)myToolTip
				   asAlternate:(BOOL)alternate
{
	if(debugEnabled) NSLog(@"Adding Menu Header: %@",myTitle);
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:myTitle
												  action:NULL keyEquivalent:@""]; 
	
	// Check where our Updates menu is and add below
	updateMenuIndex = [statusMenu indexOfItem:repairStatusItem];
	NSInteger menuIndex = updateMenuIndex;
	if(debugEnabled) NSLog(@"Found Updates at Index of %ld",menuIndex);
	
	// Check if the current index already exists
	if (!currentMenuIndex){
		// Find one place above the repair menu option.
		menuIndex = menuIndex -1;
		currentMenuIndex = menuIndex;
		if(debugEnabled) NSLog(@"Found Menu Index of %ld",menuIndex);
		
	}
	[statusMenu insertItem:item atIndex:currentMenuIndex + 1];
	// Set Our Tag 100+ are Child Menu Items
	NSInteger menuTag = menuTag + 100;
	[item setTag:menuTag];
	[item setToolTip:myToolTip];
	if(debugEnabled)NSLog(@"Checking is menu:%@ is alternate:%d",myTitle,alternate);
	if (alternate) {
		if(debugEnabled)NSLog(@"Was told YES menu: %@ is alternate: %d",myTitle,alternate);
		[ item setKeyEquivalent:@""];
		[ item setAlternate:YES];
		[ item setKeyEquivalentModifierMask:NSAlternateKeyMask];
	}
	// Add The Seperator
	//NSInteger seperatorIndex = [statusMenu indexOfItem:[ statusMenu itemAtIndex:currentMenuIndex]] -1;
	//r[statusMenu insertItem:[NSMenuItem separatorItem] atIndex:seperatorIndex];
	return menuTag;
}


- (void)awakeFromNib 
{ 
	// For our preference display
	self.bundleVersionNumber = [[mainBundle infoDictionary] valueForKey:@"CFBundleShortVersionString"];

	// Update all the Menus
	[self updateAllMenus];
	// Create the Status Item
	[self createStatusItem];
	// Intially Set Icon to Black
	[statusItem setImage:[NSImage imageNamed:@"sm_black_dna"]];
	//Set up the Plugin Menus Last
	
	// Check if plugins are enabled and run in another thread
	[self checkIfDeferAlertsEnabled:self];

	if ([self isSharedSystem] ||
		[self checkOverride:[settings objectForKey:@"pluginsOverride"]]) {
		[ statusItem setEnabled:YES];

	}
	else {
		[ pluginsSeperatorItem setHidden:NO];
		[NSThread detachNewThreadSelector:@selector(runPluginScripts:)
								 toTarget:plugins
							   withObject:self];
	}

	// Add our support menu links
	[self addSupportLinksMenuItems];
	// Enable our repairMenu
	[self updateRepairMenu:nil isEnabled:NO];
	repairController = [[RepairController alloc] init];
}

-(BOOL)isSharedSystem
{
	if ([[self deriveSystemtype] isEqualToString:@"Shared"]) {
		return YES;
	}
	else {
		return NO;
	}
	
}
# pragma mark -
# pragma mark Support Link Menus (Web Links)
# pragma mark -

- (void)addSupportLinksMenuItems
{
	[statusItem setToolTip:@"Loading Plugins..."];

	NSString *subMenuTitle;
	NSString *getURL;
	if (!supportLinks) {
		supportLinks = [[NSArray alloc] initWithArray:[settings objectForKey:@"supportLinks"]];

	}
	for(NSDictionary *object in supportLinks){
		// A couple of Keys in the Dict inside the Array
		subMenuTitle = [object objectForKey:@"subMenuTitle"];
		getURL = [object objectForKey:@"getURL"];
		NSInteger n = [ supportLinks indexOfObject:object];
		NSInteger menuTag = n +255;
		//[ supportLinkItem setImag
		supportLinkArrayItem = [supportLinkItem
								  insertItemWithTitle:subMenuTitle
								  action:@selector(openSupportLink:)
								  keyEquivalent:@""
								  atIndex:n];
		
		// Set a menu tag to programatically find the URL in the future
		[ supportLinkArrayItem setTag:menuTag];
		[ supportLinkArrayItem setToolTip:getURL];
		[ supportLinkArrayItem setTarget:self];

	}
	
	//supportLinkItem
}

- (void)openPageInSafari:(NSString *)url
{
	NSDictionary* errorDict;
	NSAppleEventDescriptor* returnDescriptor = NULL;
	NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:
								   [NSString stringWithFormat:
								   @"\
								   tell app \"Safari\"\n\
								   activate \n\
								   make new document at end of documents\n\
								   set URL of document 1 to \"%@\"\n\
								   end tell\n\
								   ",url]];
	returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
	[scriptObject release];
	
}


/**
    Returns the support directory for the application, used to store the Core Data
    store file.  This code uses a directory named "GNE_Mac_Status" for
    the content, either in the NSApplicationSupportDirectory location or (if the
    former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportDirectory {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"Mac DNA"];
}


/**
    Creates, retains, and returns the managed object model for the application 
    by merging all of the models found in the application bundle.
 */
 
- (NSManagedObjectModel *)managedObjectModel {

    if (managedObjectModel) return managedObjectModel;
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
    Returns the persistent store coordinator for the application.  This 
    implementation will create and return a coordinator, having added the 
    store for the application to it.  (The directory for the store is created, 
    if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {

    if (persistentStoreCoordinator) return persistentStoreCoordinator;

    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSAssert(NO, @"Managed object model is nil");
        if(debugEnabled)NSLog(@"%@:%s No model to generate a store from", [self class], _cmd);
        return nil;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSError *error = nil;
    
    if ( ![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] ) {
		if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory,error]));
            if(debugEnabled)NSLog(@"DEBUG: Error creating application support directory at %@ : %@",applicationSupportDirectory,error);
            return nil;
		}
    }
    
    NSURL *url = [NSURL fileURLWithPath: [applicationSupportDirectory stringByAppendingPathComponent: @"storedata"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType 
                                                configuration:nil 
                                                URL:url 
                                                options:nil 
                                                error:&error]){
        [[NSApplication sharedApplication] presentError:error];
        [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
        return nil;
    }    

    return persistentStoreCoordinator;
}

/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
 
- (NSManagedObjectContext *) managedObjectContext {

    if (managedObjectContext) return managedObjectContext;

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"com.gene.macdna" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];

    return managedObjectContext;
}

/**
    Returns the NSUndoManager for the application.  In this case, the manager
    returned is that of the managed object context for the application.
 */
 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


/**
    Performs the save action for the application, which is to send the save:
    message to the application's managed object context.  Any encountered errors
    are presented to the user.
 */
 
- (IBAction) saveAction:(id)sender {

    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        if(debugEnabled)NSLog(@"%@:%s unable to commit editing before saving", [self class], _cmd);
    }

    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}


/**
    Implementation of the applicationShouldTerminate: method, used here to
    handle the saving of changes in the application managed object context
    before the application terminates.
 */
 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    if (!managedObjectContext) return NSTerminateNow;

    if (![managedObjectContext commitEditing]) {
        if(debugEnabled)NSLog(@"%@:%s unable to commit editing to terminate", [self class], _cmd);
        return NSTerminateCancel;
    }

    if (![managedObjectContext hasChanges]) return NSTerminateNow;

    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
    
        // This error handling simply presents error information in a panel with an 
        // "Ok" button, which does not include any attempt at error recovery (meaning, 
        // attempting to fix the error.)  As a result, this implementation will 
        // present the information to the user and then follow up with a panel asking 
        // if the user wishes to "Quit Anyway", without saving the changes.

        // Typically, this process should be altered to include application-specific 
        // recovery steps.  
                
        BOOL result = [sender presentError:error];
        if (result) return NSTerminateCancel;

        NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        [alert release];
        alert = nil;
        
        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;

    }

    return NSTerminateNow;
}


/**
    Implementation of dealloc, to release the retained variables.
 */
 
- (void)dealloc {
	// default
    [window release];
    [managedObjectContext release];
    [persistentStoreCoordinator release];
    [managedObjectModel release];

	// FSEvent stop
	FSEventStreamStop(_stream);
	FSEventStreamInvalidate(_stream); /* will remove from runloop */
	FSEventStreamRelease(_stream);
	free(_context);

	// Remove ourself from Notification Center
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}
# pragma mark -
# pragma mark ********** Our Methods **********
# pragma mark -

# pragma mark Init Scripts

- (void)createStatusItem 
{ 
	statusItem = [[[NSStatusBar systemStatusBar] 
				   statusItemWithLength:NSVariableStatusItemLength] retain];
	[statusItem setHighlightMode:YES];
	[statusItem setEnabled:NO]; 
	[statusItem setMenu:statusMenu]; 
}

- (void)readInSettings 
{ 	

	mainBundle = [NSBundle bundleForClass:[self class]];
	NSString *settingsPath = [mainBundle pathForResource:SettingsFileResourceID
												  ofType:@"plist"];
	NSDictionary *defaults = [[NSDictionary alloc] initWithContentsOfFile:settingsPath];
	
	// Register our defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	
	settings = [NSUserDefaults standardUserDefaults];
	
	

}




-(void)initScripts
{
	configScriptArguments = [[NSMutableArray alloc] init]; 
	
	startUpRoutineArguments = [[NSMutableArray alloc] init];

	getSoftwareUpdates = [settings objectForKey:@"getSoftwareUpdates"];
	
	debugEnabled = [[settings objectForKey:@"debugEnabled"] boolValue];
	
	plugins	= [[ Plugins alloc] init];

}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSArray *urlData;
	NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	// Now you can parse the URL and perform whatever action is needed
    urlString = [urlString substringFromIndex:9];
	urlString = [urlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	urlData = [urlString componentsSeparatedByCharactersInSet:
			   [NSCharacterSet characterSetWithCharactersInString:@"?"]
			   ];
	if(debugEnabled)NSLog(@"url = %@", urlString);
	if(debugEnabled)NSLog(@"The content of  url array is: %@",urlData);
	
	NSString *directive = [urlData objectAtIndex:1];
	if ([directive isEqualToString:@"activate"]) {
		if(debugEnabled)NSLog(@"Recievied activate notification");
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:ShowPleaseWaitNotification
		 object:self];
		return;
	}
	if ([directive isEqualToString:@"start"]) {
		if(debugEnabled)NSLog(@"Recievied start notification");
		// post notification
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:StartPleaseWaitNotification
		 object:self];
		return;

	}
	if ([directive isEqualToString:@"stop"]) {
		if(debugEnabled)NSLog(@"Recievied start notification");
		// post notification
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:AttemptToRepairCompleteNotification
		 object:self];
		return;

	}
	if ([directive isEqualToString:@"repair"]) {
		if(debugEnabled)NSLog(@"Recievied start notification");
		// post notification
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:RequestAttemptToRepairNotification
		 object:self];
		return;
	}
	else {
		if(debugEnabled)NSLog(@"Recieived unkown directive: %@",directive);
	}
	
	
	
	return;
}

-(void)setMyStatus:(NSString *)myStatus
	setDescription:(NSString *)myDescription
		   setMenu:(NSMenuItem *)myMenu
		withReason:(NSString *)reason
		withMetric:(NSString *)metric
{
	if(debugEnabled)NSLog(@"DEBUG: Set Global Status was passed reason:%@",reason);
	NSMutableDictionary * myStatusDictionary = [[ NSMutableDictionary alloc] init];
	
	// Create a temp status dictionary that we can mutate
	[ myStatusDictionary setObject:myStatus forKey:@"status"];
	[ myStatusDictionary setObject:myDescription forKey:@"discription"];
	[ myStatusDictionary setObject:myMenu forKey:@"menu"];
	[ myStatusDictionary setObject:reason forKey:@"reason"];
	[ myStatusDictionary setObject:metric forKey:@"metric"];

	// I am treating an array like a dictionary here.
	// Need to figure out if there is a better way
	NSInteger removeMe = 365535;
	NSMutableArray *issueFile = [[ NSMutableArray alloc] init];

	for ( id object in globalStatusArray){
		NSString * discription = [object objectForKey:@"discription"];
		if ([discription isEqualToString:[myStatusDictionary objectForKey:@"discription"]]) {
			
			removeMe = [globalStatusArray indexOfObject:object];
		}
		NSMutableDictionary * saveDict = [[ NSMutableDictionary alloc] initWithDictionary:object];
		// Thin out the Menu Preferences
		[ saveDict removeObjectForKey:@"menu"];
		// Generate our Menu Title as the description
		NSString *menuTitle = [[ object objectForKey:@"menu"] title];
		[saveDict setValue:menuTitle  forKey:@"title"];
		[issueFile addObject:saveDict];

	}
	// Checking is the value is not declared.
	if (removeMe != 365535) {
		if(debugEnabled)NSLog(@"Found Index:%ld to remove",removeMe);
		[globalStatusArray removeObjectAtIndex:removeMe];
	}
	// Add our status Dictionary to the Global Status Array
	[globalStatusArray addObject:myStatusDictionary];

	// Let objects know the Global Status is being updated
	NSMutableDictionary *globalStatusUpdate = [[NSMutableDictionary alloc] init];
	// Pass the mutated Data to our NSTable
	[ globalStatusUpdate setValue:issueFile forKey:@"globalStatusArray"];
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:StatusUpdateNotification
	 object:self
	 userInfo:globalStatusUpdate];
	
	// File Drop the Global Status Array
	BOOL gsaWroteSuccess = [ globalStatusUpdate writeToFile:@"/private/tmp/gsa.plist" atomically:YES];
	if (gsaWroteSuccess) {
		if(debugEnabled)NSLog(@"Wrote the current Global Status Array to file");
	}
	else {
		if(debugEnabled)NSLog(@"Unable to write Global Status Array to file");
	}
	// Check if we have instantiated our Global Status Object 	
}



# pragma mark FSEvents


-(void)watchControlDirectory
{
	NSString *homeDirectory = [settings objectForKey:@"homeDirectory"];
	CFStringRef path = (CFStringRef)homeDirectory;
    CFArrayRef pathsToWatch = CFArrayCreate(NULL, (const void **)&path, 1, NULL);
    
    /* Use context only to simply pass the array controller */
    _context = (FSEventStreamContext*)malloc(sizeof(FSEventStreamContext));
    _context->version = 0;
    _context->info = (void*)self; 
    _context->retain = NULL;
    _context->release = NULL;
    _context->copyDescription = NULL;
	
    _stream = FSEventStreamCreate(NULL,
								  &feCallback,
								  _context,
								  pathsToWatch,
								  kFSEventStreamEventIdSinceNow, /* Or a previous event ID */
								  1.0, /* Latency in seconds */
								  kFSEventStreamCreateFlagNone
								  );
    
    FSEventStreamScheduleWithRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	
	//Start the stream
	Boolean startedStreamOK = FSEventStreamStart(_stream);
	if (!startedStreamOK) {
		if(debugEnabled) NSLog(@"ERROR: Could not start the FSEvents stream"); 
	}
	else {
		if(debugEnabled) NSLog(@"FSEvents stream started");
	}	
}

-(void)setGlobalStatus{
	if (!lastOffender) {
		if (debugEnabled) NSLog(@"No last offender array");
		lastOffender = [[NSMutableArray alloc] init];
	}
	// Loop through all statuses
	if (debugEnabled) NSLog(@"▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼---Global Status---▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼");
	if (debugEnabled) NSLog(@"%@",globalStatusArray);
	if (debugEnabled) NSLog(@"▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲---Global Status---▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲");
	if (!checkingGlobalStatus) {
		checkingGlobalStatus = YES;
		
		if (debugEnabled) NSLog(@"DEBUG:Processing global status array...");
		// May use this Class later
		if ([globalStatusArray count] >0) {
			if(debugEnabled)NSLog(@"DEBUG: Sending the global status array to the Global Status Object:%@",globalStatusArray);
			[ globalStatusController setGlobalStatusArray:globalStatusArray];
		}
		
		for (id object in globalStatusArray) {
			if (debugEnabled) NSLog(@"Processing global status object:,%@",object);
			// Grab data from current object
			NSString *myStatus = [ object objectForKey:@"status"]; 
			NSString *myDescription = [ object objectForKey:@"discription"];
			
			if (debugEnabled) NSLog(@"Setting Global Status: %@ for Item:%@",myStatus,myDescription);
			NSMenuItem *myMenu = [ object objectForKey:@"menu"];
			
			if ([myStatus isEqualToString:@"Critical"]) {
				[self setIconRed];
				[lastOffender addObject:object];
				//return;
			}
			if ([myStatus isEqualToString:@"Warning"]) {
				[self setWarningIcon:myMenu];
				[lastOffender addObject:object];
				//return;
			}			
			// If our current status is passed
			NSDictionary *removeObject = [[NSDictionary alloc] init];
			if ([myStatus isEqualToString:@"Passed"] || [myStatus isEqualToString:@"Offline"] ) {
				// Check the last Offender if we passed to clear status
				if (debugEnabled) NSLog(@"DEBUG: Processing last offender array...");
				/*NSEnumerator *enumerateLast = [lastOffender objectEnumerator];
				id lastObject;
				while (lastObject = [enumerateLast nextObject]) {*/
				for (id lastObject in lastOffender){
					if (debugEnabled) NSLog(@"DEBUG: Processing last offender object:,%@",lastObject);
					NSString *lastStatus = [ lastObject objectForKey:@"status"]; 
					NSString *lastDescription = [ lastObject objectForKey:@"discription"];
					
					if ([lastDescription isEqualToString:myDescription]) {
						if (debugEnabled) NSLog(@"DEBUG: Found previous status object:,%@",lastObject);
						// Check for previous critical
						if ([lastStatus isEqualToString:@"Critical"]) {
							if(debugEnabled)NSLog(@"Processing Critical Recovery:%@",myDescription);
							//Reset to Black
							[self setIconBlack];
							removeObject = lastObject;
						}
						// Check for previous Warning
						if ([lastStatus isEqualToString:@"Warning"]) {
							if(debugEnabled)NSLog(@"Processing Warning Recovery: %@",myDescription);
							//Reset to Black
							[ self setIconBlack];
							removeObject = lastObject;
						}
						if ([lastStatus isEqualToString:@"Passed"]) {
							if(debugEnabled)NSLog(@"DEBUG: Previous status for %@:  was already passed",myDescription);
						}
					}
					
				}
			}
			if (removeObject) {
				[lastOffender removeObjectIdenticalTo:removeObject];
			}

		}
		if(debugEnabled) NSLog(@"DEBUG: Releasing global status control to other checks...");
		checkingGlobalStatus = NO;
	}
	else {
		if(debugEnabled) NSLog(@"DEBUG: Checking Global Status: %d",checkingGlobalStatus);
		if(debugEnabled) NSLog(@"DEBUG: Global Status Being Updated by another check");
	}
	// Good measure
	checkingGlobalStatus = NO;
}

# pragma mark -- NSTask methods
-(void)taskDone:(NSString *)text 
{
	// Debug
	//if (debugEnabled) NSLog(@"DEBUG: Found text:\n %@",text);
		// Convert Plist from string
		NSData* plistData = [text dataUsingEncoding:NSUTF8StringEncoding];
		// Propertly List
		NSString *error;
		NSPropertyListFormat format;
		NSArray * plist = [NSPropertyListSerialization propertyListFromData:plistData
															mutabilityOption:NSPropertyListImmutable
																		 format:&format
															   errorDescription:&error];
	//if (debugEnabled) NSLog(@"DEBUG: Found plist:\n %@",plist);
			if([plist isKindOfClass:[NSArray class]])
			{
				if(debugEnabled) NSLog(@"DEBUG: System Profiler output validated as array");
				[_task terminate];
			}
			else {
				if(debugEnabled) NSLog(@"DEBUG: Error System Profiler output is not an array");		
			}
			// Check the plist
			if(!plist){
				if(debugEnabled)NSLog(@"ERROR:Error system_profiler output: %@",error);
				[error release];
				[_fileHandle readInBackgroundAndNotify];
				return;
				
			}
			else {
				// Parse the text information
				[self parseSystemProfiler:plist];
				if (debugEnabled) NSLog(@"DEBUG: Completed parsing system profiler");
			}
	if (debugEnabled) NSLog(@"DEBUG: Completed taskDone");
}

-(void)readPipe: (NSNotification *)notification
{
	NSMutableData *data;
	if( [notification object] != _fileHandle ){
		if(debugEnabled)NSLog(@"Notification object does not equal fileHandle");
		return;
	}
	data = [[notification userInfo] 
					objectForKey:NSFileHandleNotificationDataItem];
	[ data appendData:[_fileHandle availableData]];
	/*NSData *readData;
	while ((readData = [_fileHandle availableData]) && [readData length]) {
		NSLog(@"Waiting for data appending...");
		[data appendData: readData];
	}
	// We now have our full results in a NSString*/
	NSString *text = [[NSString alloc] initWithData:data 
											encoding:NSASCIIStringEncoding];
	if (debugEnabled) NSLog(@"Found availableData: %@",text);

		[self taskDone:text];
}



-(void)runTaskSystemProfiler{
	if (_task) {
		if (debugEnabled) NSLog(@"DEBUG: Found existing task...releasing");
		[_task release];
	}
	_task = [[NSTask alloc] init];

	NSData *data;
	// Start
	NSPipe *pipe = [NSPipe pipe];
	
	//_fileHandle = [pipe fileHandleForReading];
	//[_fileHandle readInBackgroundAndNotify];
	// Grab both our system profile outputs
	[_task setLaunchPath:@"/usr/sbin/system_profiler"];
	[_task setArguments:[NSArray arrayWithObjects:@"-xml",
						 @"SPSerialATADataType",
						 @"SPPowerDataType",
						 nil]];
	[_task setStandardOutput: pipe];
	//Set to help with Xcode debug log issues
	[_task setStandardInput:[NSPipe pipe]];
	[_task setStandardError: pipe];
	[_task launch];
	NSData *readData;
	 while ((readData = [_fileHandle availableData]) && [readData length]) {
		 if(debugEnabled)NSLog(@"Waiting for command to finish...");
	 }
	NSFileHandle *file;
	file = [pipe fileHandleForReading];
	data = [file readDataToEndOfFile];
	 // We now have our full results in a NSString
	NSString *text = [[NSString alloc] initWithData:data 
										   encoding:NSASCIIStringEncoding];
	//if (debugEnabled) NSLog(@"Constructed Text: %@",text);
	
	[self taskDone:text];
	if (debugEnabled) NSLog(@"DEBUG: Completed runTaskSystemProfiler");


}


# pragma mark System Profiler Parsing

-(void)parseSystemProfiler:(NSArray *)plist{
	// Stop the loop?
		for (id rootObject in plist){
			id rootObjectClass = rootObject;
			//if (debugEnabled) NSLog(@"parseSystemProfiler processing: %@",rootObject);
			if([rootObjectClass isKindOfClass:[NSDictionary class]]){
				NSString * _dataType = [ rootObject objectForKey:@"_dataType"];
				if(debugEnabled)NSLog(@"Found Data Type:%@",_dataType);
				if (debugEnabled) NSLog(@"DEBUG: Attempting to derive battery status");
				if ([ _dataType isEqualToString:@"SPPowerDataType"]) {
					if(debugEnabled)NSLog(@"Found dataType: SPPowerDataType");
					[self parseBatteryInformation:rootObject];
					continue;

				}
				if (debugEnabled) NSLog(@"DEBUG: Attempting to derive smart status");
				if ([ _dataType isEqualToString:@"SPSerialATADataType"]) {
					if (debugEnabled) NSLog(@"Found dataType: SPSerialATADataType");
					[self parseSmartInformation:rootObject];	
					continue;
				}
			}
		}
}

- (void)parseBatteryInformation:(NSDictionary *)rootObject{
	// Parse the Battery Information out of the system profiler xmls
	NSArray * _items = [ rootObject objectForKey:@"_items"];
	for ( id _item in _items){
		id _itemClass = _item;
		if([_itemClass isKindOfClass:[NSDictionary class]]){
			NSString * _name = [ _item objectForKey:@"_name" ];
			if (!_name) {
				continue;
			}
			else {
				if(debugEnabled) NSLog(@"DEBUG: Found Name: %@",_name);
			}

			if ([_name isEqualToString:@"spbattery_information"]){
				if(debugEnabled)NSLog(@"Found key: spbattery_information" );
				NSDictionary *sppower_battery_health_info =
					[ _item objectForKey:@"sppower_battery_health_info"];
				
				sppower_battery_health = [sppower_battery_health_info objectForKey:@"sppower_battery_health"];
				sppower_battery_cycle_count =
					[sppower_battery_health_info objectForKey:@"sppower_battery_cycle_count"];
				
				if(debugEnabled)NSLog(@"DEBUG: Found Health: %@",sppower_battery_health);
				if(debugEnabled)NSLog(@"DEBUG: Found Cycle Count: %@",sppower_battery_cycle_count);
				[self performSelectorOnMainThread:@selector(updateBatteryInfo)
												   withObject:nil
												waitUntilDone:true];
				if (debugEnabled) NSLog(@"DEBUG: Completed updateBatteryInfo");
				break;
			}
			else {
				if (debugEnabled) NSLog(@"DEBUG: Found Other Key:%@",_name);
			}
		}
		else {
			if(debugEnabled) NSLog(@"DEBUG: _item is not a dictionary:%@",_item);
			
		}
	}
	if (debugEnabled) NSLog(@"DEBUG: Mthod Completed parseBatteryInformation");
	
}


// Parse the smart information from syste profiler
- (void)parseSmartInformation:(NSDictionary *)rootObject{
	if(debugEnabled) NSLog(@"DEBUG: Attemping to gather system profiler information");
	NSArray * _items = [ rootObject objectForKey:@"_items"];
	for ( id _item in _items){
		id _itemClass = _item;
		if([_itemClass isKindOfClass:[NSDictionary class]]){
				NSString * _name = [ _item objectForKey:@"_name" ];
				if (!_name) {
					continue;
				}
				NSArray * __items = [ _item objectForKey:@"_items"];
				for ( id __item in __items){
					id __itemClass = __item;
					if([__itemClass isKindOfClass:[NSDictionary class]]){
						NSString * _name = [ __item objectForKey:@"_name" ];
						if (!_name) {
								continue;
						}
						NSString * bsd_name = [ __item objectForKey:@"bsd_name" ];
						// Make sure we are looking at the startup disk
						if(debugEnabled) NSLog(@"DEBUG: Found bsd_name:%@",_item);
						if ([bsd_name isEqualToString:@"disk0"]) {
							if(debugEnabled)NSLog(@"DEBUG: Found HD: %@",_name);
							size = [ __item objectForKey:@"size" ];
							if(debugEnabled)NSLog(@"DEBUG: Found HD Size: %@",size);
							smart_status = [ __item objectForKey:@"smart_status" ];
							if(debugEnabled)NSLog(@"DEBUG: Found HD SMart Status: %@",smart_status);
							[ self updateSmartMenu] ;


						}
						else {
							continue;
						}


					}
				}
		}
		else{
			if(debugEnabled)NSLog(@"_item is not a dictionary:%@",_item);
			
		}
	}
	
}

#pragma mark -
#pragma mark Run Scripts
#pragma mark -

- (int)runScript:(NSDictionary *)scriptDictionary
	withArguments:(NSMutableArray *)scriptArguments

{	
	// Check for any scripts running at the moment
	[self waitForLastScriptToFinish];
	// Take control of the run lock
	scriptIsRunning = YES;
	// Create a pool so we don't leak on our NSThread
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *scriptPath = [scriptDictionary objectForKey:@"scriptPath"];
	
	NSString *scriptExtention = [scriptDictionary objectForKey:@"scriptExtention"];
	
	if ([[scriptDictionary objectForKey:@"scriptIsInBundle"] boolValue]){
		scriptPath = [mainBundle pathForResource:scriptPath ofType:scriptExtention];
		// Can't get this to work without build phase addtions
		//scriptPath = [mainBundle pathForResource:scriptPath	ofType:scriptExtention inDirectory:@"bin"];
		if (!scriptPath) {
			if(debugEnabled)NSLog(@"ERROR: No Script path found");

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
		if(debugEnabled)NSLog(@"ERROR: Script does NOT exist at path:%@",scriptPath);
		NSString *aReason = [ NSString stringWithFormat:@"Script missing: %@",scriptPath];
		anException = [NSException exceptionWithName:@"Missing Script" 
											  reason:aReason
											userInfo:nil];
		return NO;
	}
	// Check script is executable
	if ([[NSFileManager defaultManager]isExecutableFileAtPath:scriptPath]) {
		if(debugEnabled)NSLog(@"Validated script is executable: %@",scriptPath);
		
	}
	else {
		NSException    *anException;
		if(debugEnabled)NSLog(@"ERROR:Script is NOT executable at path:%@",scriptPath);
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
    scriptOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	[task waitUntilExit];
	
	int status = [task terminationStatus];
	scriptIsRunning = NO;
	return status;
	[pool drain];
	
}

-(void)waitForLastScriptToFinish
{
	while (scriptIsRunning) {
		[NSThread sleepForTimeInterval:0.5f];
		if(debugEnabled)NSLog(@"Waiting for last script to run...");
	}
}

-(void)setStatus:(NSString *)scriptTitle
	 withMessage:(NSString *)scriptDescription 
		 forMenu:(NSMenuItem *)myMenuItem
{
	if(debugEnabled)NSLog(@"Running script: %@",scriptTitle);
	// Set the menu Items text
	[ myMenuItem setTitle:scriptTitle];
	
	if(debugEnabled)NSLog(@"Description: %@",scriptDescription);
	// Set the menu items Tool Tip
	[ myMenuItem setToolTip:scriptDescription];
}

-(void)setScriptIsRunning:(NSDictionary *)scriptDictionary 
				  forMenu:(NSMenuItem *)myMenuItem
{
	[ self setStatusFromScript:scriptDictionary forMenu:myMenuItem];
}

-(void)setStatusFromScript:(NSDictionary *)scriptDictionary
				   forMenu:(NSMenuItem *)myMenuItem
{
	//Main method for setting the status text
	NSString *scriptTitle = [scriptDictionary objectForKey:@"scriptTitle"];
	NSString *scriptDescription = [scriptDictionary objectForKey:@"scriptDescription"];
	
	[self setStatus:scriptTitle withMessage:scriptDescription forMenu:myMenuItem];
}

-(void)setEndStatusFromScript:(NSDictionary *)scriptDictionary
					  forMenu:(NSMenuItem *)myMenuItem
					forHeader:(NSMenuItem *)myMenuItemHeader
{
	//Main method for setting the status text
	NSString *scriptTitle = [scriptDictionary objectForKey:@"scriptEndTitle"];
	NSString *scriptDescription = [scriptDictionary objectForKey:@"scriptEndDescription"];
	// Update the menu to Green
	if(debugEnabled) NSLog(@"%@: Shell Script exited 0",scriptTitle);
	[ self setMenuItem:myMenuItemHeader
				 state:@"Passed"
	   withDescription:@"Updates"
			withReason:scriptDescription
			withMetric:@""];
	// Set the status
	[self setStatus:scriptTitle
		withMessage:scriptDescription
			forMenu:myMenuItem];
}

-(void)setFailedEndStatusFromScript:(NSDictionary *)scriptDictionary
						  withError:(NSString *)errorMessage
					   withExitCode:(int)exitStatus 
							forMenu:(NSMenuItem *)myMenuItem
						  forHeader:(NSMenuItem *)myMenuItemHeader
{
	
	NSString *scriptFailedTitle;
	NSString *scriptFailedDescription;
	if (exitStatus == 1) {
		// Use Generic Message for non custom statuses
		scriptFailedTitle = [scriptDictionary valueForKey:@"scriptFailedTitle"];
		if(debugEnabled)NSLog(@"ERROR: Found Script Failed message: %@",scriptFailedTitle);
	
		//[ myMenuItemHeader setMixedStateImage:yellow];
		[myMenuItemHeader performSelectorOnMainThread:@selector(setMixedStateImage:)
										   withObject:[NSImage imageNamed:@"yellow"]
										waitUntilDone:false];
		/*[myMenuItemHeader performSelectorOnMainThread:@selector(setState:)
										   withObject:NSMixedState
										waitUntilDone:false];*/
		
		if(debugEnabled)NSLog(@"ERROR: Script: %@ exited 1 setting warning icon",scriptFailedTitle);
		[ myMenuItemHeader setState:NSMixedState];

		[self setWarningIcon:myMenuItemHeader];


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
	if (exitStatus == 192) {
		// Yellow status for Exit 1
		[myMenuItemHeader performSelectorOnMainThread:@selector(setOnStateImage:)
										   withObject:[NSImage imageNamed:@"grey"]
										waitUntilDone:false];
		/*[myMenuItemHeader performSelectorOnMainThread:@selector(setState:)
		 withObject:NSMixedState
		 waitUntilDone:false];*/
		[ myMenuItemHeader setState:NSOnState];
	}
	if (exitStatus > 1) {
		NSString *exitStatusKey = [ NSString stringWithFormat:@"%d",exitStatus ];
		if(debugEnabled)NSLog(@"Found exit status:%@",exitStatusKey);
		// Read in our exit status info from keys
		NSDictionary *exitCodes = [ scriptDictionary objectForKey:@"exitCodes" ];
		NSDictionary *exitCode	= [ exitCodes objectForKey:exitStatusKey ];
		// Grab Our Specific Error code
		scriptFailedTitle = [ exitCode objectForKey:@"scriptFailedTitle"];
		scriptFailedDescription = [exitCode objectForKey:@"scriptFailedDescription"];
		// Red status for exit codes that are greater then 1
		if (exitStatus >= 192){
			if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[CRITICAL]--");
			[ self setMenuItem:myMenuItemHeader
						 state:@"Critical"
			   withDescription:@"NSTask" 
					withReason:scriptFailedDescription
					withMetric:@""];
		}
		

		
		// Just in case we forgot to add an exit code string
		if (!exitCode) {
			scriptFailedTitle = [ scriptDictionary objectForKey:@"scriptFailedTitle"];
			scriptFailedDescription = [scriptDictionary objectForKey:@"scriptFailedDescription"];
		}
		
	}

	
	[self setStatus:scriptFailedTitle
		withMessage:scriptFailedDescription
			forMenu:myMenuItem];
}


# pragma mark Methods Used to Update UI Menus
# pragma mark -

- (void)updateAllMenus{
	// Update our Menu Values
	[ self updateDiskMenu];
	[ self updateSystemType];
	// Setup our Polls
	[ self pollSoftwareUpdates];
	[ self pollCasper];
	[ self pollCrashPlan];
	[ self pollBattery];
	[ self setGlobalStatus];
	[ self pollGlobalStatus];
	// Poll battery covers both
	//[self pollSmartStatus];


}

-(void)updateBatteryInfo{
	// Configure Primary Menu
	if(debugEnabled) NSLog(@"DEBUG: Configuring Battery Menu...");
	NSString * batteryHealth = [ self getBatteryHealth];
	if (batteryHealth) {
		[ latestBatteryHealthStatusItem setTitle:batteryHealth];
	}
	else {
		if(debugEnabled)NSLog(@"ERROR: Unable to obtain battery stats");
		[ latestBatteryHealthStatusItem setTitle:@"Error: Missing Value"];
	}

	if(debugEnabled) NSLog(@"DEBUG: Finished getting battery health");
	
	// Configure Alternative menu
	if(debugEnabled) NSLog(@"DEBUG: Configuring Alternative Battery Menu");
	if (sppower_battery_cycle_count) {
		if(debugEnabled) NSLog(@"DEBUG: Found battery cycle_count: %@",sppower_battery_cycle_count);
		[ latestBatteryHealthStatusItemAlt setTitle:
		 [NSString stringWithFormat:@"Battery Cycles: %@",sppower_battery_cycle_count]];
	}
	else {
		[ latestBatteryHealthStatusItemAlt setTitle:[NSString stringWithFormat:@"Battery Cycles: Error"]];
	}
	[ latestBatteryHealthStatusItemAlt setKeyEquivalent:@""];
	[ latestBatteryHealthStatusItemAlt setAlternate:YES];
	[ latestBatteryHealthStatusItemAlt setKeyEquivalentModifierMask:NSAlternateKeyMask];
	
	if(debugEnabled) NSLog(@"DEBUG: Configuring Primary Battery Menu.");
	[ latestBatteryHealthStatusItem setKeyEquivalent:@""];

	if(debugEnabled) NSLog(@"DEBUG: Updated Battery Info ");
	return;
}

- (void)updateCasperMenu{
	// Setup Main Menu Item
	[ latestCasperStatusItem setKeyEquivalent:@""];
	[ latestCasperStatusItem setTitle:[self deriveCasperDate]];
	
	// Setup Alternative Menu Item 
	[ latestCasperStatusItemAlt setKeyEquivalent:@""];
	[ latestCasperStatusItemAlt setAlternate:YES];
	[ latestCasperStatusItemAlt setKeyEquivalentModifierMask:NSAlternateKeyMask];
	[ latestCasperStatusItemAlt setTitle:
	 [NSString stringWithFormat:@"Computer Name: %@", [self getComputerName]]];

}

- (void)updateSoftwareUpdatesMenu{
	// Setup Alternative Menu Item 
	[ latestUpdatesStatusItemAlt setKeyEquivalent:@""];
	[ latestUpdatesStatusItemAlt setAlternate:YES];
	[ latestUpdatesStatusItemAlt setKeyEquivalentModifierMask:NSAlternateKeyMask];
	[ latestUpdatesStatusItemAlt setTitle:
	 [NSString stringWithFormat:@"Last Check: %@",[ self deriveLastSoftwareUpdateCheck] ]];
	[latestOSVersionStatusItem setTitle:[NSString stringWithFormat:@"%@ (%@)",[self deriveSystemVersion],[self deriveBuildVersion]]];
	
	// Setup Main Menu Item
	[ latestUpdatesStatusItem setKeyEquivalent:@""];
	
}

- (void)updateDiskMenu
{
	// Setup Alternative Menu Item 
	[ latestHDUsageStatusItemAlt setKeyEquivalent:@""];
	[ latestHDUsageStatusItemAlt setAlternate:YES];
	[ latestHDUsageStatusItemAlt setKeyEquivalentModifierMask:NSAlternateKeyMask];
	[ latestHDUsageStatusItemAlt setTitle:
	 [NSString stringWithFormat:@"HD Free Space: %@",[self myFreeSpaceSize] ]];
	
	// Setup Main Menu Item
	[ latestHDUsageStatusItem setKeyEquivalent:@""];

	NSString *myFreeSpacePercent = [self myFreeSpacePercent];
	NSString *diskWarningInt = [ settings objectForKey:@"diskWarning"];
	NSString *diskCriticalInt = [ settings objectForKey:@"diskCritical"];
	
	// Set the Menu Text
	NSString *childMenuTitle = [NSString stringWithFormat:@"HD Usage: %@%%", myFreeSpacePercent];
	
	if(debugEnabled)NSLog(@"DEBUG: Generated Child Menu Item: %@",childMenuTitle);
	
	[ latestHDUsageStatusItem setTitle:childMenuTitle];
	
	if (![[settings objectForKey:@"warnHDUsage"] boolValue]) {
		if(debugEnabled) NSLog(@"DEBUG: Disk Usage is marked as offline:%@>%@",myFreeSpacePercent,diskWarningInt);
		[self setMenuItem:latestHardwareHeaderStatusItem
					state:@"Offline"
		  withDescription:@"DiskUsage" 
			   withReason:childMenuTitle
			   withMetric:myFreeSpacePercent];
		return;
	}
	if ([myFreeSpacePercent intValue] > [diskWarningInt intValue]) {
		if(debugEnabled) NSLog(@"DEBUG: Disk Usage is above warning threshold:%@>%@",myFreeSpacePercent,diskWarningInt);
		[self setMenuItem:latestHardwareHeaderStatusItem
					state:@"Warning"
		  withDescription:@"DiskUsage" 
			   withReason:childMenuTitle
			   withMetric:myFreeSpacePercent];
	}
	else {
		if(debugEnabled) NSLog(@"DEBUG: Disk Usage is not above warning threshold:%@<%@",myFreeSpacePercent,diskWarningInt);
		[self setMenuItem:latestHardwareHeaderStatusItem
					state:@"Passed"
		  withDescription:@"DiskUsage" 
			   withReason:childMenuTitle
			   withMetric:myFreeSpacePercent];
	}	
	if ([myFreeSpacePercent intValue] > [diskCriticalInt intValue]) {
		if(debugEnabled) NSLog(@"DEBUG: Disk Usage is not above critical threshold:%@>%@",myFreeSpacePercent,diskCriticalInt);
		[self setMenuItem:latestHardwareHeaderStatusItem
					state:@"Critical"
		  withDescription:@"DiskUsage" 
			   withReason:childMenuTitle
			   withMetric:myFreeSpacePercent];
	}

	
}

- (void)updateSmartMenu{
	if(debugEnabled) NSLog(@"DEBUG: Configuring Alternative Smart Menu");
	// Setup the Primary Menu
	if(debugEnabled) NSLog(@"DEBUG: Configuring Smart Menu");
	[ latestHDSmartStatusItem setKeyEquivalent:@""];
	[ latestHDSmartStatusItem setTitle:
	 [NSString stringWithFormat:@"%@", [self mySmartStatus]]];
	
	// Setup Alternative Menu Item 
	[ latestHDSmartStatusItemAlt setKeyEquivalent:@""];
	[ latestHDSmartStatusItemAlt setAlternate:YES];
	[ latestHDSmartStatusItemAlt setKeyEquivalentModifierMask:NSAlternateKeyMask];
	[ latestHDSmartStatusItemAlt setTitle:[NSString stringWithFormat:@"%@",[self myHDsize]]];
}
- (void)updateCrashplan{
	
	if ([self isSharedSystem] ||
		[self checkOverride:[settings objectForKey:@"backupOverride"]] ||
		![[settings objectForKey:@"warnOnBackupUsage"] boolValue] ) {
		// Hide the seperator
		[ latestBackupSeperatorItem setEnabled:NO ];
		// Hide the header
		[ latestBackupHeaderItem setHidden:YES];
		// Hide The main and alt status Items
		[ latestBackupStatusItem setHidden:YES];
		[ latestBackupStatusItemAlt setHidden:YES];
		[ latestBackupStatusItemAlt setAlternate:NO];
		// Hide the percentage and alt status items
		[ latestBackupPercentageStatusItem setHidden:YES];
		[ latestBackupPercentageStatusItemAlt setHidden:YES];
		[ latestBackupPercentageStatusItemAlt setAlternate:NO];
	}
	else {
		[ latestBackupSeperatorItem setHidden:NO];
		// Setup Alternative Menu Item 
		[ latestBackupStatusItemAlt setKeyEquivalent:@""];
		[ latestBackupStatusItemAlt setAlternate:YES];
		[ latestBackupStatusItemAlt setKeyEquivalentModifierMask:NSAlternateKeyMask];
		//[ latestBackupStatusItemAlt setTitle:
		//[NSString stringWithFormat:@"Client Version: %@",[self getCrashPlanVersion]]];
		//
		[ latestBackupStatusItemAlt setTitle:
		 [NSString stringWithFormat:@"%@",[self deriveCrashPlanUser]]];
		[ latestBackupStatusItem setKeyEquivalent:@""];
		[ latestBackupStatusItem setTitle:[self deriveCrashPlanDate]];
		[ latestBackupPercentageStatusItem setTitle:[self deriveBackupPercentage]];
		// Setup the Alternate Menu for Backup Percentage
		[ latestBackupPercentageStatusItemAlt setKeyEquivalent:@""];
		[ latestBackupPercentageStatusItemAlt setKeyEquivalentModifierMask:NSAlternateKeyMask];
		[ latestBackupPercentageStatusItemAlt setTitle:[ self deriveCrashPlanGUID]];
	}

}

-(void)updateSystemType{
	[ systemTypeItem setTitle:[NSString stringWithFormat:@"System Type: %@",[self deriveSystemtype]]];
	// Setup The Alternate Menu
	[ systemTypeItemAlt setKeyEquivalent:@""];
	[ systemTypeItemAlt setKeyEquivalentModifierMask:NSAlternateKeyMask];
	[ systemTypeItemAlt setTitle:[self deriveImageVersion]];
}

// Get Boolean Value for DiskUsage Stat checks
-(BOOL)evaluateBoolMenu:(NSMenuItem *)evalButton
{
    // Gather data from interface
    if ( [evalButton state] == NSOnState ){
		[ evalButton setState:NSOffState];
        return NO;
    }
    if ( [evalButton state] == NSOffState ){
		[ evalButton setState:NSOnState];
        return YES;
    }
	return YES;
}

- (IBAction)checkIfDeferAlertsEnabled:(id)sender
{
	deferEnabled = [[settings objectForKey:@"deferEnabled"] boolValue];
	if (deferEnabled) {
		if(debugEnabled)NSLog(@"Defer Alerts is enabled, adding menu");
		NSString *subMenuTitle = [settings objectForKey:@"deferDefaultText"];
		deferMenuItem = [statusMenu
						 insertItemWithTitle:subMenuTitle
						 action:@selector(deferAlertsMenuSelected:)
						 keyEquivalent:@""
						 atIndex:1];
		
		// Set a menu tag to programatically find the URL in the future
		[ deferMenuItem setToolTip:[settings objectForKey:@"deferDefaultToolTip"]];
		[ deferMenuItem setTarget:self];
		[ deferMenuItem setImage:[NSImage imageNamed:@"defer_sm"]];
		[ deferMenuItem setTag:1492];
	}
	else {
		if(debugEnabled)NSLog(@"Defer Alerts is NOT enabled.");
		if ([ statusMenu itemWithTag:1492]) {
			[ statusMenu removeItem:[ statusMenu itemWithTag:1492]];
		}
	}
	
}

-(void)updateDeferStatus
{
	deferedStaus = NO;
	[deferMenuItem setAction:@selector(deferAlertsMenuSelected:)];
	NSString *subMenuTitle = [settings objectForKey:@"deferDefaultText"];
	[deferMenuItem setTitle:subMenuTitle];
	
	[self updateAllMenus];
	
}


- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertFirstButtonReturn) {
		
		// Remove the current preferences
		NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
		[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
		
		// Syncronize 
		[[NSUserDefaults standardUserDefaults] synchronize];
		[NSApp terminate:self];
    }
	else {
		return;
	}

}

# pragma mark -
# pragma mark User intiated actions IBActions [Cancel] [OK]
# pragma mark -

- (IBAction)resetToDefaultsButton:(id)sender
{
	// Activate Our Application
//	[NSApp arrangeInFront:self];
//	[NSApp activateIgnoringOtherApps:YES];
	// Display a standard alert
//	int response;
//	NSAlert *alert = [[NSAlert alloc] init];
//	[alert addButtonWithTitle:@"OK"];
//	[alert addButtonWithTitle:@"Cancel"];

//	[alert setMessageText:@"Reset to Defaults?"];
//	[alert setInformativeText:@"Are you sure you want to reset all the settings back to their default values?"];
//	[alert setAlertStyle:NSWarningAlertStyle];
//	[alert beginSheetModalForWindow:[sender window]
//					  modalDelegate:self
//					 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
//						contextInfo:&response];
	//[alert runModal];
//	[alert release];
[preferencesPanel release];

}


// Needs some cleanup
- (IBAction)showPreferencesPanel:(id)sender
{
	
    // Check for an existing Window
	//if ( preferencesPanel ) {
	//	[preferencesPanel release];
	//} // end if
    
    // Having an issue with making this a key window
	[preferencesPanel makeKeyAndOrderFront:self];
	[NSApp arrangeInFront:self];
	[NSApp activateIgnoringOtherApps:YES];
    //[preferencesPanel release];
}


// Needs some cleanup
- (IBAction)savePreferencesButton:(id)sender
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	[preferencesPanel orderOut:self];
	[self updateAllMenus];

}

- (IBAction)updateBackupDateButton:(id)sender
{
	[self updateCrashplan];
}

- (IBAction)deferAlertsMenuSelected:(id)sender
{
	[deferMenuItem setOffStateImage:nil];
	[deferMenuItem setOnStateImage:nil];

	if(debugEnabled)NSLog(@"User asked to defer alerts");
	if ([deferMenuItem state] == NSOffState) {
		[deferMenuItem setState:NSOnState];
		if (deferTimer)
		{
			[deferTimer invalidate];
		}
		deferTimer = [[NSTimer scheduledTimerWithTimeInterval:86400.0
															target:self
														  selector:@selector(updateDeferStatus)
														  userInfo:nil
														   repeats:YES]retain];
		[deferTimer fire];
		// Format the date
		NSDate *todaysDate = [NSDate date];

		NSDate   *modDate = [ todaysDate addTimeInterval:86400];
		
		
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];		
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		NSLocale *enLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
		
		[dateFormatter setLocale:enLocale];
		// Realtive Date formatting on 10.6 and higher
		if ([dateFormatter respondsToSelector:@selector(setDoesRelativeDateFormatting:)]) {
			[dateFormatter setDoesRelativeDateFormatting:YES];
		}
		
		// Compare the Dates
		NSTimeInterval modDiff = [modDate timeIntervalSinceNow];
		NSTimeInterval todaysDiff = [todaysDate timeIntervalSinceNow];
		NSTimeInterval dateDiff = todaysDiff - modDiff;
		
		NSNumber *deferNumber = [NSNumber numberWithDouble:dateDiff];
		// Debug Messages
		if(debugEnabled) NSLog(@"The systems exact defer time was %@ seconds ago",[deferNumber stringValue] );
		if(debugEnabled) NSLog(@"The systems rounded defer time  was %d seconds ago",[deferNumber intValue] );
		NSString *dateString = [dateFormatter stringFromDate:modDate];
		
		NSString *menuText = [NSString stringWithFormat:@"Alerts disabled until: %@",dateString];
		[deferMenuItem setTitle:menuText];
		[deferMenuItem setAction:@selector(updateDeferStatu)];
		[statusItem setImage:[NSImage imageNamed:@"sm_black_dna"]];
		
		deferedStaus = YES;

		if (iconYellowTimer) {
			[iconYellowTimer invalidate];
		}
		if (iconRedTimer) {
			[iconRedTimer invalidate];
		}
		if (iconBlackTimer) {
			[iconBlackTimer invalidate];
		}

	}
	else {
		deferedStaus = NO;
		[deferMenuItem setState:NSOffState];
		if (deferTimer)
		{
			[deferTimer release];
		}
	}
}
-(IBAction)openSupportLink:(id)sender
{
	if(debugEnabled)NSLog(@"Was passed Menu: %@",sender);
	NSInteger menuTag = [sender tag];
	NSInteger n = menuTag - 255;
	NSString *getURL = [[supportLinks objectAtIndex:n] objectForKey:@"getURL"];
	[self openPageInSafari:getURL];
}
- (IBAction)toggleDiskUsage:(id)sender
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	//warnHDUsage = [self evaluateBoolMenu:subHDUsageToggleItem];
	warnHDUsage = [[settings objectForKey:@"warnHDUsage"] boolValue];
	if(debugEnabled)NSLog(@"Warn ON HD Usage is now:%d",warnHDUsage);
	// Update the menu, like a manual refresh
	[self updateDiskMenu];
	[self pollGlobalStatus];

}

- (IBAction)backupStatusButton:(id)sender
{
	
	NSString *reconToolPath  = [settings objectForKey:@"reconToolPath"];
	NSString *reconToolBundleID = [settings objectForKey:@"reconToolBundleID"];
	if(debugEnabled)NSLog(@"Using MacDNA Refresh path %@",reconToolPath);
	NSFileManager *myFileManager = [NSFileManager defaultManager];
	BOOL supportToolExists = [ myFileManager fileExistsAtPath:reconToolPath];
	
	if (supportToolExists){
		if(debugEnabled)NSLog(@"Found MacDNA Refresh path %@",reconToolPath);
		NSBundle *bundle = [NSBundle bundleWithPath:reconToolPath];
		NSString *path = [bundle executablePath];
		NSTask *task = [[NSTask alloc] init];
		[task setLaunchPath:path];
		[task launch];
		[task release];
		task = nil;
	}
	else {
		if(debugEnabled)NSLog(@"MacDNA Refresh missing using bundle id %@",reconToolBundleID);
		[ self displayMissingAlert ];
		NSWorkspace *ws = [NSWorkspace sharedWorkspace];
		NSString *appPath = [ws absolutePathForAppBundleWithIdentifier:reconToolBundleID];
		[ws launchApplication:appPath];
		if(debugEnabled)NSLog(@"Launched MacDNA Refresh Tool");
	}
    // Ask for Recon Update
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:RequestReconNotification
	 object:self];
    // Manually Update Current File
	[self updateCrashplan];
	[self pollGlobalStatus];
}

- (IBAction)securityStatusButton:(id)sender
{
        NSString *reconToolPath  = [settings objectForKey:@"reconToolPath"];
        NSString *reconToolBundleID = [settings objectForKey:@"reconToolBundleID"];
        if(debugEnabled)NSLog(@"Using MacDNA Refresh path %@",reconToolPath);
        NSFileManager *myFileManager = [NSFileManager defaultManager];
        BOOL supportToolExists = [ myFileManager fileExistsAtPath:reconToolPath];
        
        if (supportToolExists){
            if(debugEnabled)NSLog(@"Found MacDNA Refresh path %@",reconToolPath);
            NSBundle *bundle = [NSBundle bundleWithPath:reconToolPath];
            NSString *path = [bundle executablePath];
            NSTask *task = [[NSTask alloc] init];
            [task setLaunchPath:path];
            [task launch];
            [task release];
            task = nil;
        }
        else {
            if(debugEnabled)NSLog(@"MacDNA Refresh missing using bundle id %@",reconToolBundleID);
            [ self displayMissingAlert ];
            NSWorkspace *ws = [NSWorkspace sharedWorkspace];
            NSString *appPath = [ws absolutePathForAppBundleWithIdentifier:reconToolBundleID];
            [ws launchApplication:appPath];
            if(debugEnabled)NSLog(@"Launched MacDNA Refresh Tool");
        }
    // Ask for Recon Update
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:RequestReconNotification
	 object:self];
    // Manually Update Current File
	[self updateCasperMenu];
	[self pollGlobalStatus];
}

- (IBAction)hardwareStatusButton:(id)sender
    {
	if(debugEnabled) NSLog(@"DEBUG: User selected the hardware button");
	[ self updateDiskMenu];
	[ self pollBattery];
	[ self pollGlobalStatus];

}

- (IBAction)updatesStatusButton:(id)sender{
	if(debugEnabled) NSLog(@"DEBUG: User selected the updates button");
	[self pollSoftwareUpdates];
	[self pollGlobalStatus];
}

- (IBAction)updatePluginsButton:(id)sender
{
	[self updateAllMenus];
}

- (IBAction)summaryButton:(id)sender{
	if(debugEnabled) NSLog(@"DEBUG: User selected the summary button");
	// Check for an existing Window
	if ( summaryWindow ) {
		[summaryWindow release];
	} // end if
	summaryWindow	= [[SummaryWindowController alloc] initWithWindowNibName:@"SummaryWindow" owner:globalStatusController];
	if(debugEnabled)NSLog(@"App Delegate is sending the Global Status Array:%@",globalStatusArray);
	if(debugEnabled)NSLog(@"To the Summary Window Controller");

	//[ summaryWindow setGlobalStatusArray:globalStatusArray];

	[summaryWindow showWindow:self];
	// Adding this back in due to duplications in the plist
	// Moved this down further as we are now posting notifications for GSA updates
	[self updateCasperMenu];
    [self updateAllMenus];
	[self pollGlobalStatus];
}


- (IBAction)attemptToFixButton:(id)sender{
// post notification
	// post notification
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:RequestAttemptToRepairNotification
	 object:self];
}
# pragma mark -
# pragma mark Flashing Updates
-(void)startFlashing:(NSString *)color
{

		if ([color isEqualToString:@"yellow"]) {
			// Release our previous flasher so we don't double up
			if (iconYellowTimer) {
				if(debugEnabled) NSLog(@"DEBUG: Already flashing yellow, restarting timer");
				[ iconYellowTimer invalidate];
				// Don't remove all objects here
			}
			iconYellowTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5
																target:self
															  selector:@selector(flashYellow)
															  userInfo:nil
															   repeats:YES]retain];
			[iconYellowTimer fire];
            // Added To Stop Yellow Flashing
			if (![[settings objectForKey:@"flashOnWarning"] boolValue]) {
				return;
			}
		}
		if ([color isEqualToString:@"red"]) {
			// Release our previous flasher so we don't double up
			if (iconRedTimer) {
				if(debugEnabled) NSLog(@"DEBUG: Already flashing red, restarting timer");
				// Disable All Other timers when we are critical
				[ self stopFlashing];
				// Don't remove all objects here
			}
			iconRedTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5
															 target:self
														   selector:@selector(flashRed)
														   userInfo:nil
															repeats:YES]retain];
			[iconRedTimer fire];
			// Added To Stop Red Flashing
			if (![[settings objectForKey:@"flashOnCritical"] boolValue]) {
				return;
			}
		}
		// Always flash black no matter what
		if (iconBlackTimer) {
			if(debugEnabled) NSLog(@"DEBUG: Already flashing black, restarting timer");
			[ iconBlackTimer invalidate];
			// Don't remove all objects here
		}
		iconBlackTimer = [[NSTimer scheduledTimerWithTimeInterval:1.5
													   target:self
													 selector:@selector(flashBlack)
													 userInfo:nil
													  repeats:YES]retain];
		// Start the Timer
		[iconBlackTimer fire];
}
-(void)stopFlashing{
	// Release our previous flasher so we don't double up
	if ([iconRedTimer isValid]) {
		if (debugEnabled) NSLog(@"DEBUG: Stopping Flashing by invalidating timer");

		[iconRedTimer invalidate];
	}
	if ([iconBlackTimer isValid]) {
		if (debugEnabled) NSLog(@"DEBUG: Stopping Flashing by invalidating timer");
		
		[iconBlackTimer invalidate];
	}
	if ([iconYellowTimer isValid]) {
		if (debugEnabled) NSLog(@"DEBUG: Stopping Flashing by invalidating timer");
		
		[iconYellowTimer invalidate];
	}
	// Set the icon to black for good measure
	if (debugEnabled) NSLog(@"DEBUG: Setting statusItem image to black...");
	[ statusItem setImage:[NSImage imageNamed:@"sm_black_dna"]];
}



// launch crashplan
-(IBAction)launchBackupTool:(id)sender 
{
	NSString *backupToolPath  = [settings objectForKey:@"backupToolPath"];
	if(debugEnabled)NSLog(@"Using Support Tool path %@",backupToolPath);
	NSFileManager *myFileManager = [NSFileManager defaultManager];
	BOOL supportToolExists = [ myFileManager fileExistsAtPath:backupToolPath];
	
	if (supportToolExists){
		if(debugEnabled)NSLog(@"Found Support Tool path %@",backupToolPath);
		NSBundle *bundle = [NSBundle bundleWithPath:backupToolPath];
		NSString *path = [bundle executablePath];
		NSTask *task = [[NSTask alloc] init];
		[task setLaunchPath:path];
		[task launch];
		[task release];
		task = nil;	
	}
	else {
		if(debugEnabled)NSLog(@"ERROR: Support Tool missing using bundle id %@",[settings objectForKey:@"backupBundleID"]);
		[ self displayMissingAlert ];
		NSWorkspace *ws = [NSWorkspace sharedWorkspace]; 
		NSString *appPath = [ws absolutePathForAppBundleWithIdentifier:[settings objectForKey:@"backupBundleID"]]; 
		[ws launchApplication:appPath];
		if(debugEnabled)NSLog(@"Launched Backup Tool");
	}
} 

// launch System Profiler
-(IBAction)launchSystemProfiler:(id)sender 
{
	
	NSString *backupToolPath  = @"/Applications/Utilities/System Profiler.app";
	NSString *backupBundleID = @"com.apple.systemprofiler";
	if(debugEnabled)NSLog(@"Using Support Tool path %@",backupToolPath);
	NSFileManager *myFileManager = [NSFileManager defaultManager];
	BOOL supportToolExists = [ myFileManager fileExistsAtPath:backupToolPath];
	
	if (supportToolExists){
		if(debugEnabled)NSLog(@"Found Support Tool path %@",backupToolPath);
		NSBundle *bundle = [NSBundle bundleWithPath:backupToolPath];
		NSString *path = [bundle executablePath];
		NSTask *task = [[NSTask alloc] init];
		[task setLaunchPath:path];
		[task launch];
		[task release];
		task = nil;	
	}
	else {
		if(debugEnabled)NSLog(@"ERROR:Support Tool missing using bundle id %@",backupBundleID);
		NSWorkspace *ws = [NSWorkspace sharedWorkspace]; 
		NSString *appPath = [ws absolutePathForAppBundleWithIdentifier:backupBundleID]; 
		[ws launchApplication:appPath];
		if(debugEnabled)NSLog(@"Launched Backup Tool");
	}
} 
// launch System Profiler
-(IBAction)launchDirectoryServiceTool:(id)sender 
{
	
	NSString *backupToolPath  = [settings objectForKey:@"directoryServiceToolPath"];
	NSString *backupBundleID = [settings objectForKey:@"directoryServiceToolBundleID"];
	if(debugEnabled)NSLog(@"Using Support Tool path %@",backupToolPath);
	NSFileManager *myFileManager = [NSFileManager defaultManager];
	BOOL supportToolExists = [ myFileManager fileExistsAtPath:backupToolPath];
	
	if (supportToolExists){
		if(debugEnabled)NSLog(@"Found Support Tool path %@",backupToolPath);
		NSBundle *bundle = [NSBundle bundleWithPath:backupToolPath];
		NSString *path = [bundle executablePath];
		NSTask *task = [[NSTask alloc] init];
		[task setLaunchPath:path];
		[task launch];
		[task release];
		task = nil;	
	}
	else {
		if(debugEnabled)NSLog(@"Support Tool missing using bundle id %@",backupBundleID);
		[ self displayMissingAlert ];
		NSWorkspace *ws = [NSWorkspace sharedWorkspace]; 
		NSString *appPath = [ws absolutePathForAppBundleWithIdentifier:backupBundleID]; 
		[ws launchApplication:appPath];
		if(debugEnabled)NSLog(@"Launched Backup Tool");
	}
} 


-(IBAction)launchPasswordTool:(id)sender 
{
	
	NSString *passwordToolPath  = [settings objectForKey:@"passwordToolPath"];
	NSString *passwordToolBundleID = [settings objectForKey:@"passwordToolBundleID"];
	if(debugEnabled)NSLog(@"Using Password Utility path %@",passwordToolPath);
	NSFileManager *myFileManager = [NSFileManager defaultManager];
	BOOL supportToolExists = [ myFileManager fileExistsAtPath:passwordToolPath];
	
	if (supportToolExists){
		if(debugEnabled)NSLog(@"Found Support Tool path %@",passwordToolPath);
		NSBundle *bundle = [NSBundle bundleWithPath:passwordToolPath];
		NSString *path = [bundle executablePath];
		NSTask *task = [[NSTask alloc] init];
		[task setLaunchPath:path];
		[task launch];
		[task release];
		task = nil;	
	}
	else {
		if(debugEnabled)NSLog(@"Password Utility missing using bundle id %@",passwordToolBundleID);
		[ self displayMissingAlert ];
		NSWorkspace *ws = [NSWorkspace sharedWorkspace]; 
		NSString *appPath = [ws absolutePathForAppBundleWithIdentifier:passwordToolBundleID]; 
		[ws launchApplication:appPath];
		if(debugEnabled)NSLog(@"Launched Backup Tool");
	}
} 

// launch crashplan
-(IBAction)launchSWUpdateTool:(id)sender 
{
	NSString *swupToolPath  = [settings objectForKey:@"swupToolPath"];
	if(debugEnabled)NSLog(@"Using Support Tool path %@",swupToolPath);
	NSFileManager *myFileManager = [NSFileManager defaultManager];
	BOOL supportToolExists = [ myFileManager fileExistsAtPath:swupToolPath];
	
	if (supportToolExists){
		if(debugEnabled)NSLog(@"Found Support Tool path %@",swupToolPath);
		NSBundle *bundle = [NSBundle bundleWithPath:swupToolPath];
		NSString *path = [bundle executablePath];
		NSTask *task = [[NSTask alloc] init];
		[task setLaunchPath:path];
		[task launch];
		[task release];
		task = nil;	
	}
	else {
		if(debugEnabled)NSLog(@"Support Tool missing using bundle id %@",[settings objectForKey:@"swUpdateBundleID"]);
		[ self displayMissingAlert ];
		NSWorkspace *ws = [NSWorkspace sharedWorkspace]; 
		NSString *appPath = [ws absolutePathForAppBundleWithIdentifier:[settings objectForKey:@"swUpdateBundleID"]]; 
		[ws launchApplication:appPath];
		if(debugEnabled)NSLog(@"Launched Software Update Tool");
	}
} 

-(void)displayMissingAlert
{
	// Activate Our Application
	[NSApp arrangeInFront:self];
	[NSApp activateIgnoringOtherApps:YES];
	// Display a standard alert
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"Locate"];
	[alert setMessageText:@"Support Application Missing"];
	[alert setInformativeText:@"Unable find support application at its normal location."];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert runModal];
	[alert release];
}

# pragma mark NSTimers
# pragma mark -
-(void)pollBattery{
	// Release our previous poll so we don't double up
	if ([batteryPoolTimer isValid]) {
		if(debugEnabled) NSLog(@"DEBUG:Found existing battery timer, releasing it");
		[batteryPoolTimer invalidate];
	}
	// Refresh every 24 hours (86400 seconds) and at launch
	batteryPoolTimer = [[NSTimer scheduledTimerWithTimeInterval:[[settings objectForKey:@"pollBatteryInterval"] intValue]
													   target:self
													 selector:@selector(runTaskSystemProfiler)
													 userInfo:nil
													  repeats:YES]retain];
	[batteryPoolTimer fire];
	
}

-(void)pollGlobalStatus{
	// Update our IP Address
	//[ self getCurrentIPAddress];
	// Release our previous poll so we don't double up
	if ([globalTimer isValid]) {
		if(debugEnabled) NSLog(@"DEBUG: Found existing global timer, releasing it");
		[globalTimer invalidate];
		checkingGlobalStatus = NO;
	}
	// Refresh every 24 hours (86400 seconds) and at launch
	globalTimer = [[NSTimer scheduledTimerWithTimeInterval:[[settings objectForKey:@"globalStatusInterval"] intValue]
														 target:self
													   selector:@selector(setGlobalStatus)
													   userInfo:nil
														repeats:YES]retain];
	[globalTimer fire];
	
}

-(void)pollCrashPlan{
	// Release our previous poll so we don't double up
	if ([backupPoolTimer isValid]) {
		if(debugEnabled) NSLog(@"DEBUG: Found existing battery timer, releasing it");
		[backupPoolTimer invalidate];
	}
	// Refresh every 24 hours (86400 seconds) and at launch
	backupPoolTimer = [[NSTimer scheduledTimerWithTimeInterval:[[settings objectForKey:@"pollBackupInterval"] intValue]
														 target:self
													   selector:@selector(updateCrashplan)
													   userInfo:nil
														repeats:YES]retain];
	[backupPoolTimer fire];
	
}
-(void)pollCasper{
	// Release our previous poll so we don't double up
	if ([casperPoolTimer isValid]) {
		if(debugEnabled)NSLog(@"Found existing battery timer, releasing it");
		[casperPoolTimer invalidate];
	}
	// Refresh every 24 hours (86400 seconds) and at launch
	casperPoolTimer = [[NSTimer scheduledTimerWithTimeInterval:86400
														target:self
													  selector:@selector(updateCasperMenu)
													  userInfo:nil
													   repeats:YES]retain];
	[casperPoolTimer fire];
	
}

- (void)pollSoftwareUpdates{
	if(debugEnabled) NSLog(@"DEBUG: Polling Software Updates");
	if (!softwareUpdateRunning) {
		if(debugEnabled)NSLog(@"Polling for SoftwareUpdates");
		// Release our previous poll so we don't double up
		if (swupPoolTimer) {
			if(debugEnabled)NSLog(@"Found existing softwareupdate poll, releasing it");
			[swupPoolTimer invalidate];
		}
		// Refresh every 24 hours (86400 seconds) and at launch
		swupPoolTimer = [[NSTimer scheduledTimerWithTimeInterval:86400
															 target:self
														   selector:@selector(runSoftwareUpdateThread)
														   userInfo:nil
															repeats:YES]retain];
		[swupPoolTimer fire];
	}
	else {
		if(debugEnabled)NSLog(@"Software update check already running");
	}


}

- (void)pollSmartStatus{
	// Release our previous poll so we don't double up
	if ([smartPoolTimer isValid]) {
		if(debugEnabled)NSLog(@"Found existing smart timer, releasing it");
		[smartPoolTimer invalidate];
	}
	// Refresh every 24 hours (86400 seconds) and at launch
	smartPoolTimer = [[NSTimer scheduledTimerWithTimeInterval:[[ settings objectForKey:@"pollSMARTInterval"] intValue]
														target:self
													  selector:@selector(runTaskSystemProfiler)
													  userInfo:nil
													   repeats:YES]retain];
	[smartPoolTimer fire];
}

- (void) addConfigScriptArguments
{
	[ configScriptArguments addObject:@"-v"];
}

- (void) addStartUpRoutineArguments
{
	[ startUpRoutineArguments addObject:@"-s"];	
}

-(void)runSoftwareUpdateThread{
	if(debugEnabled) NSLog(@"DEBUG: Running the softwareupdate thread");
	// Update Alternate Menus
	[ self updateSoftwareUpdatesMenu];

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *filePath = @"/Library/Preferences/com.apple.SoftwareUpdate.plist";
	
	// Check to see if the breadcrum file exists
	if ([fileManager fileExistsAtPath:filePath]){
		NSDictionary *plistSoftwareUpdate;
		plistSoftwareUpdate = [ [NSDictionary alloc] initWithContentsOfFile:filePath];
		NSString *numberOfUpdates = [ plistSoftwareUpdate objectForKey:@"LastUpdatesAvailable"];
		if (numberOfUpdates != nil) {
			// If the plist contains the value then we don't need to worry about multi run.
			if(debugEnabled)NSLog(@"Updates: Found %@ Updates..",numberOfUpdates);
			softwareUpdateRunning = NO;
		}
		// Check to see if value
		if (!numberOfUpdates) {
			// If the key does not exist in the file we run the softwareupdate command line
			if(debugEnabled)NSLog(@"Updates: LastUpdatesAvailable is undefined");
			if(debugEnabled)NSLog(@"Updates: in file: %@",filePath);

			[NSThread detachNewThreadSelector:@selector(runSoftwareUpdateTask)
									 toTarget:self
								   withObject:nil];
			return;
		}
		[self evaluateSoftwareUpdates:numberOfUpdates];
		softwareUpdateRunning = NO;
	}
}

-(void)evaluateSoftwareUpdates:(NSString *)numberOfUpdates
{
	if(debugEnabled)NSLog(@"Found %@ updates avaiable",numberOfUpdates);
	// Update the other menu items
	// Our holder for our final output
	NSString *childMenuTitle;
	// Check is we need to add an s
	NSString *s ;
	// Check for Zero Updates
	if ([numberOfUpdates intValue] == 0) {
		if(debugEnabled)NSLog(@"Updates: Found Zero Updates");
		// Add an s as there are no Update(s) avaiable
		s = @"s";
		if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[PASSED]--");
		childMenuTitle = [NSString stringWithFormat:@"You have %@ Update%@ Available",numberOfUpdates,s];
		[ self setMenuItem:latestUpdatesHeaderStatusItem
					 state:@"Passed"
		   withDescription:@"Updates" 
				withReason:childMenuTitle
				withMetric:numberOfUpdates];
		[ latestUpdatesStatusItem setTitle:childMenuTitle];
		return;
		
	}
	// Check for 1 update
	if ([numberOfUpdates intValue] == 1) {
		if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[WARNING]--");
		s = @"";
		childMenuTitle = [NSString stringWithFormat:@"You have %@ Update%@ Available",numberOfUpdates,s];
		[ self setMenuItem:latestUpdatesHeaderStatusItem
					 state:@"Warning"
		   withDescription:@"Updates" 
				withReason:childMenuTitle
				withMetric:numberOfUpdates];
		[ latestUpdatesStatusItem setTitle:childMenuTitle];
		return;
	}
	else {
		// Check for more then 1 updates
		if ([numberOfUpdates intValue] > 1) {
			if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[WARNING]--");
			s = @"s";
			childMenuTitle = [NSString stringWithFormat:@"You have %@ Update%@ Available",numberOfUpdates,s];
			[ self setMenuItem:latestUpdatesHeaderStatusItem
						 state:@"Warning"
			   withDescription:@"Updates" 
					withReason:childMenuTitle
					withMetric:numberOfUpdates];
			[ latestUpdatesStatusItem setTitle:childMenuTitle];
			return;
		}
	}
}

-(BOOL)runSoftwareUpdateTask
{
	if(debugEnabled) NSLog(@"DEBUG: Running the softwareupdate task");
	// Make sure this pool is created here.
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// Reset Header to Grey on launch 
	[ latestUpdatesHeaderStatusItem setState:NSMixedState];
	[ latestUpdatesHeaderStatusItem setMixedStateImage:[NSImage imageNamed:@"grey"]];
	[ latestUpdatesStatusItem setTitle:@"Checking for Updates..."];
	[ self addConfigScriptArguments ];
	[ self waitForLastScriptToFinish];
	
	int scriptResult;
	if ([configScriptArguments count] >0) {
		scriptResult = [ self runScript:getSoftwareUpdates
						  withArguments:configScriptArguments];
	}
	[ self evaluateSoftwareUpdates:[[NSNumber numberWithInt:scriptResult] stringValue]];
	softwareUpdateRunning = NO;
	// Update the menu
	[ pool drain];
	return scriptResult;
}

- (NSString *)getComputerName{
	NSString *hostname = (NSString *)SCDynamicStoreCopyComputerName(NULL, NULL);
	return hostname;
}

- (NSString *)getCrashPlanVersion{
	NSURL *crashPlanURL;
	NSString *bundleID = [settings objectForKey:@"backupBundleID"];
	CFStringRef crashPlanBundleIdentifier = (CFStringRef)bundleID;
	
	if (LSFindApplicationForInfo(kLSUnknownCreator,(CFStringRef)crashPlanBundleIdentifier,NULL,NULL,(CFURLRef *)&crashPlanURL) == kLSApplicationNotFoundErr)
		return nil;
	// Grab the Bundle
	NSBundle *crashPlanBundle = [NSBundle bundleWithPath:[crashPlanURL path]];
	// Init the Dictionary
	NSDictionary *crashPlanInfo = [crashPlanBundle infoDictionary];
	[crashPlanURL release];
	if(debugEnabled)NSLog(@"Found Crash Plan Version: %@",[crashPlanInfo objectForKey:@"CFBundleVersion"]);
	return [crashPlanInfo objectForKey:@"CFBundleVersion"];
}
# pragma mark -
# pragma mark Update Status Menu Icon Colors
# pragma mark -


// Sets the Status Item as Red
-(void)setIconRed{
	if(debugEnabled) NSLog(@"-------------------------SET RED---------------------------------");
	/*if ([globalStatus isEqualToString:@"Warning"]) {
		NSLog(@"Upgrading the warning status to: %@",globalStatus);
	}
	// Notify the system we are critical
	globalStatus = @"Critical";
	if(debugEnabled)NSLog(@"Global Status is now %@",globalStatus);*/
	
	// Notify the Summary Menu
	
	NSString *summaryTitle = [settings objectForKey:@"criticalTitle"];
	if(debugEnabled) NSLog(@"Setting Summary Menu to Critical with Title: %@",summaryTitle);
	[summaryMenuItem setTitle:[NSString stringWithFormat:@"%@",summaryTitle]];
	[summaryMenuItem setState:NSOffState];
	[summaryMenuItem setAction:@selector(summaryButton:)];
	[statusItem setImage:[NSImage imageNamed:@"sm_red_dna"]];
	
	// Update the Repair Status menu
	[self updateRepairMenu:nil isEnabled:YES];


	[self startFlashing:@"red"];
}

// Set warning
- (void)setWarningIcon:(NSMenuItem *)myMenu{
	if(debugEnabled) NSLog(@"▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼SET YELLOW▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼");
	// Start the Yellow Flashing ( internal check for Red Override)
	[self startFlashing:@"yellow"];
	
	[ myMenu setState:NSMixedState];
	NSString *summaryTitle = [settings objectForKey:@"warningTitle"];
	// Debug Code
	if(debugEnabled) NSLog(@"DEBUG: Yellow Summary Title: %@",summaryTitle);
	if(debugEnabled) NSLog(@"DEBUG: Yellow Menu: %@",myMenu);

		
	[ summaryMenuItem setTitle:[NSString stringWithFormat:@"%@",summaryTitle]];
	//  Set The NSMizedState Icon
	[ summaryMenuItem setState:NSMixedState];
	[ summaryMenuItem setAction:@selector(summaryButton:)];

	// Update the Repair Status menu
	[self updateRepairMenu:nil isEnabled:YES];


	// Debug code
	if(debugEnabled) NSLog(@"▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲SET YELLOW▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲");
}

// Sets the Status Item as Black
-(void)setIconBlack{
	if(debugEnabled) NSLog(@"▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼SET BLACK▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼");

	
	// Update the summary menu
	NSString *summaryTitle = [settings objectForKey:@"passedTitle"];
	[ summaryMenuItem setTitle:[NSString stringWithFormat:@"%@",summaryTitle]];
	[ summaryMenuItem setState:NSOnState];
	[ summaryMenuItem setAction:nil];

	
	// Stopping Flashing
	if(debugEnabled) NSLog(@"DEBUG: Stopping flashing due to black...");
	[ self stopFlashing];
	
	// Set Icon as black, redundant but for good measure
	[ statusItem setImage:[NSImage imageNamed:@"sm_black_dna"]];
	
	if(debugEnabled) NSLog(@"DEBUG: Black Summary Title: %@",summaryTitle);
	if(debugEnabled) NSLog(@"DEBUG: Black Menu: %@",summaryMenuItem);
	// Update the Repair Status Menu
	[self updateRepairMenu:nil isEnabled:NO];

	if(debugEnabled) NSLog(@"▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲SET BLACK▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲");
}

// Not thread safe
/*-(NSString *) getCurrentIPAddress
{
    NSArray *addresses = [[NSHost currentHost] addresses];
	
	for (NSString *myAddress in addresses) {
		if (![myAddress hasPrefix:@"127"] && [[myAddress componentsSeparatedByString:@"."] count] == 4) {
			ipv4Address = [NSString stringWithFormat:@"IP: %@",myAddress];

			
			break;
		} else {
			ipv4Address = @"IP: Not Available" ;
		}
	}
	return ipv4Address;
}*/


-(void)updateRepairMenu:(NSString *)menuTitle isEnabled:(BOOL)enabled
{
	if(debugEnabled) NSLog(@"Updating Repair Menu Title to: %@",menuTitle);
	//[repairStatusItem setImage:];
	NSInteger repairTag = 365534;
	[ repairStatusItem setTag:repairTag];
	if (enabled) {
		[repairStatusItem setAction:@selector(attemptToFixButton:)];
		[repairStatusItem setOffStateImage:[NSImage imageNamed:@"repair_sm"]];
		[repairStatusItem setState:NSOffState];
		[repairStatusItem setTitle:[settings objectForKey:@"repairNeededTitle"]];

	}
	else {
		[repairStatusItem setAction:@selector(summaryButton:)];
		[repairStatusItem setOnStateImage:[NSImage imageNamed:@"refresh_sm"]];
		[repairStatusItem setState:NSOnState];
		[repairStatusItem setTitle:[settings objectForKey:@"repairNotNeededTitle"]];

	}
	// Set Custom Title
	if (menuTitle) {
		[repairStatusItem setTitle:menuTitle ];

	}


}
# pragma mark Status Menu Flashers
# pragma mark -
// Swap the colors ( Flash from black to red )
-(void)flashBlack{
	NSString * currentColor = [[ statusItem image] name];
	if ([currentColor isEqualToString:@"sm_red_dna"]) {
		[statusItem setImage:[NSImage imageNamed:@"sm_black_dna"]];
	}
	if ([currentColor isEqualToString:@"sm_yellow_dna"]) {
		[statusItem setImage:[NSImage imageNamed:@"sm_black_dna"]];
	}
}
-(void)flashRed{
	if (deferedStaus) {
		[statusItem setImage:[NSImage imageNamed:@"sm_black_dna"]];
		[iconRedTimer invalidate];
		return;
	}
	NSString * currentColor = [[ statusItem image] name];
	if ([currentColor isEqualToString:@"sm_black_dna"]) {
		[statusItem setImage:[NSImage imageNamed:@"sm_red_dna"]];
	}
	if ([currentColor isEqualToString:@"sm_yellow_dna"]) {
		if(debugEnabled)NSLog(@"Red Found yellow icon, invalidating yellow flashing");
		[iconYellowTimer invalidate];
	}
}

-(void)flashYellow{
	if (deferedStaus) {
		[statusItem setImage:[NSImage imageNamed:@"sm_black_dna"]];
		[iconYellowTimer invalidate];
		return;
	}
	NSString * currentColor = [[ statusItem image] name];
	if ([currentColor isEqualToString:@"sm_black_dna"]) {
		[statusItem setImage:[NSImage imageNamed:@"sm_yellow_dna"]];
	}
	if ([currentColor isEqualToString:@"sm_red_dna"]) {
		if(debugEnabled) NSLog(@"DEBUG: Yellow Found red icon, invalidating yellow flashing");
		[iconYellowTimer invalidate];
	}
}

// Configure the menu system for the static content

- (void)setMenuItem:(NSMenuItem *)myMenuItem
			  state:(NSString * )myState
	withDescription:(NSString *)myDescription 
		 withReason:(NSString *)reason
		 withMetric:(NSString	*)metric
{
	if(debugEnabled) NSLog(@"DEBUG: Set Menu Item was passed reason: %@",reason);
	if(debugEnabled) NSLog(@"DEBUG: setMenuItem was called for : %@",[myMenuItem title]);


	// Check the passed state boolean
	if ([ myState isEqualToString:@"Passed"]) {
		if(debugEnabled) NSLog(@"DEBUG: Setting Menu to Green: %@",[myMenuItem title]);
		
		[ myMenuItem setState:NSOnState];
		/*NSImage *green = [[NSImage alloc] initWithContentsOfFile: [ mainBundle
																	pathForResource:@"green" ofType:@"png"]];*/

		if(debugEnabled) NSLog(@"DEBUG: Setting NSOnstate image to green: %@",[myMenuItem title]);
		[myMenuItem performSelectorOnMainThread:@selector(setOnStateImage:)
										   withObject:[NSImage imageNamed:@"green"]
										waitUntilDone:false];
		
		if(debugEnabled) NSLog(@"DEBUG: Setting my menu status...");
		[self setMyStatus:@"Passed"
		   setDescription:myDescription
				  setMenu:myMenuItem
			   withReason:reason
			   withMetric:metric];
		return;

	}
	else {
		if ([ myState isEqualToString:@"Warning"]){
			if(debugEnabled) NSLog(@"DEBUG: Setting Menu to yellow: %@",[myMenuItem title]);
			[ myMenuItem setState:NSMixedState];
			/*NSImage *yellow = [[NSImage alloc] initWithContentsOfFile: [ mainBundle
																	 pathForResource:@"yellow" ofType:@"png"]];*/
			if(debugEnabled) NSLog(@"DEBUG: Setting NSMixedState image to yellow: %@",[myMenuItem title]);
			[myMenuItem performSelectorOnMainThread:@selector(setMixedStateImage:)
										 withObject:[NSImage imageNamed:@"yellow"]
									  waitUntilDone:false];
			if(debugEnabled) NSLog(@"Prior to flashing message was: %@",[myMenuItem title]);
			
			// Update the Status
			[self setMyStatus:@"Warning"
			   setDescription:myDescription
					  setMenu:myMenuItem 
				   withReason:reason 			
				   withMetric:metric];
			[self setWarningIcon:myMenuItem];

			return;
			
		}
		if ([ myState isEqualToString:@"Offline"]){
			if(debugEnabled) NSLog(@"DEBUG: Setting Menu to grey: %@",[myMenuItem title]);
			[ myMenuItem setState:NSOffState];
			/*NSImage *red = [[NSImage alloc] initWithContentsOfFile: [ mainBundle
			 pathForResource:@"red" ofType:@"png"]];*/
			if(debugEnabled) NSLog(@"DEBUG: Setting NSOffstate image to grey: %@",[myMenuItem title]);
			[myMenuItem performSelectorOnMainThread:@selector(setOffStateImage:)
										 withObject:[NSImage imageNamed:@"grey"]
									  waitUntilDone:false];
			if(debugEnabled) NSLog(@"Prior to flashing message was: %@",[myMenuItem title]);
			[self setMyStatus:@"Passed"
			   setDescription:myDescription
					  setMenu:myMenuItem
				   withReason:reason 		 
				   withMetric:metric];
			return;
		}
		if ([ myState isEqualToString:@"Critical"]){
			if(debugEnabled) NSLog(@"DEBUG: Setting Menu to red: %@",[myMenuItem title]);
			[ myMenuItem setState:NSOffState];
			/*NSImage *red = [[NSImage alloc] initWithContentsOfFile: [ mainBundle
																	 pathForResource:@"red" ofType:@"png"]];*/
			if(debugEnabled) NSLog(@"DEBUG: Setting NSOffstate image to red: %@",[myMenuItem title]);
			[myMenuItem performSelectorOnMainThread:@selector(setOffStateImage:)
										 withObject:[NSImage imageNamed:@"red"]
									  waitUntilDone:false];
			if(debugEnabled) NSLog(@"Prior to flashing message was: %@",[myMenuItem title]);
			[self setMyStatus:@"Critical"
			   setDescription:myDescription
					  setMenu:myMenuItem
				   withReason:reason 		 
				   withMetric:metric];
			[self setIconRed];
			return;
		}

		
	}
}

# pragma mark Getters - Methods that Return values

- (NSString *)getBatteryHealth{
	if(debugEnabled) NSLog(@"DEBUG: Attempting to get battery health");
	
	// un comment below for example failure
	//sppower_battery_health = @"Check Battery";
	// Setup our return value
	
	NSString * childMenuTitle;
	if (!sppower_battery_health) {
		if(debugEnabled) NSLog(@"DEBUG: sppower_battery_health has no value");
		
		// Setup our return value
		childMenuTitle = [NSString stringWithFormat:@"Battery Health: Updating..."];
		if(debugEnabled) NSLog(@"DEBUG: Setting Menu to value:%@",childMenuTitle);
		
		//Set the menu item
		[ self setMenuItem:latestHardwareHeaderStatusItem
					 state:@"Critical"
		   withDescription:@"Battery" 
				withReason:childMenuTitle
				withMetric:@"No batteries availble"];
		return childMenuTitle;
	}
	else {
		if(debugEnabled) NSLog(@"DEBUG: sppower_battery_health has a value");
		
		// Check to make sure is a NSString
		
		if([sppower_battery_health isKindOfClass:[NSString class]]){
			if(debugEnabled) NSLog(@"DEBUG: Validated sppower_battery_health is a string");
			// Set up our return value
			childMenuTitle = [NSString stringWithFormat:@"Battery Health: %@",sppower_battery_health];
			
			// Check if the battery health is anything but Good
			if (![sppower_battery_health isEqualToString:@"Good"]) {
				if ([sppower_battery_health isEqualToString:@"Fair"]) {
					if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[WARNING]--");
					
					if(debugEnabled) NSLog(@"DEBUG: sppower_battery_health equals fair");
					
					if(debugEnabled) NSLog(@"DEBUG: Setting Menu to value:%@",childMenuTitle);
					
					// Menu and summary will show non "Good" value
					[ self setMenuItem:latestHardwareHeaderStatusItem
								 state:@"Warning"
					   withDescription:@"Battery" 
							withReason:childMenuTitle
							withMetric:sppower_battery_health];
				}
				else {
					if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[CRITICAL]--");
					
					if(debugEnabled) NSLog(@"DEBUG: sppower_battery_health does not equal Good");
					
					if(debugEnabled) NSLog(@"DEBUG: Setting Menu to value:%@",childMenuTitle);
					
					// Menu and summary will show non "Good" value
					[ self setMenuItem:latestHardwareHeaderStatusItem
								 state:@"Critical"
					   withDescription:@"Battery" 
							withReason:childMenuTitle
							withMetric:sppower_battery_health];
				}
			}
			else {
					[ self setMenuItem:latestHardwareHeaderStatusItem
								 state:@"Passed"
					   withDescription:@"Battery" 
							withReason:childMenuTitle
							withMetric:sppower_battery_health];

			}
			return childMenuTitle;
		}
		else {
			
			if(debugEnabled) NSLog(@"DEBUG: sppower_battery_health is not a string");
			
			childMenuTitle = [NSString stringWithFormat:@"Error Updating Value"];
			[ self setMenuItem:latestHardwareHeaderStatusItem
						 state:@"Offline"
			   withDescription:@"Battery" 
					withReason:childMenuTitle
					withMetric:@"Validation Error"];
			return childMenuTitle;
		}


	}

}

- (NSMutableArray *)getGlobalStatusArray
{
	if(debugEnabled) NSLog(@"Was asked to give our global status array");
	return globalStatusArray;
}

- (NSString *)mySmartStatus{
	// Check if value exists
	NSString *childMenu;
	if (!smart_status) {
		// If Smart status is not set
		if(debugEnabled) NSLog(@"Smart Status is Null");
		childMenu = [NSString stringWithFormat:@"HD Status: Updating..."];
		[ self setMenuItem:latestHardwareHeaderStatusItem
					 state:@"Warning"
		   withDescription:@"Smart" 
				withReason:@"?"
				withMetric:@"Invalid Value"];
		 
		 return childMenu;
	}
	else {
		childMenu = [NSString stringWithFormat:@"HD Status: %@",smart_status];

		if ([smart_status isEqualToString:@"Verified"]) {
			if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[PASSED]--");
			[ self setMenuItem:latestHardwareHeaderStatusItem
						 state:@"Passed"
			   withDescription:@"Smart" 
					withReason:childMenu
					withMetric:smart_status];
			if(debugEnabled)NSLog(@"Found Smart Status: %@",smart_status);
		}
		else {
			if ([smart_status isEqualToString:@"Not Supported"]) {
				if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[PASSED]--");
				[ self setMenuItem:latestHardwareHeaderStatusItem
							 state:@"Passed"
				   withDescription:@"Smart" 
						withReason:childMenu
						withMetric:smart_status];
				if(debugEnabled)NSLog(@"Found Smart Status: %@",smart_status);
				
			}
			else {
				if(debugEnabled)NSLog(@"Smart Status: %@ does not equal:Verified",smart_status);
				if(debugEnabled) NSLog(@"#####################STATE CHANGE###################--[CRITICAL]--");
				[ self setMenuItem:latestHardwareHeaderStatusItem
							 state:@"Critical"
				   withDescription:@"Smart"
						withReason:childMenu
						withMetric:smart_status];
				if(debugEnabled)NSLog(@"Found Smart Status: %@",smart_status);
			}
		}
		return childMenu;
	}
}


- (NSString *)myHDsize{
	NSString * childMenuTitle;
	if (!size) {
		childMenuTitle = [NSString stringWithFormat:@"HD Size: Updating..."];
		[ latestHardwareHeaderStatusItem setState:NSMixedState];
		return childMenuTitle;
	}
	else {
		childMenuTitle = [NSString stringWithFormat:@"HD Size: %@",size];
		if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[PASSED]--");
		[ self setMenuItem:latestHardwareHeaderStatusItem
					 state:@"Passed"
		   withDescription:@"HDsize"
				withReason:childMenuTitle
				withMetric:size];
		return childMenuTitle;
	}
}


- (NSString *)myFreeSpacePercent{
	myDiskSize = [[DiskSpaceMonitor alloc] init]; 
	self.myDiskSpaceUsedNumber = [NSNumber numberWithInt:[myDiskSize getDiskPercentage]];
	if (!self.myDiskSpaceUsedNumber) {
		return [NSString stringWithFormat:@"Updating..."];
	}
	else {
		return 	[self.myDiskSpaceUsedNumber stringValue];
	}
}

- (NSString *)myFreeSpaceSize{
	/*if ([[myDiskSize getDiskPercentage] intValue] => 60) {
	 [ self setMenuItem:latestHardwareStatusItem state:YES];
	 }*/
	myDiskSize = [[DiskSpaceMonitor alloc] init]; 
	NSString *diskFreeSizeString = [myDiskSize diskFreeSizeString];
	if (!diskFreeSizeString) {
		return [NSString stringWithFormat:@"Updating..."];
	}
	else {
		return diskFreeSizeString;
	}
}

- (NSString *)myCrashPlanVersion{
	NSString *crashPlanVersion = [ self getCrashPlanVersion];
	if (!crashPlanVersion) {
		return @"Unknown Version";
	}
	else {
		return crashPlanVersion;
	}

}

# pragma mark -- Bread crum checks


- (NSString *)deriveCasperDate{
	NSString *childMenuTitle;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *filePath = [settings objectForKey:@"casperBreadCrum"];
	if(debugEnabled)NSLog(@"Checking for file path: %@",filePath);
	// Check to see if the breadcrum file exists
	if ([fileManager fileExistsAtPath:filePath]){
		NSDate   *modDate      = [[fileManager attributesOfItemAtPath:filePath error:nil] fileModificationDate];
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];		
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		NSLocale *enLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
		
		[dateFormatter setLocale:enLocale];
		// Realtive Date formatting on 10.6 and higher
		if ([dateFormatter respondsToSelector:@selector(setDoesRelativeDateFormatting:)]) {
			[dateFormatter setDoesRelativeDateFormatting:YES];
		}
		
		// Compare the Dates
		NSDate *todaysDate = [NSDate date];
		NSTimeInterval modDiff = [modDate timeIntervalSinceNow];
		NSTimeInterval todaysDiff = [todaysDate timeIntervalSinceNow];
		NSTimeInterval dateDiff = todaysDiff - modDiff;
		
		NSNumber *backupNumber = [NSNumber numberWithDouble:dateDiff];
		// Debug Messages
		if(debugEnabled) NSLog(@"The systems exact backup  time was %@ seconds ago",[backupNumber stringValue] );
		if(debugEnabled) NSLog(@"The systems rounded backup time  was %d seconds ago",[backupNumber intValue] );
		
		// Check the date values
		int securityWarningInt = [[ settings objectForKey:@"securityWarningInt"]intValue] * 86400;
		int securityCriticalInt = [[ settings objectForKey:@"securityCriticalInt"]intValue] * 86400;
		int daysAgo = [backupNumber intValue] / 86400;
		
		NSString *dateString = [dateFormatter stringFromDate:modDate];
		if(debugEnabled)NSLog(@"Casper Relative Date: %@", dateString);
		
		if ([backupNumber intValue] > securityCriticalInt ) {
			childMenuTitle = [NSString stringWithFormat:@"Last Check: %@",dateString];
			if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[CRITICAL]--");
			[self setMenuItem:latestCasperHeaderItem
						state:@"Critical"
			  withDescription:@"Casper"
				   withReason:childMenuTitle
				   withMetric:[[NSNumber numberWithInt:daysAgo] stringValue]];
			[ fileManager release];
			return childMenuTitle;
		}
		if ([backupNumber intValue] > securityWarningInt ) {
			childMenuTitle = [NSString stringWithFormat:@"Last Check: %@",dateString];
			if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[WARNING]--");
			[self setMenuItem:latestCasperHeaderItem
						state:@"Warning"
			  withDescription:@"Casper"
				   withReason:childMenuTitle
				   withMetric:[[NSNumber numberWithInt:daysAgo]stringValue]];
			[ fileManager release];
			return childMenuTitle;
		}
		// Setup out child menu string
		childMenuTitle = [NSString stringWithFormat:@"Last Check: %@",dateString];
		if(debugEnabled) NSLog(@"#####################STATE CHANGE###################--[PASSED]--");
		[self setMenuItem:latestCasperHeaderItem
					state:@"Passed"
		  withDescription:@"Casper"
			   withReason:childMenuTitle
			   withMetric:dateString];
		return childMenuTitle;
	}
	else {
		// If the file is not found:
		if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[OFFLINE]--");
		childMenuTitle = [NSString stringWithFormat:@"Last Check: Unknown"];

		[self setMenuItem:latestCasperHeaderItem
					state:@"Offline"
		  withDescription:@"Casper"
			   withReason:childMenuTitle
			   withMetric:@"?"];
		return childMenuTitle;
	}
}

- (NSString *)deriveSystemVersion{
	unsigned major, minor, bugFix;
	[self getSystemVersionMajor:&major minor:&minor bugFix:&bugFix];
	NSString *myOSVersion = [NSString stringWithFormat:@"OS Version: Mac OS %u.%u.%u", major, minor, bugFix];
	return myOSVersion;
}

- (NSString *)deriveBuildVersion{
	CF_EXPORT CFDictionaryRef _CFCopySystemVersionDictionary(void);
	CF_EXPORT const CFStringRef _kCFSystemVersionBuildVersionKey;
	CFDictionaryRef vers = _CFCopySystemVersionDictionary();
	CFStringRef cfbuildver = CFDictionaryGetValue(vers, _kCFSystemVersionBuildVersionKey);
	NSString *build = (NSString *)cfbuildver;
	return build;
}


// Check the Last Software Update Check Run based on the Preference File
- (NSString *)deriveLastSoftwareUpdateCheck{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *filePath = @"/Library/Preferences/com.apple.SoftwareUpdate.plist";
	NSString *childMenuTitle;
	if ([fileManager fileExistsAtPath:filePath]){
		NSDate   *modDate      = [[fileManager attributesOfItemAtPath:filePath error:nil] fileModificationDate];
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];		
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		NSLocale *enLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
		[dateFormatter setLocale:enLocale];
		// Realtive Date formatting on 10.6 and higher
		if ([dateFormatter respondsToSelector:@selector(setDoesRelativeDateFormatting:)]) {
			[dateFormatter setDoesRelativeDateFormatting:YES];
		}		
		
		NSString *dateString = [dateFormatter stringFromDate:modDate];
		if(debugEnabled)NSLog(@"SoftwareUpdate Relative Date: %@", dateString);
		
		childMenuTitle = [NSString stringWithFormat:@"Last Check: %@",dateString];
		
		if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[PASSED]--");
		[self setMenuItem:latestUpdatesHeaderStatusItem
					state:@"Passed"
		  withDescription:@"UpdatesDate"
			   withReason:childMenuTitle
			   withMetric:dateString];

		return childMenuTitle;
	}
	else {
		if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[CRITICAL]--");
		if(debugEnabled)NSLog(@"ERROR: Preference file: %@ does not exist",filePath);
		childMenuTitle = [NSString stringWithFormat:@"Last Check: Never"];
		[self setMenuItem:latestUpdatesHeaderStatusItem
					state:@"Critical"
		  withDescription:@"UpdatesDate"
			   withReason:childMenuTitle
			   withMetric:@"Missing"];
		return childMenuTitle;
	}
}


- (NSString *)deriveCrashPlanDate{

	// Need to add check for old dates
	NSString *childMenuTitle;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *filePath = [settings objectForKey:@"backupBreadCrum"]; 
	// Check that our bread crum file exists
	if ([fileManager fileExistsAtPath:filePath]){
		NSDate   *modDate      = [[fileManager attributesOfItemAtPath:filePath
																error:nil] fileModificationDate];
		// Fix for Time Zone issue
		NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
		[offsetComponents setHour:-2];
		
		NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

		modDate = [gregorian dateByAddingComponents:offsetComponents toDate:modDate options:0];
		
		// Init our date formatter
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];		
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		NSLocale *enLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
		[dateFormatter setLocale:enLocale];
		// Realtive Date formatting on 10.6 
		if ([dateFormatter respondsToSelector:@selector(setDoesRelativeDateFormatting:)]) {
			[dateFormatter setDoesRelativeDateFormatting:YES];
		}		
		NSString *dateString = [dateFormatter stringFromDate:modDate];
		
		if(debugEnabled)NSLog(@"Crashplan Relative Date: %@", dateString);
	
		
		
		// Compare the Dates
		NSDate *todaysDate = [NSDate date];
		NSTimeInterval modDiff = [modDate timeIntervalSinceNow];
		NSTimeInterval todaysDiff = [todaysDate timeIntervalSinceNow];
		NSTimeInterval dateDiff = todaysDiff - modDiff;
		
		NSNumber *backupNumber = [NSNumber numberWithDouble:dateDiff];
		if(debugEnabled)NSLog(@"The systems exact backup  time was %@ seconds ago",[backupNumber stringValue] );
		if(debugEnabled)NSLog(@"The systems rounded backup time  was %d seconds ago",[backupNumber intValue] );
		// Check the date values
		int backupWarningInt = [[ settings objectForKey:@"backupWarning"]intValue] * 86400;
		int bakupCriticalInt = [[ settings objectForKey:@"bakupCritical"]intValue] * 86400;
		
		int daysAgo = [backupNumber intValue] / 86400;
		
		// For our preferences display
		if (daysAgo <=1) {
			self.backupDateString = [NSString stringWithFormat:@"%@",dateString];
		}
		else {
			self.backupDateString = [NSString stringWithFormat:@"%d Days",daysAgo];
		}

		
		if ([backupNumber intValue] > bakupCriticalInt ) {
			childMenuTitle = [NSString stringWithFormat:@"Last Backup: %@",dateString];
			if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[CRITICAL]--");
			[self setMenuItem:latestBackupHeaderItem
						state:@"Critical"
			  withDescription:@"CrashPlanDate"
				   withReason:childMenuTitle
				   withMetric:[[NSNumber numberWithInt:daysAgo] stringValue]];
			[ fileManager release];
			return childMenuTitle;
		}
		if ([backupNumber intValue] > backupWarningInt ) {
			childMenuTitle = [NSString stringWithFormat:@"Last Backup: %@",dateString];
			if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[WARNING]--");
			[self setMenuItem:latestBackupHeaderItem
						state:@"Warning"
			  withDescription:@"CrashPlanDate"
				   withReason:childMenuTitle
				   withMetric:[[NSNumber numberWithInt:daysAgo]stringValue]];
			[ fileManager release];
			return childMenuTitle;
		}
		// Set up our return value
		childMenuTitle = [NSString stringWithFormat:@"Last Backup: %@",dateString];
		// Turn our header menu green
		if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[PASSED]--");
		[self setMenuItem:latestBackupHeaderItem
					state:@"Passed"
		  withDescription:@"CrashPlanDate"
			   withReason:childMenuTitle
			   withMetric:dateString];
		[ fileManager release];
		return childMenuTitle;
	}
	else {
		if(debugEnabled)NSLog(@"ERROR: File %@ does not exist",filePath);
		// Set up our return value
		childMenuTitle = [NSString stringWithFormat:@"Last Backup: Unknown"];
		// Turn our header menu red
		if(debugEnabled) NSLog(@"#####################--STATE CHANGE--####################--[Offline]--");
		[self setMenuItem:latestBackupHeaderItem
					state:@"Offline"
		  withDescription:@"CrashPlanDate" 
			   withReason:childMenuTitle
			   withMetric:@"?"];
		// Return the menu String
		[ fileManager release];
		return [NSString stringWithFormat:@"Last Backup: Unknown"];
	}
}

- (NSString *)deriveBackupPercentage{
	NSError *error;
	NSString *childMenuTitle;
	NSString *filePath = [settings objectForKey:@"backupPercentageBreadCrum"];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if ([fileManager fileExistsAtPath:filePath]){
		NSString *backupPercentage = [NSString stringWithContentsOfFile:filePath
															   encoding:NSUTF8StringEncoding
																  error:&error];
		// Remove New Line Characters
		backupPercentage = [backupPercentage stringByReplacingOccurrencesOfString:@"\n"
																	   withString:@""];
		if (backupPercentage == nil)
		{
			childMenuTitle = [NSString stringWithFormat:@"Completed: Unknown"];
			return childMenuTitle;
			if(debugEnabled)NSLog (@"ERROR: %@", error);
		}
		else
		{
			childMenuTitle = [NSString stringWithFormat:@"Completed: %d%%",[backupPercentage intValue]];
			if ([backupPercentage intValue] == 0) {
				[ self setMenuItem:latestBackupHeaderItem
							 state:@"Offline"
				   withDescription:@"CrashPlanPercentage" 
						withReason:childMenuTitle
						withMetric:backupPercentage];
				return childMenuTitle;
			}
			else {
				[ self setMenuItem:latestBackupHeaderItem
							 state:@"Passed"
				   withDescription:@"CrashPlanPercentage" 
						withReason:childMenuTitle
						withMetric:backupPercentage];
				return childMenuTitle;
			}


		}
	}
	
	return [NSString stringWithFormat:@"Completed: Unknown"];
}


- (NSString *)deriveCrashPlanUser
{	
	NSError *error;
	NSString *filePath = [settings objectForKey:@"backupUserBreadCrum"];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if ([fileManager fileExistsAtPath:filePath]){
		NSString *fileSystemtype = [NSString stringWithContentsOfFile:filePath
															 encoding:NSUTF8StringEncoding
																error:&error];
		if (fileSystemtype == nil)
		{
			return [NSString stringWithFormat:@"CrashPlan User: Unknown"];
			if(debugEnabled)NSLog (@"ERROR:%@", error);
		}
		else
		{
			return [NSString stringWithFormat:@"CrashPlan User: %@",fileSystemtype];
		}
	}
	
	return [NSString stringWithFormat:@"CrashPlan User: Unknown"];
}


- (NSString *)deriveCrashPlanGUID{
	NSError *error;
	NSString *filePath = [settings objectForKey:@"backupGUIDBreadCrum"];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if ([fileManager fileExistsAtPath:filePath]){
		NSString *fileSystemtype = [NSString stringWithContentsOfFile:filePath
															 encoding:NSUTF8StringEncoding
																error:&error];
		if (fileSystemtype == nil)
		{
			return [NSString stringWithFormat:@"GUID: Unknown"];
			if(debugEnabled)NSLog (@"ERROR:%@", error);
		}
		else
		{
			return [NSString stringWithFormat:@"GUID: %@",fileSystemtype];
		}
	}
	
	return [NSString stringWithFormat:@"System Type: Unknown"];
}

- (BOOL)checkOverride:(NSString *)filePath
{
	NSError *error;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if ([fileManager fileExistsAtPath:filePath]){
		return YES;
	}
	else {
		return NO;
	}

}


- (NSString *)deriveSystemtype{
	NSError *error;
	NSString *filePath = [settings objectForKey:@"systemTypeBreadCrum"];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if ([fileManager fileExistsAtPath:filePath]){
		NSString *fileSystemtype = [NSString stringWithContentsOfFile:filePath
											   encoding:NSUTF8StringEncoding
												  error:&error];
		// Remove Line Endings
		fileSystemtype = [fileSystemtype stringByReplacingOccurrencesOfString:@"\n"
																   withString:@""];
		if (fileSystemtype == nil)
		{
			return [NSString stringWithFormat:@"Unknown"];
			if(debugEnabled)NSLog (@"ERROR:%@", error);
		}
		else
		{
			return [NSString stringWithFormat:@"%@",fileSystemtype];
		}
	}

	return [NSString stringWithFormat:@"Unknown"];
}


- (NSString *)deriveImageVersion
{
	NSError *error;
	NSString *filePath = [settings objectForKey:@"systemImageVersion"];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if ([fileManager fileExistsAtPath:filePath]){
		// Remove Line Endings
		NSString *fileSystemtype = [NSString stringWithContentsOfFile:filePath
															 encoding:NSUTF8StringEncoding
																error:&error];
		fileSystemtype = [fileSystemtype stringByReplacingOccurrencesOfString:@"\n"
																	   withString:@""];
		if (fileSystemtype == nil)
		{
			return [NSString stringWithFormat:@"Image Version: Unknown"];
			if(debugEnabled)NSLog (@"ERROR:%@", error);
		}
		else
		{
			return [NSString stringWithFormat:@"Image Version: %@",fileSystemtype];
		}
	}
	
	return [NSString stringWithFormat:@"Image Version: Unknown"];
}


- (void)getSystemVersionMajor:(unsigned *)major
                        minor:(unsigned *)minor
                       bugFix:(unsigned *)bugFix;
{
    OSErr err;
    SInt32 systemVersion, versionMajor, versionMinor, versionBugFix;
    if ((err = Gestalt(gestaltSystemVersion, &systemVersion)) != noErr) goto fail;
    if (systemVersion < 0x1040)
    {
        if (major) *major = ((systemVersion & 0xF000) >> 12) * 10 +
            ((systemVersion & 0x0F00) >> 8);
        if (minor) *minor = (systemVersion & 0x00F0) >> 4;
        if (bugFix) *bugFix = (systemVersion & 0x000F);
    }
    else
    {
        if ((err = Gestalt(gestaltSystemVersionMajor, &versionMajor)) != noErr) goto fail;
        if ((err = Gestalt(gestaltSystemVersionMinor, &versionMinor)) != noErr) goto fail;
        if ((err = Gestalt(gestaltSystemVersionBugFix, &versionBugFix)) != noErr) goto fail;
        if (major) *major = versionMajor;
        if (minor) *minor = versionMinor;
        if (bugFix) *bugFix = versionBugFix;
    }
    
    return;
    
fail:
    if(debugEnabled)NSLog(@"ERROR:Unable to obtain system version: %ld", (long)err);
    if (major) *major = 10;
    if (minor) *minor = 0;
    if (bugFix) *bugFix = 0;
}

@end
