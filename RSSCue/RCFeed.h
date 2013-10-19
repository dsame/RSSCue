//
//  RGFeed.h
//  RssGrowler
//
//  Created by Sergey Dolin on 10/9/13.
//  Copyright 2013 DSA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RGItem.h"


@interface RCFeed : NSObject<NSXMLParserDelegate> {
	NSMutableData * _responseData;	
	BOOL _isAtom;
	int _state;
	int _waitFor;
	
	NSMutableArray * _newItems;
	RGItem * _item;//current
}

@property (copy) NSURL * url;
@property (copy) NSString * link;
@property (copy) NSString * title;
@property (copy) NSString * description;
@property (copy) NSArray * items;

- (id) initWithURL:(NSURL *)aUrl;
+ (RCFeed *) feedWithURL:(NSURL *)aUrl;

- (void) run;

@end
