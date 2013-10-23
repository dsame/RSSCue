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
    BOOL _atomSummary;
    BOOL _atomContent;
    BOOL _atomSelfLink;
	RC_FEED_STATE _state;
	int _waitFor;
	NSMutableArray * _newItems;
	RCItem * _item;//current
    NSURLConnection * _connection;
    
    NSString * _uuid;
    NSString *_link;
	NSString *_title;
    NSString *_description;
    NSArray *_items;
    NSError *_error;
    NSURL *_effectiveURL;
    id <RCFeedDelegate> _delegate;
    unsigned int _reported;
}

@property (copy) NSString * link;
@property (copy) NSString * title;
@property (copy) NSString * description;
@property (assign) unsigned int reported;
@property (readonly) NSString *type;
@property (retain) NSURL* effectiveURL;
@property (readonly) NSArray * items;
@property (readonly) NSError * error;
@property (readonly) NSString * name;
@property (readonly) NSString * uuid;
@property (retain) id <RCFeedDelegate> delegate;
@property (assign) RC_FEED_STATE state;


- (id) initWithUUID:(NSString *)uuid andDelegate:(id<RCFeedDelegate>) delegate;

- (void) run;
- (void) makeUnreported;

- (NSMutableDictionary*) configuration;
@end
