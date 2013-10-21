//
//  RGItem.m
//  RssGrowler
//
//  Created by Sergey Dolin on 10/14/13.
//  Copyright 2013 DSA. All rights reserved.
//

#import "RCItem.h"


@implementation RCItem

@synthesize reported=_reported;
@synthesize link=_link;
@synthesize title=_title;
@synthesize description=_description;
@synthesize date=_date;


-(BOOL) isSameAs:(RCItem*)item{
    return [self.title isEqualToString:item.title] && [self.description isEqualToString:item.description] && [self.link isEqualToString:item.link];
};
-(RCItem*) init{
    self=[super init];
    self.description=@"";
    self.title=@"";
    return self;
}
@end

