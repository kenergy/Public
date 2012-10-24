//
//  GlobalStatus.h
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 8/17/11.
//  Copyright 2011 Genentech. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GlobalStatus : NSWindowController {
	NSMutableArray * globalStatusArray;
	BOOL debugEnabled;
}

- (void)setGlobalStatusArray:(NSMutableArray *)myArray;
- (NSMutableArray *)getGlobalStatusArray;

@property (nonatomic,retain) NSMutableArray* globalStatusArray;


@end
