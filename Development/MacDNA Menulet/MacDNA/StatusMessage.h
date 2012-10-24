//
//  StatusMessage.h
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 7/19/11.
//  Copyright 2011 Genentech. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Constants.h"


@interface StatusMessage : NSWindowController {
	NSFileManager *myFileManager;
	NSTimer *updateProgressBarTime;
	NSString *myInstallProgressFile;
	NSString *myInstallProgressTxt;
	NSString *myInstallPhaseTxt;
	NSString *InstallProgressTxt;
	IBOutlet NSProgressIndicator *userProgressBar;
	IBOutlet NSWindow *window;
	IBOutlet NSTextField *currentStatus;
	IBOutlet NSTextField *currentPhase;
	
	NSBundle *mainBundle;
	NSDictionary *settings;
}
- (void)readInSettings ;
- (void) startUserProgressIndicator;
- (void) stopUserProgressIndicator;
- (void) sleepNow;
- (void) makeWindowFullScreen;
- (void) readInstallProgress;
- (void) updateProgressBar;
- (void) updateStatusTxt;
- (void) updatePhaseTxt;
- (void)removePreviousFiles;
- (void)repairStopped;

@end
