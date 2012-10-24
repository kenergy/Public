//
//  GlobalStatus.m
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 8/17/11.
//  Copyright 2011 Genentech. All rights reserved.
//

#import "GlobalStatus.h"


@implementation GlobalStatus

@synthesize globalStatusArray;

-(id)init
{
    [ super init];	
	// Init our ivar
	if (!globalStatusArray) {
		globalStatusArray = [[NSMutableArray alloc] init];
		if(debugEnabled) NSLog(@"DEBUG: A New global Status array Was Created");
	}
    return self;
}

-(void)setGlobalStatusArray:(NSMutableArray *)myArray;
{
	if ([myArray count] >0) {
		if(debugEnabled)NSLog(@"DEBUG: Global Status Object was passed new array:%@",myArray);
		globalStatusArray = myArray;
	}
	else {
		NSLog(@"ERROR: Global Status Object was Passed an Empty Array");
	}
	[ globalStatusArray retain];
}

-(NSMutableArray *)getGlobalStatusArray;
{
	if(debugEnabled)NSLog(@"DEBUG: Returing the Global Status Array:%@",globalStatusArray);
	return globalStatusArray;
}

@end
