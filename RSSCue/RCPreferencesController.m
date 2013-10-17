//
//  RCPreferencesController.m
//  RSSCue
//
//  Created by Sergey Dolin on 10/16/13.
//  Copyright (c) 2013 DSA. All rights reserved.
//

#import "RCPreferencesController.h"

@implementation RCPreferencesController

@synthesize feedsArrayController;

#pragma mark *** Inits ***
- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark *** Buttons ***
- (IBAction)addRemoveFeed:(id)sender {
    NSInteger button=[sender selectedSegment];
    NSLog(@"btn=%d",(int)button);
    //NSDictionary * feed;
    switch (button) {
        case 0:
            //feed=[[NSDictionary dictionaryWithObjectsAndKeys:@"<New Feed>",@"name",nil] autorelease];
            //[feedsArrayController addObject:feed];
            [feedsArrayController add: self];
            break;
        case 1:
            [feedsArrayController remove:self]; 
        default:
            break;
    }
    /*
    NSSegmentedControl * control=sender;
    NSUserDefaultsController *udc=[NSUserDefaultsController sharedUserDefaultsController];
    NSLog(@"Clicked %D",[control selectedSegment]);*/
}

@end
