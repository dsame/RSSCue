//
//  RCAppDelegate.h
//  RSSCue
//
//  Created by Sergey Dolin on 10/16/13.
//  Copyright (c) 2013 DSA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>


@interface RCAppDelegate : NSObject <NSApplicationDelegate, GrowlApplicationBridgeDelegate> {
    NSWindowController *_preferencesPanelController;
    NSStatusItem * _statusItem;
    NSMenu* _statusMenu;
}

@property (assign) IBOutlet NSMenu *statusMenu;

- (IBAction)showPreferencesPanel:(id)sender;

@end
