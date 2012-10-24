//
//  SummaryWindowController.h
//  GNE Mac Status
//
//  Created by Zack Smith and Arek Sokol on 8/17/11.
//  Copyright 2011 Genentech. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Constants.h"


@interface SummaryWindowController : NSWindowController {
	IBOutlet NSWindow *window;
	IBOutlet NSButton *attemptToRepairButton;
	IBOutlet NSButton *refreshButton;
	IBOutlet NSTableView *tableView;
	IBOutlet NSTextField *uiLabel;
	IBOutlet NSBox *progressBox;
	
	IBOutlet NSPopUpButton *toggleSummaryPredicateButton;
	// Our Progress Bar
	IBOutlet NSProgressIndicator *userProgressBar;
	IBOutlet NSProgressIndicator *summaryProgressBar;

	
	IBOutlet NSTableColumn *statusCol;
	IBOutlet NSTableColumn *discriptionCol;
	IBOutlet NSTableColumn *statusTxtCol;
	NSMutableArray *globalStatusArray;
	
	// Standard Object Set
	NSBundle *mainBundle;
	NSDictionary *settings;
	
	// Data source @private
	NSMutableArray *aBuffer;

	NSString *statusPredicate;
	
	NSDictionary *lastGlobalStatusUpdate;

	BOOL debugEnabled;
	BOOL windowNeedsResize;

}

- (void)readInSettings ;
- (void) startUserProgressIndicator:(id)sender;
- (void) stopUserProgressIndicator:(id)sender;
- (void) makeWindowFullScreen;
- (void) windowClosed;
//- (IBAction)refreshButtonClicked:(id)sender;
- (NSMutableArray*)aBuffer;
- (IBAction)attemptToFixButton:(id)sender;
- (void)displayAlertDialog;
- (void)reloadTableBuffer:(NSDictionary *)globalStatusUpdate;
- (void)reloadTableBufferNow:(NSNotification *) notification;
- (void)reconIsCompleted:(NSNotification *) notification;
- (void)attemptToRepairStarted:(NSNotification *) notification;
- (void)attemptToRepairCompleted:(NSNotification *) notification;
- (void)expandProgressBar:(id)sender;
- (void)closeProgressBar:(id)sender;
- (void)startSummaryProgressIndicator;
- (void)stopSummaryProgressIndicator;

// IBActions
-(IBAction)toggleSummaryPredicate:(id)sender;

//@property (nonatomic,retain) NSMutableArray* aBuffer;


@end
