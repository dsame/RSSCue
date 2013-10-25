//
//  NSUserDefaults+FeedConfig.h
//  RSSCue
//
//  Created by Sergey Dolin on 10/21/13.
//  Copyright (c) 2013 DSA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCFeed.h"

@interface NSUserDefaults (FeedConfig) 
+ (NSMutableDictionary* ) configForFeedByUUID:(NSString *)uuid;
+ (void) updateConfigForFeed:(RCFeed*)feed;
+ (void) disableConfigUpdate;

@end
