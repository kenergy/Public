//
//  StatusIconCell.h
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 8/19/11.
//  Copyright 2011 Genentech. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Constants.h"

@interface StatusIconCell : NSTextFieldCell {
	NSObject* delegate;

	// Standard iVars
	NSBundle *mainBundle;
	NSDictionary *settings;
	BOOL debugEnabled;

	
}

- (void)readInSettings ;
- (void) setDataDelegate: (NSObject*) aDelegate;


@end
