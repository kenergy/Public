//
//  URLHandlerCommand.m
//  Package Assistant
//
//  Created by Zack Smith and Arek Sokol on 2/13/12.
//  Copyright 2012 Genentech. All rights reserved.
//

#import "URLHandlerCommand.h"
#import "PleaseWaitController.h"
#import "Constants.h"


@implementation URLHandlerCommand


- (id)performDefaultImplementation {
 	NSString *urlString = [self directParameter];

 
	// NSLog(@"Recieived unkown URL: %@",urlString);
	return self;
}



@end