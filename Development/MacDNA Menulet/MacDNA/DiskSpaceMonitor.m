//
//  DiskSpaceMonitor.m
//  Support Tool
//
//  Created by Zack Smith and Arek Sokol on 2/5/10.
//  Copyright 2010 Genentech. All rights reserved.
//
// Updated to show 1000 per snow leopard standards

#import "DiskSpaceMonitor.h"


@implementation DiskSpaceMonitor

- (id)init
{	
	[super init];
	[self updateDiskSpaceInfo];
	return self;
}

-(void)dealloc 
{ 
	[super dealloc]; 
} 

- (NSNumber *)updateDiskSpaceInfo
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSDictionary *diskFileSystemAttributes = 
	[fileManager fileSystemAttributesAtPath:@"/"];
	// I need to update the above
	
	diskSize =[diskFileSystemAttributes objectForKey:NSFileSystemSize];
	diskFreeSize =[diskFileSystemAttributes objectForKey:NSFileSystemFreeSize];
	//NSLog(@"My Raw Disk Space Free Size is %@",diskFreeSize);
	percentOfUsedSpace = [self percentOfDiskSpaceUsedForFileSize];
	[fileManager release];
	return percentOfUsedSpace;
}

- (NSString *)getHumanReadableFileSize:(NSNumber *)filesize
{
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setFormat:@"0.##"];
	
	static NSString *suffix[] = { @"B", @"KB", @"MB", @"GB", @"TB", @"PB", @"EB" };
	int i, c = 7;
	double size = [filesize floatValue];
	
	for (i = 0; i < c && size >= 1000; i++)
	{
		size = size / 1000;
	}
	size = round(size);
	NSString *formattedNumber = [numberFormatter stringFromNumber:[NSNumber numberWithDouble:size]];
	return [NSString stringWithFormat:@"%@ %@",formattedNumber, suffix[i]];
}

- (NSNumber *)percentOfDiskSpaceUsedForFileSize
{
	double x = 100.0 - ([diskFreeSize doubleValue] / [diskSize doubleValue] * 100.0);
	//NSLog( @"%f", x );
	x = round(x);
	return [NSNumber numberWithDouble:x];
}

- (int)getDiskPercentage
{
	int diskPercentage = 100.0 - ([diskFreeSize doubleValue] / [diskSize doubleValue] * 100.0);
	//NSLog( @"%f", x );
	diskPercentage = round(diskPercentage);
	return diskPercentage;
}



- (BOOL )warnIfPercentIsOver:(int)warnLevel
{
	int percentOfUsedSpaceInt = [[self percentOfUsedSpace] intValue];
	if (percentOfUsedSpaceInt > warnLevel) {
		return YES;
	}
	return NO;
}


- (NSString *)percentOfUsedSpaceString {
    return [[[self percentOfUsedSpace] stringValue] stringByAppendingString:@"%"];
}

- (NSString *)diskSizeString {
	return [self getHumanReadableFileSize:diskSize];
}

- (NSString *)diskFreeSizeString {
	[self updateDiskSpaceInfo];
    return [[[self getHumanReadableFileSize:diskFreeSize] retain] autorelease];
}

- (NSNumber *)percentOfUsedSpace {
	[self updateDiskSpaceInfo];
    return [[percentOfUsedSpace retain] autorelease];
}


@end
