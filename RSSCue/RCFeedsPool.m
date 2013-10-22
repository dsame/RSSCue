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

-(void) addFeedByConfig:(NSDictionary *)config {
    if (NO==[[config valueForKey:@"enabled"] boolValue]) {
        return;
    }
    NSString *uuid=[config valueForKey:@"uuid"];
    NSAssert(uuid!=nil, @"UUID must not be nill\n%@", config);
    RCFeed* feed=[[[RCFeed alloc] initWithUUID:uuid andDelegate:self] autorelease];
    NSLog(@"Feed %@ started",feed.name);
    [feed run];
    NSTimeInterval interval=[[config objectForKey:@"interval"] doubleValue];
    if (interval<10) interval=10; //precaution
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                      target:self 
                                                    selector:@selector(runFeed:)
                                                    userInfo:[NSDictionary dictionaryWithObject:feed forKey:@"feed"] 
                                                     repeats:YES];
    [_timers setObject:timer forKey:uuid];
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
    NSLog(@"Feed %@ removed",feed.name);
    [feed release];
};

-(void) updateFeedByUUID:(NSString*)uuid{
    [self removeFeedByUUID:uuid];
    [self addFeedByUUID:uuid];
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
    RCFeed *feed=[[timer userInfo] objectForKey:@"feed"];
    NSLog(@"Feed %@ started",feed.name);
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
    unsigned int repc=0;
    unsigned int max=[[feed.configuration objectForKey:@"max"] unsignedIntValue];
    
    for(RCItem * i in feed.items){
        if (!i.isReported){
            [GrowlApplicationBridge notifyWithTitle:i.title
                                        description:[NSString stringWithFormat:@"%@",i.description]
                                   notificationName:@"ItemArrived"
                                           iconData:nil
                                           priority:0
                                           isSticky:NO
                                       clickContext:nil];
            i.reported=YES;
            repc=repc+1;
            if (repc>=max){
                NSLog(@"Feed \"%@\" exceeded number of max allowed entries, some will be skipped",feed.name);
                break;
            }
        }else{
            repc=repc+1;
        }
    }
    
    feed.reported=repc;
    
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
