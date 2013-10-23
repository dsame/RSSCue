//
//  RGItem.h
//  RssGrowler
//
//  Created by Sergey Dolin on 10/11/13.
//  Copyright 2013 DSA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RCItem : NSObject {
    BOOL _reported;
    NSString * _link;
    NSString * _title;
    NSString * _description;
    NSDate * _date;
}
@property (assign,getter = isReported) BOOL reported;
@property (copy) NSString * link;
@property (copy) NSString * title;
@property (copy) NSString * description;
@property (copy) NSDate * date;

-(BOOL) isSameAs:(RCItem*)item;
@end
