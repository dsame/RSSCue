//
//  RCPreferencesController.m
//  RSSCue
//
//  Created by Sergey Dolin on 10/16/13.
//  Copyright (c) 2013 DSA. All rights reserved.
//

#import "RCPreferencesController.h"
#import "RCFeedsPool.h"
#import "NSUserDefaults+FeedConfig.h"

@implementation RCPreferencesController
@synthesize fieldURL=_fieldURL;
@synthesize fieldLogin=_fieldLogin;
@synthesize fieldPassword=_fieldPassword;
@synthesize stepperInterval=_stepperInterval;
@synthesize stepperMax=_stepperMax;
@synthesize fieldInterval=_fieldInterval;

@synthesize checkboxEnabled=_checkboxEnabled;
@synthesize progress=_progress;
@synthesize info=_info;

@synthesize login=_login;
@synthesize password=_password;

@synthesize feedsArrayController=_feedsArrayController;
@synthesize buttons=_buttons;

#pragma mark utilities 
- (NSDictionary *)selectedConfig{
    NSArray * selection=[_feedsArrayController selectedObjects];
    NSDictionary * config=[selection count]>0?[selection objectAtIndex:0]:nil;
    return config;
}
- (NSString *)selectedUUID {
    NSDictionary *config=[self selectedConfig];
    return config?[config objectForKey:@"uuid"]:nil;
}

- (void) setControlsEnabled {
    unsigned long c=[[_feedsArrayController selectedObjects] count];
    [self.buttons setEnabled:c>0 forSegment:1];
    [self.buttons setEnabled:c>0 forSegment:2];
    if (c>0){
        NSDictionary * config=[[_feedsArrayController selectedObjects] objectAtIndex:0];
        [self.buttons setEnabled:[[config valueForKey:@"enabled"] boolValue]==YES forSegment:3];
    }
}

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

- (void) updateInfoText {
    NSArray * sel=[_feedsArrayController selectedObjects];
    if (sel.count<1){
        [self.info setStringValue:@""];
        return;
    }
    NSDictionary *config=[NSUserDefaults configForFeedByUUID:[[sel objectAtIndex:0] valueForKey:@"uuid"]];
    
    RCFeed* f=[[RCFeedsPool sharedPool] feedForUUID:[config valueForKey:@"uuid"]];
    NSString * title=[config valueForKey:@"title"];if (title==nil) title=@"<Untitled>";
    NSString * link=[config valueForKey:@"link"];if (link==nil) link=@"<No URL>";
    NSString * summary=[config valueForKey:@"description"];if (summary==nil) summary=@"";
    NSDate * lastFetch=[config valueForKey:@"lastFetch"];
    NSString * lastFetchTxt;

    id total;
    id reported;

    if (lastFetch) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"MMM dd, yyyy HH:mm:ss"];
        lastFetchTxt=[df stringFromDate:lastFetch];
        [df release];
        total=[NSNumber numberWithUnsignedLong:f.items.count];
        reported=[NSNumber numberWithUnsignedInt:f.reported];
    } else {
        lastFetchTxt=@"<Never>";    
        total=@"<Unknown>";
        reported=@"<Unknown>";
    }
    
    
    [self.info setStringValue:[NSString stringWithFormat:@"%@\nURL: %@\nTotal number of entries: %@\nNumber of shown entries: %@\nLast fetch: %@\n%@",title,link,total,reported, lastFetchTxt,summary]];
}

- (IBAction)restartSelectedFeed:(id)sender {
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
    [_feedsArrayController addObserver:self forKeyPath:@"selection" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];

    [self setControlsEnabled];
    [self updateInfoText];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(feedUpdated:)
                                                 name:@"feedUpdate" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(feedsConfigWillUpdate:)
                                                 name:@"feeds_config_to_be_updated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(feedsConfigDidUpdate:)
                                             name:@"feeds_config_updated" object:nil];
}
#pragma mark Controls observers & delegators

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selection"]){
        [self setControlsEnabled];
        [self updateInfoText];
    }
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification {
    NSTextField* f=[aNotification object];
    if (f==self.fieldLogin||f==self.fieldURL||f==self.fieldPassword){
        NSString* uuid=[[self selectedConfig] objectForKey:@"uuid"];
        [[RCFeedsPool sharedPool] restartFeedByUUID:uuid];
    }
}

