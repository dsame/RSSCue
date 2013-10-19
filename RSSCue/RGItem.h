//
//  RGItem.h
//  RssGrowler
//
//  Created by Sergey Dolin on 10/11/13.
//  Copyright 2013 DSA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RGItem : NSObject
{
@public
	NSString * link;
	NSString * title; //atom updated
	NSString * description;
}
@property (retain) NSString * link;
@property (retain) NSString * title;
@property (retain) NSString * description;

@end
