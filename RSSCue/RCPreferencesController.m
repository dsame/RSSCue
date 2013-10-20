//
//  RCPreferencesController.m
//  RSSCue
//
//  Created by Sergey Dolin on 10/16/13.
//  Copyright (c) 2013 DSA. All rights reserved.
//

#import "RCPreferencesController.h"

@implementation RCPreferencesController
@synthesize testButton;
@synthesize progress;
@synthesize info;

@synthesize feedsArrayController;
@synthesize buttons=_buttons;

#pragma mark utilities 
- (void) setControlsEnabled {
    unsigned long c=[[feedsArrayController selectedObjects] count];
    [self.buttons setEnabled:c>0 forSegment:1];
    [self.testButton setEnabled:c>0];
}


#pragma mark Utilities
- (void) clearInfo {
    [self.info setStringValue:@""];
}
- (void) printInfo:(NSString *) msg{
    [self.info setStringValue:[NSString stringWithFormat:@"%@\n%@",[self.info stringValue],msg]];
}
- (void) printError:(NSError *) error{
    [self printInfo:[[error userInfo] objectForKey:NSLocalizedDescriptionKey]];
}
- (void) printFeedError {
    [self printError:_feed.error];
}

#pragma mark Initialization
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
    [self setControlsEnabled];
}

#pragma mark Controls observers

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selection"]){
        [self setControlsEnabled];
    }
}

#pragma mark *** Buttons ***
- (IBAction)addRemoveFeed:(id)sender {
    NSInteger button=[sender selectedSegment];
    CFUUIDRef theUUID;
    CFStringRef uuid;
    
    switch (button) {
        case 0:
            theUUID = CFUUIDCreate(NULL);
            uuid = CFUUIDCreateString(NULL, theUUID);
            CFRelease(theUUID);
            [feedsArrayController addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                             [(NSString *)uuid autorelease],@"uuid",
                                             @"",@"name",
                                             @"",@"url",
                                             @"", @"logon",
                                             @"",@"password",
                                             [NSNumber numberWithInteger:60],@"interval",
                                             nil]];
            break;
        case 1:
            [feedsArrayController remove:self]; 
        default:
            break;
    }
}

- (IBAction)testFeed:(id)sender {
    [self clearInfo];
    [self.progress startAnimation:self];
    NSDictionary * config=[[feedsArrayController selectedObjects] objectAtIndex:0];
    [_feed release];
    _feed=[[[RCFeed alloc] initWithConfiguration:config andDelegate:self] retain];
    [_feed run];
}

#pragma mark FeedDelegate
-(void) feedFailed:(RCFeed *)feed {
    [self.progress stopAnimation:self];
    NSAlert* msgBox = [NSAlert alertWithError:feed.error];
    [msgBox runModal];
}
-(void) feedSuccess:(RCFeed *)feed {
    [self.progress stopAnimation:self];
    NSAlert* msgBox = [NSAlert alertWithMessageText:@"Success!" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"Effective URL: %@\nTitle: %@\nType: %@\nNumber of Entries: %d",[_feed.effectiveURL absoluteString],_feed.title,_feed.type,[[_feed items] count],nil];
    [msgBox runModal];
}

-(void) feedStateChanged:(RCFeed *)feed {
    NSLog(@"status %d",[feed state]);
}
- (IBAction)save:(id)sender {
    id r=[[[self window] firstResponder] retain];
    [[self window] makeFirstResponder:nil];
    [[self window] makeFirstResponder:r];
    [r release];
    [[self window] close];
}
@end
