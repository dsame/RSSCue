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
#import "EMKeychain.h"

static NSString *const kServiceName = @"RSS Cue";

@interface  RCPreferencesController()
-(NSString *)selectedUUID;    
@end

@implementation RCPreferencesController

#pragma mark accessors
@synthesize fieldURL=_fieldURL;
@synthesize fieldLogin=_fieldLogin;
@synthesize fieldPassword=_fieldPassword;
@synthesize stepperInterval=_stepperInterval;
@synthesize stepperMax=_stepperMax;
@synthesize fieldInterval=_fieldInterval;

@synthesize checkboxEnabled=_checkboxEnabled;
@synthesize progress=_progress;
@synthesize info=_info;

@synthesize feedsArrayController=_feedsArrayController;
@synthesize buttons=_buttons;


-(NSString*)login{
    NSString* uuid=[self selectedUUID];
    if (uuid==nil) return @"";
    EMGenericKeychainItem * ki=[EMGenericKeychainItem genericKeychainItemForService:kServiceName withUsername:uuid];
    return ki?ki.label:@"";
}

-(void)setLogin:(NSString *)login{
    if ((void*)login==(void*)-1) return;//hack to trigger KVC on new selection
    NSString* uuid=[self selectedUUID];
    if (uuid==nil) return;
    EMGenericKeychainItem * ki=[EMGenericKeychainItem genericKeychainItemForService:kServiceName withUsername:uuid];
    if (!ki){
        NSString *password=[self.fieldPassword stringValue];
        ki=[EMGenericKeychainItem addGenericKeychainItemForService:(NSString *)kServiceName withUsername:uuid password:password label:login];
    }
    if (ki){
        ki.label=login;
    }
    if ((!ki.password || [ki.password isEqualToString:@""])&& (!ki.label || [ki.label isEqualToString:@""])){
        NSError *error;
        [EMKeychainItem deleteKeychainItem:ki error:&error];
    }
}
-(NSString*)password{
    NSString* uuid=[self selectedUUID];
    if (uuid==nil) return @"";
    EMGenericKeychainItem * ki=[EMGenericKeychainItem genericKeychainItemForService:kServiceName withUsername:uuid];
    return ki?ki.password:@"";
}

-(void)setPassword:(NSString *)password{
    if ((void*)password==(void*)-1) return;//hack to trigger KVC on new selection
    NSString* uuid=[self selectedUUID];
    if (uuid==nil) return;
    EMGenericKeychainItem * ki=[EMGenericKeychainItem genericKeychainItemForService:kServiceName withUsername:uuid];
    if (!ki){
        NSString *login=[self.fieldLogin stringValue];
        ki=[EMGenericKeychainItem addGenericKeychainItemForService:(NSString *)kServiceName withUsername:uuid password:password label:login];
    }
    if (ki){
        ki.password=password;
    }
    if ((!ki.password || [ki.password isEqualToString:@""])&& (!ki.label || [ki.label isEqualToString:@""])){
        NSError *error;
        [EMKeychainItem deleteKeychainItem:ki error:&error];
    }
}

- (BOOL)loginItemExistsWithLoginItemReference:(LSSharedFileListRef)theLoginItemsRefs ForPath:(CFURLRef)thePath {
    BOOL exists = NO;
    UInt32 seedValue;
    
    // We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
    // and pop it in an array so we can iterate through it to find our item.
    NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
    for (id item in loginItemsArray) {
        LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
        if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
            if ([[(NSURL *)thePath path] hasPrefix:@"/Applications/MyApp.app"])
                exists = YES;
        }
        return exists;
    };
    return NO;
}

-(BOOL) findLaunchItem:(LSSharedFileListItemRef*)pItemRef inLoginsList:(LSSharedFileListRef*)pLoginsList{
    NSURL * appPath=[[NSRunningApplication currentApplication] bundleURL];
    UInt32 seedValue;
    *pLoginsList = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(*pLoginsList, &seedValue);
    for (id item in loginItemsArray) {
        *pItemRef = (LSSharedFileListItemRef)item;
        NSURL* path;
        if (LSSharedFileListItemResolve(*pItemRef, 0, (CFURLRef*) &path, NULL) == noErr) {
            if ([path isEqual:appPath]) return YES;
        }
    };       
    return NO;
}
-(void)setRunOnLaunch:(NSNumber*)runOnLaunch{
    LSSharedFileListRef loginsList;
    LSSharedFileListItemRef itemRef;
    
    BOOL exists=[self findLaunchItem:&itemRef inLoginsList:&loginsList];
    CFURLRef path = (CFURLRef)[[NSRunningApplication currentApplication] bundleURL];
    
    if ([runOnLaunch boolValue] && !exists){        
        NSNumber * exist=[self runOnLaunch];
        if ([exist boolValue]) return;
        LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginsList, kLSSharedFileListItemLast, NULL, NULL, path, NULL, NULL);
        if (item)
            CFRelease(item);
    }else if (![runOnLaunch boolValue] && exists){        
        LSSharedFileListItemRemove(loginsList, itemRef);
    }
}

-(NSNumber *)runOnLaunch{
    LSSharedFileListRef loginsList;
    LSSharedFileListItemRef itemRef;
    
    return [NSNumber numberWithBool:[self findLaunchItem:&itemRef inLoginsList:&loginsList]];
}

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
    //NSAssert(!_isEditing,@"External update must be disable while the Preferences are editing");
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
    
    
    [self.info setStringValue:[NSString stringWithFormat:@"%@\nURL: %@\nTotal number of entries: %@\nNumber of shown entries: %@\nLast update: %@\n%@",title,link,total,reported, lastFetchTxt,summary]];
}

