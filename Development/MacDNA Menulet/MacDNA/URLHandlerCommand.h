//
//  URLHandlerCommand.h
//  Package Assistant
//
//  Created by Zack Smith and Arek Sokol on 2/13/12.
//  Copyright 2012 Genentech. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "Constants.h"

@class PleaseWaitController;

@interface URLHandlerCommand : NSScriptCommand {
	NSArray *urlData;
	
	// Our Custom Classes
	PleaseWaitController *pleaseWaitWindow;
}


@end
