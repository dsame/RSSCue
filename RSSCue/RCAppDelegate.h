//
//  RCAppDelegate.h
//  RSSCue
//
//  Created by Sergey Dolin on 10/16/13.
//  Copyright (c) 2013 DSA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RCAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindowController *_preferencesPanelController;
    NSStatusItem * _statusItem;
}

@property (assign) IBOutlet NSMenu *statusMenu;

- (IBAction)showPreferencesPanel:(id)sender;

@end
