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
}
@property (assign) IBOutlet NSArrayController *feedsArrayController;
@property (assign) IBOutlet NSSegmentedControl *buttons;
@property (assign) IBOutlet NSTextField *info;
@property (assign) IBOutlet NSButton *testButton;
@property (assign) IBOutlet NSProgressIndicator *progress;

- (IBAction)addRemoveFeed:(id)sender;
- (IBAction)testFeed:(id)sender;
- (IBAction)save:(id)sender;

@end
