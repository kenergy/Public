//
//  StatusIconCell.m
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 8/19/11.
//  Copyright 2011 Genentech. All rights reserved.
//

#import "StatusIconCell.h"
#import "Constants.h"


@implementation StatusIconCell

- (id)init
{	
	[super init];
	[self readInSettings];
	return self;
}

- (void) setDataDelegate: (NSObject*) aDelegate {
	[aDelegate retain];	
	[delegate autorelease];
	delegate = aDelegate;	
}

- (id) dataDelegate {
	if (delegate) return delegate;
	return self; // in case there is no delegate we try to resolve values by using key paths
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[self setTextColor:[NSColor blackColor]];
		
	NSDictionary* data = [self objectValue];
	if (!data) {
		return;
		/*NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
		[ mutableDictionary setValue:@"Unknown Title" forKey:@"summaryTitle"];
		[ mutableDictionary setValue:@"Unknown Reason" forKey:@"summaryReason"];
		[ mutableDictionary setValue:@"generic_sm" forKey:@"summaryImage"];
		data = [[NSDictionary alloc] initWithDictionary:mutableDictionary];*/
	}

	BOOL elementDisabled    = NO;	

	
	NSColor* primaryColor   = [self isHighlighted] ? [NSColor alternateSelectedControlTextColor] : (elementDisabled? [NSColor disabledControlTextColor] : [NSColor textColor]);

	NSString* primaryText;
	if ([data objectForKey:@"summaryTitle"] !=nil) {
		primaryText = [data objectForKey:@"summaryTitle"];
	}
	else {
		primaryText   = @"Unknown";
	}
	
	NSDictionary* primaryTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys: primaryColor, NSForegroundColorAttributeName,
										   [NSFont systemFontOfSize:13], NSFontAttributeName, nil];	
	[primaryText drawAtPoint:NSMakePoint(cellFrame.origin.x+cellFrame.size.height+10, cellFrame.origin.y) withAttributes:primaryTextAttributes];
	
	NSColor* secondaryColor = [self isHighlighted] ? [NSColor alternateSelectedControlTextColor] : [NSColor disabledControlTextColor];
	NSString* secondaryText;
	if ([data objectForKey:@"summaryReason"] !=nil) {
		secondaryText = [data objectForKey:@"summaryReason"];
	}
	else {
		secondaryText   = @"Unknown";
	}


	
	NSDictionary* secondaryTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys: secondaryColor, NSForegroundColorAttributeName,
											 [NSFont systemFontOfSize:10], NSFontAttributeName, nil];	
	[secondaryText drawAtPoint:NSMakePoint(cellFrame.origin.x+cellFrame.size.height+10, cellFrame.origin.y+cellFrame.size.height/2) 
				withAttributes:secondaryTextAttributes];
	
	
	[[NSGraphicsContext currentContext] saveGraphicsState];
	float yOffset = cellFrame.origin.y;
	if ([controlView isFlipped]) {
		NSAffineTransform* xform = [NSAffineTransform transform];
		[xform translateXBy:0.0 yBy: cellFrame.size.height];
		[xform scaleXBy:1.0 yBy:-1.0];
		[xform concat];		
		yOffset = 0-cellFrame.origin.y;
	}
	
	// Grab the Icon at the specified Path
	NSString* iconPath = [data objectForKey:@"summaryImage"];

	NSImage *icon = [[NSImage alloc] initWithContentsOfFile: [ mainBundle pathForResource:iconPath ofType:@"png"]];
	
	NSImageInterpolation interpolation = [[NSGraphicsContext currentContext] imageInterpolation];
	[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];	
	
	[icon drawInRect:NSMakeRect(cellFrame.origin.x+5,yOffset+3,cellFrame.size.height-6, cellFrame.size.height-6)
			fromRect:NSMakeRect(0,0,[icon size].width, [icon size].height)
		   operation:NSCompositeSourceOver
			fraction:1.0];
	
	[[NSGraphicsContext currentContext] setImageInterpolation: interpolation];
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (void)readInSettings 
{ 	
	mainBundle = [NSBundle bundleForClass:[self class]];
	NSString *settingsPath = [mainBundle pathForResource:SettingsFileResourceID ofType:@"plist"];
	settings = [[NSDictionary alloc] initWithContentsOfFile:settingsPath];
}



@end
