//
//  Recon.h
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 8/23/11.
//  Copyright 2011 Genentech. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Constants.h"


@interface Recon : NSObject {
	
	// Handle our nstasks
	NSTask       *_task;
	NSFileHandle *_fileHandle;
	
	// Our task sanity boolean
	BOOL reconIsRunning;
	
	// Standard iVars
	NSBundle *mainBundle;
	NSDictionary *settings;
	
	BOOL debugEnabled;


}
- (void)readInSettings ;
- (void)runCasperRecon;
- (void)reconRequested:(NSNotification*)aNotification;

@end