- (bool)endEditing;
{
	bool success;
	id responder = [[self window] firstResponder];
    
	// If we're dealing with the field editor, the real first responder is
	// its delegate.
    
	if ( (responder != nil) && [responder isKindOfClass:[NSTextView class]] && [(NSTextView*)responder isFieldEditor] )
		responder = ( [[responder delegate] isKindOfClass:[NSResponder class]] ) ? [responder delegate] : nil;
    
	success = [[self window] makeFirstResponder:nil];
    
	// Return first responder status.
    
	if ( success && responder != nil )
		[[self window ]makeFirstResponder:responder];
    
	return success;
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
    [self setControlsEnabled];
    [self updateInfoText];
    
    [_feedsArrayController addObserver:self forKeyPath:@"selection" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];    

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
        if (!_isConfigUpdatingOutside) {
            self.password=(NSString*)-1;//hack to trigger KVC
            self.login=(NSString*)-1;//hack to trigger KVC
        }
        [self setControlsEnabled];
        [self updateInfoText];
    }
}

- (void)controlTextDidBeginEditing:(NSNotification *)obj{
    _isEditing=YES;
}
- (void)controlTextDidEndEditing:(NSNotification *)aNotification {
    // The problem with this is the method may be called by the code, not by user action
    // I detect this with _isEditing=Yes/No
     NSAssert(!_isEditing || !_isConfigUpdatingOutside,@"External update must be disable while the Preferences are editing");
    if (_isEditing){
        NSString* uuid=[self selectedUUID];
        NSAssert(uuid,@"If it was manual editing then uuid must be set. If it was not then isEditing must be NO");
        [[RCFeedsPool sharedPool] restartFeedByUUID:uuid];
    }
    _isEditing=NO;
}

- (IBAction)stepperChanged:(id)sender {
    if (_isConfigUpdatingOutside) return; // Ugly, but it's better than updating modifing config
    NSString* uuid=[[self selectedConfig] objectForKey:@"uuid"];
    [[RCFeedsPool sharedPool] restartFeedByUUID:uuid];
}

- (IBAction)enableFeed:(id)sender {
    if (_isConfigUpdatingOutside) return; // Ugly, but it's better than updating modifing config
    NSString* uuid=[[self selectedConfig] objectForKey:@"uuid"];
    if ([self.checkboxEnabled state]==NSOnState )
        [[RCFeedsPool sharedPool] addFeedByUUID:uuid];
    else
        [[RCFeedsPool sharedPool] removeFeedByUUID:uuid];
    [self setControlsEnabled];
}


#pragma mark *** Buttons ***
- (IBAction)addRemoveFeed:(id)sender {
    
    [self endEditing];
    
    NSInteger button=[sender selectedSegment];

    
    NSArray * selection=[_feedsArrayController selectedObjects];
    NSDictionary * config=[selection count]>0?[selection objectAtIndex:0]:nil;
    RCFeed *f=config?[[RCFeedsPool sharedPool] feedForUUID:[config valueForKey:@"uuid"]]:nil;
    
    switch (button) {
        case 0:{
            CFUUIDRef theUUID;
            CFStringRef uuid;            theUUID = CFUUIDCreate(NULL);
            uuid = CFUUIDCreateString(NULL, theUUID);//TODO: release?
            CFRelease(theUUID);
            NSDictionary *newConfig=[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     (NSString *)uuid,@"uuid",
                                     @"",@"name",
                                     @"",@"url",
                                     @"", @"logon",
                                     @"",@"password",
                                     [NSNumber numberWithBool:NO],@"enabled",
                                     [NSNumber numberWithInt: 3],@"max",
                                     [NSNumber numberWithInteger:60],@"interval",
                                     nil];
            [_feedsArrayController addObject:newConfig];
            [_feedsArrayController setSelectedObjects:[NSArray arrayWithObject: newConfig]];
            
            [[NSUserDefaults standardUserDefaults] synchronize];
            // enable is always false in this point 
            [[RCFeedsPool sharedPool] addFeedByUUID:(NSString *)uuid];
            CFRelease(uuid); 
            break;
        }
        case 1:{
            if (f){ //no f means the feed is not enable
                [[RCFeedsPool sharedPool] removeFeedByUUID:[config valueForKey:@"uuid"]];
            }
            if (config){
                NSString* uuid=[config objectForKey:@"uuid"];
                if (uuid){
                    NSError *error;
                    EMGenericKeychainItem * ki=[EMGenericKeychainItem genericKeychainItemForService:kServiceName withUsername:uuid];
                    if (ki) [EMKeychainItem deleteKeychainItem:ki error:&error];
                }
            }
            NSUInteger selIndex=[_feedsArrayController selectionIndex];
            [_feedsArrayController remove:self];
            [[NSUserDefaults standardUserDefaults] synchronize];
            if (selIndex>0) [_feedsArrayController setSelectionIndex:selIndex-1];
            break;
        }
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
                [self updateInfoText];
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

-(void) feedsConfigWillUpdate:(NSNotification *)notification {
    if (_isEditing) {
        [NSUserDefaults disableConfigUpdate];
        return;
    }
    _isConfigUpdatingOutside=YES;
    _uuid=[[self selectedUUID] retain];
}
-(void) feedsConfigDidUpdate:(NSNotification *)notification {
    _isConfigUpdatingOutside=NO;
    if (!_isEditing){
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
        if ([self.window isVisible]) 
            [self updateInfoText];   
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
    [[self window] close];
}
- (void)windowWillClose:(NSNotification *) notification{
    [self endEditing];
    [[NSUserDefaults standardUserDefaults] synchronize];
    //[[RCFeedsPool sharedPool] launchAll];    
}


@end
