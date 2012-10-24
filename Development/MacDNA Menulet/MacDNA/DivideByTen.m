//
//  DivideByTen.m
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 2/13/12.
//  Copyright 2012 Genentech. All rights reserved.
//

#import "DivideByTen.h"


@implementation DivideByTen


-(Class)transformedValueClass
{
    return [NSNumber class];
}


-(BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    float numberInputValue;
	
    if (value == nil) return nil;
	
    // Attempt to get a reasonable value from the
    // value object.
    if ([value respondsToSelector: @selector(floatValue)]) {
		// handles NSString and NSNumber
        numberInputValue = [value floatValue];
    } else {
        [NSException raise: NSInternalInconsistencyException
                    format: @"Value (%@) does not respond to -floatValue.",
		 [value class]];
    }
	
	float numberOutputValue = round(2.0f * numberInputValue) / 10.0f;
    return [NSNumber numberWithFloat:numberOutputValue];
}


@end
