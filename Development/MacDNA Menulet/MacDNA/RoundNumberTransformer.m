//
//  RoundNumberTransformer.m
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokok on 2/13/12.
//  Copyright 2012 Genentech. All rights reserved.
//

#import "RoundNumberTransformer.h"


@implementation RoundNumberTransformer

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
	
	float numberOutputValue = round(2.0f * numberInputValue) / 2.0f;
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	[formatter setMaximumFractionDigits:0];
	[formatter setRoundingMode: NSNumberFormatterRoundDown];
	
	NSString *numberString = [formatter stringFromNumber:[NSNumber numberWithFloat:numberOutputValue]];
	[formatter release];
    return numberString;
}
@end
