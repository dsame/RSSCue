//
//  RCFeedDesc.m
//  RSSCue
//
//  Created by Sergey Dolin on 10/17/13.
//  Copyright (c) 2013 DSA. All rights reserved.
//

#import "RCFeedDesc.h"

@implementation RCFeedDesc

@synthesize name=_name;

- (void) dealloc{
    self.name=nil;
    [super dealloc];
}
@end
