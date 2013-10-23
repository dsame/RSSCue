//
//  RCFeedsPool.m
//  RSSCue
//
//  Created by Sergey Dolin on 10/20/13.
//  Copyright (c) 2013 DSA. All rights reserved.
//

#import "RCFeedsPool.h"
#import "RCFeed.h"
#import <Growl/Growl.h>
#import "NSUserDefaults+FeedConfig.h"

@implementation RCFeedsPool
static RCFeedsPool * _sharedPool;

+ (void)initialize
{
    if(_sharedPool==nil)
    {
        _sharedPool = [[RCFeedsPool alloc] init];
    }
}

+ (RCFeedsPool*)sharedPool{
    return _sharedPool;
}

-(id)init{
    self=[super init];
    _launchTime=[[NSDate date] retain];
    return self;
}

-(void) dealloc{
    [_launchTime release];
    [super dealloc];
}
-(void) addFeed:(RCFeed *)feed withConfig:(NSDictionary *)config {
    if (NO==[[config valueForKey:@"enabled"] boolValue]) {
        return;
    }
    NSTimeInterval interval=[[config objectForKey:@"interval"] doubleValue];
    if (interval<10) interval=10; //precaution
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                      target:self 
                                                    selector:@selector(runFeed:)
                                                    userInfo:[NSDictionary dictionaryWithObject:feed forKey:@"feed"] 
                                                     repeats:YES];
    [_timers setObject:timer forKey:feed.uuid];
    NSLog(@"Feed %@ added to the schedule",feed.name);
};

-(void) addFeedByConfig:(NSDictionary *)config {

    NSString *uuid=[config valueForKey:@"uuid"];
    NSAssert(uuid!=nil, @"UUID must not be nill\n%@", config);
    RCFeed* feed=[[[RCFeed alloc] initWithUUID:uuid andDelegate:self] autorelease];
    
    //[feed run];
    [self addFeed:feed withConfig:config];
};

-(void) addFeedByUUID:(NSString*)uuid {
    NSDictionary * config=[NSUserDefaults configForFeedByUUID:uuid];
    NSAssert(config!=nil, @"Attempt to add a feed with no configuraiton, uuid=%@",uuid);
    [self addFeedByConfig:config];
};

-(void) removeFeedByUUID:(NSString*)uuid{
    NSTimer * timer=[_timers objectForKey:uuid];
    RCFeed *feed=[[[timer userInfo] objectForKey:@"feed"] retain];
    [timer invalidate];
    [_timers removeObjectForKey:uuid];
    NSLog(@"Feed %@ removed from the schedule",feed.name);
    [feed release];
};

-(void) restartFeedByUUID:(NSString*)uuid{
    RCFeed *feed=[[self feedForUUID:uuid] retain];
    NSDictionary * config=[NSUserDefaults configForFeedByUUID:uuid];
    NSAssert(config!=nil, @"Attempt to add a feed with no configuraiton, uuid=%@",uuid);
    [self removeFeedByUUID:uuid];
    [self addFeed:feed withConfig:config];
    [feed release];
}

-(void)launchAll{
    [_timers release];
    NSArray *configs=[[NSUserDefaults standardUserDefaults] arrayForKey:@"feeds"];
    _timers=[[NSMutableDictionary alloc] initWithCapacity:[configs count]];
    for (NSDictionary* config in configs){
        [self addFeedByConfig:config];
    }
    NSLog(@"Timers have been respawned for %lu feeds",[_timers count]);
}

- (void)runFeed:(NSTimer*)timer {
    NSUserDefaults *ud=[NSUserDefaults standardUserDefaults];
    
    if ([[ud objectForKey:@"delayOnLaunch"] boolValue]==YES){
        NSTimeInterval passed=[[NSDate date] timeIntervalSinceDate:_launchTime];
        NSTimeInterval expected=[[ud objectForKey:@"delayOnLaunchInterval"] doubleValue];
        if (passed<expected) return;
    }
    RCFeed *feed=[[timer userInfo] objectForKey:@"feed"];
    //NSLog(@"Feed %@ started",feed.name);
    [feed run];
}

- (RCFeed *)feedForUUID:(NSString *)uuid{
    NSTimer * timer=[_timers objectForKey:uuid];
    if (!timer) return nil;
    RCFeed *feed=[[timer userInfo] objectForKey:@"feed"];
    NSAssert([feed.uuid isEqualToString:uuid],@"Timers queue has a feed with the UUID not equal to timer UUID");
    return feed;
}

#pragma mark Feed Deligators
- (void) feedFailed:(RCFeed *) feed{
    
    
    NSLog(@"Feed \"%@\" failed with the message: %@(%@)",feed.name,[feed.error localizedDescription],[feed.error localizedRecoverySuggestion]);    
}
- (void) feedSuccess:(RCFeed *) feed{
    NSLog(@"Feed \"%@\" success",feed.name);
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"readOnLaunch"] boolValue]==YES && feed.reported==0){
        for(RCItem * i in feed.items) i.reported=YES;
        feed.reported=(unsigned int)feed.items.count;
    }else{
        unsigned int repc=0,rept=0;
        unsigned int max=[[feed.configuration objectForKey:@"max"] unsignedIntValue];
        
        for(RCItem * i in feed.items){
            if (!i.isReported){
                [GrowlApplicationBridge notifyWithTitle:i.title
                                            description:[NSString stringWithFormat:@"%@",i.description]
                                       notificationName:@"ItemArrived"
                                               iconData:nil
                                               priority:0
                                               isSticky:NO
                                           clickContext:i.link];
                i.reported=YES;
                repc=repc+1;
                rept=rept+1;
                if (repc>=max){
                    //          NSLog(@"Feed \"%@\" exceeded number of max allowed entries, some will be skipped",feed.name);
                    break;
                }
            }else{
                rept=rept+1;
            }
        }
        feed.reported=rept;
    }
    
    
    [NSUserDefaults updateConfigForFeed:feed];
    
    NSNotification *n = [NSNotification notificationWithName:@"feedUpdate" object:feed];
    [[NSNotificationQueue defaultQueue]
     enqueueNotification:n
     postingStyle:NSPostWhenIdle
     coalesceMask:NSNotificationNoCoalescing
     forModes:nil];
}

- (void) feedStateChanged:(RCFeed *) feed{
}

@end
