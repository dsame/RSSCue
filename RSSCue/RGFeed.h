//
//  RGFeed.h
//  RssGrowler
//
//  Created by Sergey Dolin on 10/9/13.
//  Copyright 2013 DSA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RGItem.h"


@interface RGFeed : NSObject<NSXMLParserDelegate> {

	
	NSURL * url;
	NSMutableData * responseData;
	
	NSString * title;
	NSString * link;
	NSString * description;
	NSDate * pubDate;
	
	BOOL isAtom;
	
	int state;
	int waitFor;
	
	NSMutableArray * newItems;
	NSArray * items;
	RGItem * item;//current
}

@property (retain) NSURL * url;
@property (retain) NSString * link;
@property (retain) NSString * title;
@property (retain) NSString * description;
@property (retain) NSArray * items;

- (id) initWithURL:(NSURL *)aUrl;
+ (RGFeed *) feedWithURL:(NSURL *)aUrl;

- (void) run;

@end
