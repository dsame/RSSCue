//
//  RCPreferencesController.h
//  RSSCue
//
//  Created by Sergey Dolin on 10/16/13.
//  Copyright (c) 2013 DSA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RCPreferencesController : NSWindowController
@property (assign) IBOutlet NSArrayController *feedsArrayController;
@property (assign) NSIndexSet * selectionIndexes;
@property (assign) IBOutlet NSSegmentedControl *buttons;

- (IBAction)addRemoveFeed:(id)sender;

@end
