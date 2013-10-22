//
//  RCAppDelegate.m
//  RSSCue
//
//  Created by Sergey Dolin on 10/16/13.
//  Copyright (c) 2013 DSA. All rights reserved.
//

#import "RCAppDelegate.h"
#import "RCPreferencesController.h"
#import "RCFeedsPool.h"

@implementation RCAppDelegate

@synthesize statusMenu = _statusMenu;


- (void)dealloc
{
    [super dealloc];
}
	
#pragma mark *** Launching ***

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[RCFeedsPool sharedPool] launchAll];
}

- (void) awakeFromNib {
	_statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:16] retain]; 
	[_statusItem setMenu:_statusMenu];
	[_statusItem setImage:[[[NSImage alloc] initByReferencingFile:[[NSBundle mainBundle] pathForResource:@"RSS-status-item" ofType:@"png"]] autorelease]];
	[_statusItem setHighlightMode:YES];
}

#pragma mark *** Preferences ***
- (IBAction)showPreferencesPanel:(id)sender {
    if (!_preferencesPanelController) {
        _preferencesPanelController = [[RCPreferencesController alloc] initWithWindowNibName:@"Preferences"];
        
        // Make the panel appear in a good default location.
        [[_preferencesPanelController window] center];
        
    }
    [_preferencesPanelController showWindow:self];
    //[[_preferencesPanelController window] makeKeyAndOrderFront:self];
}

@end
