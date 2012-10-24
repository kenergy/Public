//
//  Constants.m
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 8/22/11.
//  Copyright 2011 Genentech. All rights reserved.
//

#import "Constants.h"


@implementation Constants
// Standard Notfications
NSString * const SettingsFileResourceID = @"com.gene.settings";

# pragma mark NSNotifications
// Status Notifications
NSString * const RequestStatusUpdateNotification = @"RequestStatusUpdateNotification";
NSString * const StatusUpdateNotification = @"StatusUpdateNotification";
NSString * const ShowPleaseWaitNotification = @"ShowPleaseWaitNotification";
NSString * const StartPleaseWaitNotification = @"StartPleaseWaitNotification";

// Repair Notifications
NSString * const RequestAttemptToRepairNotification = @"RequestAttemptToRepairNotification";
NSString * const AttemptToRepairCompleteNotification = @"AttemptToRepairCompleteNotification";
NSString * const AttemptToRepairStartedNotification = @"AttemptToRepairStartedNotification";
// Recon Notifications
NSString * const RequestReconNotification = @"RequestReconNotification";
NSString * const ReconCompleteNotification = @"ReconCompleteNotification";
//Plugin Notifications
NSString * const PluginsHaveLoadedNotfication = @"PluginsHaveLoadedNotfication";




@end
