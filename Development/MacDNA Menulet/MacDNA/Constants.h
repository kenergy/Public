//
//  Constants.h
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 8/22/11.
//  Copyright 2011 Genentech. All rights reserved.
//

#import <Cocoa/Cocoa.h>
// Status Notifications
extern NSString * const RequestStatusUpdateNotification;
extern NSString * const StatusUpdateNotification;
extern NSString * const ShowPleaseWaitNotification;
extern NSString * const StartPleaseWaitNotification;

// Repair Notifications
extern NSString * const AttemptToRepairCompleteNotification;
extern NSString * const AttemptToRepairStartedNotification;
extern NSString * const RequestAttemptToRepairNotification;
// Recon Notifications
extern NSString * const RequestReconNotification;
extern NSString * const ReconCompleteNotification;
//Plugin Notifications
extern NSString * const PluginsHaveLoadedNotfication;


extern NSString * const SettingsFileResourceID;

@interface Constants : NSWindowController {

}

@end
