//
//  PleaseWaitController.h
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 7/19/11.
//  Copyright 2011 Genentech. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Constants.h"

@interface PleaseWaitController : NSWindowController {
}


- (void)repairStarted:(NSNotification *)notification;
- (void) repairComplete:(NSNotification *) notification;

@end
