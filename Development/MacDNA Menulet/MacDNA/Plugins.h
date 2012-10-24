//
//  Plugins.h
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 2/13/12.
//  Copyright 2012 Genentech. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Constants.h"


@interface Plugins : NSObject {
	// UI Elements
	IBOutlet NSMenu *statusMenu;
	IBOutlet NSMenuItem *latestUpdatesHeaderStatusItem;

	
	NSBundle *mainBundle;
	NSDictionary *settings;
	NSMutableArray *configScriptArguments;
	NSMutableArray *menuItems;

	BOOL scriptIsRunning;
	BOOL debugEnabled;
}
//void
- (void)readInSettings ;
- (void)waitForLastScriptToFinish;
- (void)addConfigScriptArguments;
- (void)runPluginScripts:(id)sender;
- (void)setFailedEndStatusFromScript:(NSDictionary *)scriptDictionary
						  withError:(NSString *)errorMessage
					   withExitCode:(int)exitStatus
							forMenu:(NSInteger)menuTag
						  controller:(id)sender;

-(void)setStatus:(NSString *)scriptTitle
	 withMessage:(NSString *)scriptDescription 
		 forMenu:(NSInteger)menuTag
	  controller:(id)sender
	 asAlternate:(BOOL)alternate;

-(void)setEndStatusFromScript:(NSDictionary *)scriptDictionary
				   withOutPut:scriptOutput
					  forMenu:(NSInteger)menuTag
				   controller:(id)sender;
// BOOL
- (BOOL)runScript:(NSDictionary *)scriptDictionary
	withArguments:(NSMutableArray *)scriptArguments
		  forMenu:(NSInteger)menuTag
	   controller:(id)sender;

// IBActions
- (IBAction)updatePluginMenus:(id)sender;
@end
