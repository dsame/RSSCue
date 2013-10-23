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
    NSMutableDictionary* _timers;
    NSDate* _launchTime;
}
+(RCFeedsPool*) sharedPool;


-(void)launchAll;
-(RCFeed *) feedForUUID:(NSString *)uuid;
-(void) addFeedByUUID:(NSString*)uuid;
-(void) removeFeedByUUID:(NSString*)uuid;
-(void) restartFeedByUUID:(NSString*)uuid;
@end
