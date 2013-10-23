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
    /*
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"showMenu"] intValue]==1){
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    }*/
    [GrowlApplicationBridge setGrowlDelegate:self];
    [[RCFeedsPool sharedPool] launchAll];
}
- (void) growlNotificationWasClicked:(id)clickContext{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:clickContext]];
};
- (void) awakeFromNib {
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"showMenu"] intValue]==1){
        _statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:16] retain]; 
        [_statusItem setMenu:_statusMenu];
        [_statusItem setImage:[[[NSImage alloc] initByReferencingFile:[[NSBundle mainBundle] pathForResource:@"RSS-status-item" ofType:@"png"]] autorelease]];
        [_statusItem setHighlightMode:YES];
    }else{
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    }
}
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag{
    [self showPreferencesPanel:self];
    return NO;
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
