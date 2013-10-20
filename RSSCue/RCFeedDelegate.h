//
//  RCFeedDelegate.h
//  RSSCue
//
//  Created by Sergey Dolin on 10/19/13.
//  Copyright (c) 2013 DSA. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RCFeed;

@protocol RCFeedDelegate
- (void) feedFailed:(RCFeed *) feed;
- (void) feedSuccess:(RCFeed *) feed;
- (void) feedStateChanged:(RCFeed *) feed;
@end
