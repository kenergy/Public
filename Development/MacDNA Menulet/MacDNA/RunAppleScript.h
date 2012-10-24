//
//  RunAppleScript.h
//  GNE Mac Status
//
//  Created by Zack Smith on 7/20/11.
//  Copyright 2011 318. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Constants.h"


@interface RunAppleScript : NSObject {
	// Reference to this bundle
	NSBundle *mainBundle;
	IBOutlet NSWindow *window;

}

- (void)runAppleScript;
- (void)runAppleScriptTask;
- (void)displayDialog:(NSString *)message;
@end
