//
//  GNE_Mac_Status_AppDelegate.h
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 7/5/11.
//  Copyright Genentech 2011 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DiskSpaceMonitor.h"
#import "Constants.h"
#include <CoreServices/CoreServices.h>
// Disk Space Monitor is my Object
// Core Services is here because we use FSEvents

@class DiskSpaceMonitor;
@class SummaryWindowController;
@class GlobalStatus;
@class Plugins;
@class Recon;
@class RepairController;

// NSValuetransformers
@class RoundNumberTransformer;
@class RoundNumberTransformerNeg;
@class DivideByTen;
@class DivideByTenNeg;

@interface GNE_Mac_Status_AppDelegate : NSObject 
{
	/*---------------------------------------------------*/
	// UI Elements
	IBOutlet NSMenu *statusMenu;
	IBOutlet NSMenuItem *deferMenuItem;

	IBOutlet NSMenuItem *systemTypeItem;
	
	IBOutlet NSMenu *supportLinkItem;

	IBOutlet NSMenuItem *systemTypeItemAlt;
	
	IBOutlet NSPanel *preferencesPanel;


	/*---------------------------------------------------*/
	//Summary Menu
	IBOutlet NSMenuItem *summaryMenuItem;
	/*---------------------------------------------------*/
	IBOutlet NSMenuItem *latestBackupSeperatorItem;
	//Backup Status
	IBOutlet NSMenuItem *latestBackupHeaderItem;
	IBOutlet NSMenuItem *latestBackupStatusItem;
	IBOutlet NSMenuItem *latestBackupStatusItemAlt;
	IBOutlet NSMenuItem *latestBackupPercentageStatusItem;
	IBOutlet NSMenuItem *latestBackupPercentageStatusItemAlt;

	/*---------------------------------------------------*/
	// Security Status
	IBOutlet NSMenuItem *latestCasperHeaderItem;
	IBOutlet NSMenuItem *latestCasperStatusItem;
	IBOutlet NSMenuItem *latestCasperStatusItemAlt;
	/*---------------------------------------------------*/
	// Hardware Status
	IBOutlet NSMenuItem *latestHardwareHeaderStatusItem;
	IBOutlet NSMenuItem *latestHDSmartStatusItem;
	IBOutlet NSMenuItem *latestHDSmartStatusItemAlt;

	IBOutlet NSMenuItem *latestHDUsageStatusItem;
	IBOutlet NSMenuItem *latestHDUsageStatusItemAlt;

	IBOutlet NSMenuItem *latestBatteryHealthStatusItem;
	IBOutlet NSMenuItem *latestBatteryHealthStatusItemAlt;
	
	IBOutlet NSMenuItem *subHDUsageToggleItem;
	/*---------------------------------------------------*/
	// Updates Status
	IBOutlet NSMenuItem *latestUpdatesHeaderStatusItem;
	IBOutlet NSMenuItem *latestUpdatesStatusItem;
	IBOutlet NSMenuItem *latestUpdatesStatusItemAlt;
	IBOutlet NSMenuItem *latestOSVersionStatusItem;
	/*---------------------------------------------------*/
	IBOutlet NSMenuItem *pluginsSeperatorItem;
	// Plugin Menus
	IBOutlet NSMenu *refreshMenu;
	IBOutlet NSMenuItem *pluginsPlaceHolder;
	/*---------------------------------------------------*/
	// Repair Menu
	IBOutlet NSMenuItem *repairStatusItem;
	/*---------------------------------------------------*/
	
	NSMenuItem *supportLinkArrayItem;

    NSWindow *window;
	NSStatusItem *statusItem;
	
	// Our Timers
	NSTimer *iconRedTimer;
	NSTimer *iconYellowTimer;
	NSTimer *iconBlackTimer;
	NSTimer *globalTimer;
	NSTimer *batteryPoolTimer;
	NSTimer *swupPoolTimer;
	NSTimer *backupPoolTimer;
	NSTimer *casperPoolTimer;
	NSTimer *smartPoolTimer;

	// Disk Space Calculation
	IBOutlet NSLevelIndicator *myDiskSizeLevel;
	NSNumber *myDiskSpaceUsedNumber;
	DiskSpaceMonitor *myDiskSize;
	
	IBOutlet NSMenuItem *attemptToRepairMenu;
	// Handle our nstasks
	NSTask       *_task;
	NSFileHandle *_fileHandle;
	
