//
//  RCFeedsPool.h
//  RSSCue
//
//  Created by Sergey Dolin on 10/20/13.
//  Copyright (c) 2013 DSA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCFeed.h"
#import "RCFeedDelegate.h"

@interface RCFeedsPool : NSObject<RCFeedDelegate> {
    NSMutableArray* _timers;
}
+(RCFeedsPool*) sharedPool;
-(void)launchAll;
-(RCFeed *) feedForConfiguration:(NSDictionary *)config;
@end
