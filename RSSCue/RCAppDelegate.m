//
//  RCAppDelegate.m
//  RSSCue
//
//  Created by Sergey Dolin on 10/16/13.
//  Copyright (c) 2013 DSA. All rights reserved.
//

#import "RCAppDelegate.h"
#import "RCPreferencesController.h"

@implementation RCAppDelegate

@synthesize statusMenu = _statusMenu;


- (void)dealloc
{
    [super dealloc];
}
	
#pragma mark *** Launching ***

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSDictionary *appDefaults = [NSDictionary
                                 dictionaryWithObjectsAndKeys:@"name",nil,@"img", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
}

- (void) awakeFromNib {
	_statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain]; 
	[_statusItem setMenu:_statusMenu];
	[_statusItem setTitle:@"RSS Cue"];
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
    [[_preferencesPanelController window] makeKeyAndOrderFront:self];
}

@end