	// System Profiler Items
	NSString * sppower_battery_health;
	NSString * sppower_battery_cycle_count;
	NSString * smart_status;
	NSString * size;
	
	NSString *systemtype;
	NSString *lastText;
	NSMutableArray *lastOffender;
	NSArray *supportLinks;
	NSString *ipv4Address;
	
	BOOL warnHDUsage;
	BOOL debugEnabled;
	BOOL scriptIsRunning;
	BOOL refreshingComplete;
	BOOL softwareUpdateRunning;
	BOOL checkingGlobalStatus;
	// ZS Added Defer Support
	// Pref Key
	BOOL deferEnabled;
	// Global Status
	BOOL deferedStaus;
	
	NSTimer *deferTimer;
	// Reference to this bundle
	NSBundle *mainBundle;
	NSMutableArray *configScriptArguments;
	NSMutableArray *startUpRoutineArguments;
	
	// Updated for Preference Panel
	NSUserDefaults *settings;
	
	NSDictionary *getSoftwareUpdates;
	
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
	
	// Our Custom classes
	SummaryWindowController *summaryWindow;
	GlobalStatus  *globalStatusController;
	Plugins *plugins;
	Recon	*recon;
	RepairController *repairController;
	// NSValueTransformers
	RoundNumberTransformer *roundNumberTransformer;
	RoundNumberTransformerNeg *roundNumberTransformerNeg;
    DivideByTen *divideByTenTransformer;
	DivideByTenNeg *divideByTenNegTransformer;

	NSString *backupDateString;
	
	FSEventStreamRef _stream;
    FSEventStreamContext *_context;
	
	// Used for Keeping track of the menu for plugins
	NSInteger currentMenuIndex;
	NSInteger updateMenuIndex; 
	NSString *bundleVersionNumber;
	
	// Our Primary Array
	NSMutableArray *globalStatusArray;
}
@property (nonatomic, retain) IBOutlet NSWindow *window;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@property (retain) NSNumber* myDiskSpaceUsedNumber;
@property (retain) NSString* backupDateString;
@property (retain) NSString* bundleVersionNumber;

// Interface Builder Actions
- (IBAction)saveAction:sender;
- (IBAction)backupStatusButton:(id)sender;
- (IBAction)securityStatusButton:(id)sender;
- (IBAction)hardwareStatusButton:(id)sender;
- (IBAction)updatesStatusButton:(id)sender;
- (IBAction)updatePluginsButton:(id)sender;
- (IBAction)attemptToFixButton:(id)sender;
- (IBAction)launchBackupTool:(id)sender;
- (IBAction)launchSWUpdateTool:(id)sender;
- (IBAction)summaryButton:(id)sender;
- (IBAction)launchSystemProfiler:(id)sender;
- (IBAction)launchDirectoryServiceTool:(id)sender;
- (IBAction)launchPasswordTool:(id)sender;
- (IBAction)deferAlertsMenuSelected:(id)sender;
- (IBAction)showPreferencesPanel:(id)sender;
- (IBAction)savePreferencesButton:(id)sender;

// Strings Returned
- (NSString *)getComputerName;
- (NSString *)getBatteryHealth;
- (NSString *)deriveBackupPercentage;
- (NSString *)deriveSystemtype;
- (NSString *)deriveCasperDate;
- (NSString *)deriveLastSoftwareUpdateCheck;
- (NSString *)deriveCrashPlanDate;
- (NSString *)deriveSystemVersion;
- (NSString *)deriveBuildVersion;
- (NSString *)deriveCrashPlanUser;
- (NSString *)deriveImageVersion;
- (NSString *)getCrashPlanVersion;
- (NSString *)myCrashPlanVersion;
- (NSString *)mySmartStatus;
- (NSString *)myHDsize;
- (NSString *)myFreeSpacePercent;
- (NSString *)myFreeSpaceSize;
- (NSMutableArray *)getGlobalStatusArray;


// void returns
- (void)updateSystemType;
- (void)updateSoftwareUpdatesMenu;
- (void)runTaskSystemProfiler;
- (void)runSoftwareUpdateThread;
- (void)updateBatteryInfo;
- (void)updateCasperMenu;
- (void)updateDiskMenu;
- (void)createStatusItem;
- (void)stopFlashing;
- (void)flashBlack;
- (void)flashRed;
- (void)setIconBlack;
- (void)setIconRed;
- (void)pollBattery;
- (void)updateCrashplan;
- (void)updateSmartMenu;
- (void)updateAllMenus;
- (void)addSupportLinksMenuItems;
-(IBAction)openSupportLink:(id)sender;
//- (NSString *)getCurrentIPAddress;
- (void)setWarningIcon:(NSMenuItem *)myMenu;
- (void)displayMissingAlert;

