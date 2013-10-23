//
//  RGFeed.h
//  RssGrowler
//
//  Created by Sergey Dolin on 10/9/13.
//  Copyright 2013 DSA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RCFeedDelegate.h"
#import "RCItem.h"

typedef enum {
    kUndefined,
	kParserNothingMet,
	kParserHeaderMet,
	kParserImageMet,
	kParserItemMet,
    kParserError,
    kParserFinished,
    kHTTPsent,
    kHTTPresposne,
    kHTTPdata,
    kHTTPfail,
    kHTTPfinished,
    kFinished
} RC_FEED_STATE;


@interface RCFeed : NSObject<NSXMLParserDelegate> {
	NSMutableData * _responseData;	
	BOOL _isAtom;
    BOOL _inTag;
    BOOL _summary;
    BOOL _content;
	RC_FEED_STATE _state;
	int _waitFor;
    NSString * _uuid;
	
	NSMutableArray * _newItems;
	RCItem * _item;//current
}

@property (copy) NSString * link;
@property (copy) NSString * title;
@property (copy) NSString * description;
@property (assign) unsigned int reported;

@property (readonly) NSArray * items;
@property (readonly) NSError * error;
@property (readonly) NSString * name;
@property (readonly) NSString * uuid;
@property (retain) id <RCFeedDelegate> delegate;
@property (assign) RC_FEED_STATE state;
@property (readonly) NSString *type;
@property (retain) NSURL* effectiveURL;

- (id) initWithUUID:(NSString *)uuid andDelegate:(id<RCFeedDelegate>) delegate;

- (void) run;
- (void) makeUnreported;

- (NSMutableDictionary*) configuration;
@end
