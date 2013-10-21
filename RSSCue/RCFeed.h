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
    kUndefined = 0,
	kParserNothingMet = 1,
	kParserHeaderMet = 2,
	kParserItemMet = 3,
    kParserError = 4,
    kParserFinished = 5,
    kHTTPsent = 6,
    kHTTPresposne = 7,
    kHTTPdata = 8,
    kHTTPfail = 9,
    kHTTPfinished = 10,
    kFinished = 11
} RC_FEED_STATE;


@interface RCFeed : NSObject<NSXMLParserDelegate> {
	NSMutableData * _responseData;	
	BOOL _isAtom;
    BOOL _isModified;
    BOOL _inTag;
	RC_FEED_STATE _state;
	int _waitFor;
	
	NSMutableArray * _newItems;
	RCItem * _item;//current
}

@property (copy) NSString * link;
@property (copy) NSString * title;
@property (copy) NSString * description;
@property (readonly) NSArray * items;
@property (readonly) NSError * error;
@property (readonly) NSString * name;
@property (readonly) NSDictionary *configuration;
@property (readonly,assign) BOOL modified;
@property (retain) id <RCFeedDelegate> delegate;
@property (assign) RC_FEED_STATE state;
@property (readonly) NSString *type;
@property (retain) NSURL* effectiveURL;

- (id) initWithConfiguration:(NSDictionary *)config andDelegate:(id<RCFeedDelegate>) delegate;

- (void) run;
- (void) makeUnreported;

@end