- (IBAction)stepperChanged:(id)sender {
    NSString* uuid=[[self selectedConfig] objectForKey:@"uuid"];
    [[RCFeedsPool sharedPool] restartFeedByUUID:uuid];
}

- (IBAction)enableFeed:(id)sender {
    NSString* uuid=[[self selectedConfig] objectForKey:@"uuid"];
    if ([self.checkboxEnabled state]==NSOnState )
        [[RCFeedsPool sharedPool] addFeedByUUID:uuid];
    else
        [[RCFeedsPool sharedPool] removeFeedByUUID:uuid];
    [self setControlsEnabled];
}


#pragma mark *** Buttons ***
- (IBAction)addRemoveFeed:(id)sender {
    NSInteger button=[sender selectedSegment];
    CFUUIDRef theUUID;
    CFStringRef uuid;
    
    NSArray * selection=[_feedsArrayController selectedObjects];
    NSDictionary * config=[selection count]>0?[selection objectAtIndex:0]:nil;
    RCFeed *f=config?[[RCFeedsPool sharedPool] feedForUUID:[config valueForKey:@"uuid"]]:nil;
    
    switch (button) {
        case 0:
            theUUID = CFUUIDCreate(NULL);
            uuid = CFUUIDCreateString(NULL, theUUID);//TODO: release?
            CFRelease(theUUID);
            [_feedsArrayController addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             (NSString *)uuid,@"uuid",
                                             @"",@"name",
                                             @"",@"url",
                                             @"", @"logon",
                                             @"",@"password",
                                             [NSNumber numberWithBool:NO],@"enabled",
                                             [NSNumber numberWithInt: 3],@"max",
                                             [NSNumber numberWithInteger:60],@"interval",
                                             nil]];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[RCFeedsPool sharedPool] addFeedByUUID:(NSString *)uuid];
            CFRelease(uuid); 
            break;
        case 1:
            if (f){ //no f means the feed is not enable
                [[RCFeedsPool sharedPool] removeFeedByUUID:[config valueForKey:@"uuid"]];
            }
            [_feedsArrayController remove:self]; 
            [[NSUserDefaults standardUserDefaults] synchronize];
            break;
        case 2:
            NSAssert(config!=nil, @"Attempt to test a feed with no configuraiton");
            [self.progress startAnimation:self];
            [_feed release];
            _feed=[[[RCFeed alloc] initWithUUID:[config valueForKey:@"uuid"] andDelegate:self] retain];
            [_feed run];
            break;
        case 3:
            if (f){//NSAssert(f!=nil, @"Attempt to refresh a feed with no configuraiton or unexisting feed");
                [f makeUnreported];
                NSAlert* alert=[NSAlert alertWithMessageText:@"The feed has been marked as never read" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"Number of entries: %u",[f.items count]];
                [alert runModal];
            }else{
                NSAlert* alert=[NSAlert alertWithMessageText:@"The feed is not enabled" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
                [alert runModal];
                
            }
            break;
        default:
            break;
    }
}

#pragma mark Handle notifications

-(void) feedUpdated:(NSNotification *)notification {
    if (![self.window isVisible]) return;
    [self updateInfoText];
}
-(void) feedsConfigWillUpdate:(NSNotification *)notification {
    [_uuid release];
    _uuid=[[self selectedUUID] retain];
}
-(void) feedsConfigDidUpdate:(NSNotification *)notification {
    if (_uuid!=nil){
        NSArray * configs=[_feedsArrayController arrangedObjects];
        for (unsigned long i=0; i<configs.count; i++) {
            if ([_uuid isEqualToString:[[configs objectAtIndex:i] objectForKey:@"uuid"]]){
                [_feedsArrayController setSelectionIndex:i];
                break;
            }
        }
        [_uuid release];
        _uuid=nil;
    }
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
    
}



- (IBAction)save:(id)sender {
    id r=[[[self window] firstResponder] retain];
    [[self window] makeFirstResponder:nil];
    [[self window] makeFirstResponder:r];
    [r release];
    [[self window] close];
}
- (void)windowWillClose:(NSNotification *) notification{
    [[NSUserDefaults standardUserDefaults] synchronize];
    //[[RCFeedsPool sharedPool] launchAll];    
}


@end
