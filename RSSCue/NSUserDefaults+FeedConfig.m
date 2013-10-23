//
//  NSUserDefaults+FeedConfig.m
//  RSSCue
//
//  Created by Sergey Dolin on 10/21/13.
//  Copyright (c) 2013 DSA. All rights reserved.
//

#import "NSUserDefaults+FeedConfig.h"


@implementation NSUserDefaults (FeedConfig)

+ (NSMutableDictionary* ) configForFeedByUUID:(NSString *)uuid{
    NSMutableArray *configs=[[NSUserDefaults standardUserDefaults] valueForKey:@"feeds"];
    NSAssert(configs!=nil,@"Userdefaults has not \"feeds\" key");
    for (NSMutableDictionary *config in configs) {
        NSString* _uuid=[config valueForKey:@"uuid"];
        if ([uuid isEqualToString:_uuid]) return  config;
    }
    NSAssert(configs!=nil,@"Userdefaults has not \"feed\" for uid=%@",uuid);
    return nil;
}
+ (void) updateConfigForFeed:(RCFeed*)feed {
    NSUserDefaults* ud=[NSUserDefaults standardUserDefaults];
    NSMutableArray *configs=[[[ud valueForKey:@"feeds"] mutableCopy] autorelease];
    for (unsigned int ci=0;ci<configs.count;ci++){
        NSMutableDictionary* config=[[[configs objectAtIndex:ci] mutableCopy] autorelease];
        if ([feed.uuid isEqualToString:[config valueForKey:@"uuid"]]){
            [config setValue:feed.title forKey:@"title"];
            [config setValue:feed.link forKey:@"link"];
            [config setValue:feed.description forKey:@"description"];
            [config setValue:[NSDate date] forKey:@"lastFetch"];
            [configs replaceObjectAtIndex:ci withObject:config];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"feeds_config_to_be_updated" object:self];
            [ud setValue:configs forKey:@"feeds"];
            
            [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:@"feeds_config_updated" object:self] postingStyle:NSPostASAP  coalesceMask:NSNotificationCoalescingOnName forModes:nil];
            return;
        }
    }
}
@end