// Our Main Static Menu Handler
- (void)setMenuItem:(NSMenuItem *)myMenuItem
			  state:(NSString * )myState
	withDescription:(NSString *)myDescription 
		 withReason:(NSString *)reason
		 withMetric:(NSString *)metric;

- (void)parseSystemProfiler:(NSArray *)plist;
- (void)parseBatteryInformation:(NSDictionary *)rootObject;
- (void)parseSmartInformation:(NSDictionary *)rootObject;
- (void)taskDone:(NSString *)text;
- (void)startFlashing:(NSString *)color;

// Init Methods
- (void)watchControlDirectory;
- (BOOL)runSoftwareUpdateTask;
- (BOOL)isSharedSystem;
- (void)readInSettings;
- (void)initScripts;

// NSTimer methods
- (void)pollGlobalStatus;
- (void)pollSoftwareUpdates;
- (void)pollCrashPlan;
- (void)pollCasper;
- (void)pollSmartStatus;
- (void)waitForLastScriptToFinish;
- (void)setGlobalStatus;
- (NSString *)deriveCrashPlanGUID;

// Our Main Method for interacting with child and Parent
- (void)setMyStatus:(NSString *)myStatus
	setDescription:(NSString *)myDescription
		   setMenu:(NSMenuItem *)myMenu
		withReason:(NSString *)reason
		withMetric:(NSString *)metric;
// Complex Methods - via Mac Setup

- (void)setScriptIsRunning:(NSDictionary *)scriptDictionary 
				  forMenu:(NSMenuItem *)myMenuItem;

- (void)setFailedEndStatusFromScript:(NSDictionary *)scriptDictionary
						  withError:(NSString *)errorMessage
					   withExitCode:(int)exitStatus 
							forMenu:(NSMenuItem *)myMenuItem
						  forHeader:(NSMenuItem *)myMenuItemHeader;

-(void)setEndStatusFromScript:(NSDictionary *)scriptDictionary
					  forMenu:(NSMenuItem *)myMenuItem
					forHeader:(NSMenuItem *)myMenuItemHeader;


- (void)openPageInSafari:(NSString *)url;


- (void)setStatus:(NSString *)scriptTitle
	 withMessage:(NSString *)scriptDescription 
		 forMenu:(NSMenuItem *)myMenuItem;

- (int)runScript:(NSDictionary *)scriptDictionary
   withArguments:(NSMutableArray *)scriptArguments;

- (void)setStatusFromScript:(NSDictionary *)scriptDictionary
				   forMenu:(NSMenuItem *)myMenuItem;

- (void)getSystemVersionMajor:(unsigned *)major
                        minor:(unsigned *)minor
                       bugFix:(unsigned *)bugFix;
- (void)updateRepairMenu:(NSString *)menuTitle
			  isEnabled:(BOOL)enabled;

- (IBAction)toggleDiskUsage:(id)sender;
- (BOOL)evaluateBoolMenu:(NSMenuItem *)evalButton;

// Plugin Methods
- (void)setPluginHeaderGreen:(NSInteger)menuTag;
- (void)setPluginHeaderYellow:(NSInteger)menuTag;
- (void)setPluginHeaderRed:(NSInteger)menuTag;
- (void)setPluginHeaderGrey:(NSInteger)menuTag;
- (NSInteger)addPluginMenuHeader:(NSString *)myTitle;
- (NSInteger)addPluginMenuChild:(NSString *)myTitle
				   withToolTip:(NSString *)myToolTip
				   asAlternate:(BOOL)alternate;
- (void) pluginsHaveLoaded:(NSNotification *) notification;
- (BOOL)checkOverride:(NSString *)filePath;
// Our Notification System Reciever
- (void) receiveUpdateRequest:(NSNotification *) notification;
- (void)evaluateSoftwareUpdates:(NSString *)numberOfUpdates;

- (IBAction)checkIfDeferAlertsEnabled:(id)sender;
- (IBAction)updateBackupDateButton:(id)sender;
- (IBAction)resetToDefaultsButton:(id)sender;
@end
