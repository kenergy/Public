//
//  DiskSpaceMonitor.h
//  Support Tool
//
//  Created by Zack Smith and Arek Sokol on 2/5/10.
//  Copyright 2010 Genentech. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DiskSpaceMonitor : NSObject {
	NSNumber *diskSize;
	NSNumber *diskFreeSize;
	NSNumber *percentOfUsedSpace;
}

- (void)dealloc;
- (NSNumber *)updateDiskSpaceInfo;
- (NSString *)getHumanReadableFileSize:(NSNumber *)filesize;
- (NSNumber *)percentOfDiskSpaceUsedForFileSize;
- (BOOL )warnIfPercentIsOver:(int)warnLevel;
- (NSString *)percentOfUsedSpaceString;
- (NSString *)diskSizeString;
- (NSString *)diskFreeSizeString;
- (NSNumber *)percentOfUsedSpace;
- (int)getDiskPercentage;

@end
