//
//  RCFeedsPool.m
//  RSSCue
//
//  Created by Sergey Dolin on 10/20/13.
//  Copyright (c) 2013 DSA. All rights reserved.
//

#import "RCFeedsPool.h"
#import "RCFeed.h"

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

-(void)launchAll{
    [_timers release];
    NSArray *configs=[[NSUserDefaults standardUserDefaults] arrayForKey:@"feeds"];
    _timers=[[NSMutableArray alloc] initWithCapacity:[configs count]];
    NSLog(@"Timers will be respawned for %lu feeds",[configs count]);
    for (NSDictionary* config in configs){
        RCFeed* feed=[[[RCFeed alloc] initWithConfiguration:config andDelegate:self] autorelease];
        NSLog(@"Feed %@ started",feed.name);
        [feed run];
        NSTimeInterval interval=[[config objectForKey:@"interval"] doubleValue];
        if (interval<10) interval=10; //precaution
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                          target:self 
                                                        selector:@selector(runFeed:)
                                                        userInfo:[NSDictionary dictionaryWithObject:feed forKey:@"feed"] 
                                                         repeats:YES];
        [_timers addObject:timer];
    }
}

- (void)runFeed:(NSTimer*)timer {
    RCFeed *feed=[[timer userInfo] objectForKey:@"feed"];
    NSLog(@"Feed %@ started",feed.name);
    [feed run];
}

#pragma mark Feed Deligators
- (void) feedFailed:(RCFeed *) feed{
    NSLog(@"Feed \"%@\" failed with the message: %@(%@)",feed.name,[feed.error localizedDescription],[feed.error localizedRecoverySuggestion]);    
}
- (void) feedSuccess:(RCFeed *) feed{
    NSLog(@"Feed \"%@\" success",feed.name);
}
- (void) feedStateChanged:(RCFeed *) feed{
}

@end
