//
//  RepairController.h
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 9/27/11.
//  Copyright 2011 Genentech. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Constants.h"

@class PleaseWaitController;

@class RunAppleScript;

@interface RepairController : NSObject {
	
	// Our Custom Classes
	PleaseWaitController *pleaseWaitWindow;
	RunAppleScript *attemptToRepair;

}
-(void)startNewRepair:(NSNotification *)notification;
-(void)startPleaseWait:(NSNotification *)notification;

@end
