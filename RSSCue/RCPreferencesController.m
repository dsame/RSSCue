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
@synthesize selectionIndexes;
@synthesize buttons=_buttons;

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

}
- (void) awakeFromNib {
    [feedsArrayController addObserver:self forKeyPath:@"selection" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];
    unsigned long c=[[feedsArrayController selectedObjects] count];
    [self.buttons setEnabled:c>0 forSegment:1];
}

#pragma mark *** observers ***

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selection"]){
        unsigned long c=[[feedsArrayController selectedObjects] count];
        [self.buttons setEnabled:c>0 forSegment:1];
    }
}

#pragma mark *** Buttons ***
- (IBAction)addRemoveFeed:(id)sender {
    NSInteger button=[sender selectedSegment];
    CFUUIDRef theUUID;
    CFStringRef string;
    
    switch (button) {
        case 0:
            theUUID = CFUUIDCreate(NULL);
            string = CFUUIDCreateString(NULL, theUUID);
            CFRelease(theUUID);
            [feedsArrayController addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"uuid",[(NSString *)string autorelease],@"name",@"",@"url",@"", @"logon",@"",@"password",@"",nil]];
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
