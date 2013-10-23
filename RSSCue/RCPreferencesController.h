//
//  RCPreferencesController.h
//  RSSCue
//
//  Created by Sergey Dolin on 10/16/13.
//  Copyright (c) 2013 DSA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RCFeed.h"

@interface RCPreferencesController : NSWindowController <RCFeedDelegate> {
    RCFeed * _feed;
    NSString * _uuid;
}

@property (assign) IBOutlet NSArrayController *feedsArrayController;
@property (assign) IBOutlet NSSegmentedControl *buttons;
@property (assign) IBOutlet NSTextField *info;
@property (assign) IBOutlet NSProgressIndicator *progress;
@property (retain) NSString* login;
@property (retain) NSString* password;

- (IBAction)addRemoveFeed:(id)sender;
- (IBAction)save:(id)sender;

- (void)controlTextDidEndEditing:(NSNotification *)aNotification;

@property (assign) IBOutlet NSTextField *fieldURL;
@property (assign) IBOutlet NSTextField *fieldLogin;
@property (assign) IBOutlet NSTextField *fieldPassword;
@property (assign) IBOutlet NSStepper *stepperInterval;
@property (assign) IBOutlet NSStepper *stepperMax;
@property (assign) IBOutlet NSTextField *fieldInterval;
@property (assign) IBOutlet NSButton *checkboxEnabled;

- (IBAction)stepperChanged:(id)sender;
- (IBAction)enableFeed:(id)sender;

@end
