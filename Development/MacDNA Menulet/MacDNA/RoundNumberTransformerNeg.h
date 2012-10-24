//
//  RoundNumberTransformer.h
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 2/13/12.
//  Copyright 2012 Genentech. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RoundNumberTransformerNeg : NSValueTransformer {
	
}

-(Class)transformedValueClass;
-(BOOL)allowsReverseTransformation;
- (id)transformedValue:(id)value;

@end
