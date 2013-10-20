//
//  RGFeed.m
//  RssGrowler
//
//  Created by Sergey Dolin on 10/9/13.
//  Copyright 2013 DSA. All rights reserved.
//

#import "RCFeed.h"


typedef enum {
    kNoWait=0,
	kWaitForTitle=1,
	kWaitForDescription=2,
	kWaitForLink=3,
    kWaitForDate=4
} WAITS;

@implementation RCFeed
@synthesize link=_link;
@synthesize title=_title;
@synthesize description=_description;
@synthesize items=_items;
@synthesize delegate=_delegate;
@synthesize error=_error;
@synthesize state=_state;
@synthesize effectiveURL=_effectiveURL;

#pragma mark utilities and accessros

- (NSString *) type{
    if (_isAtom) return @"Atom"; else return @"RSS";
}

- (BOOL) isModified{
    return _isModified;
}
- (BOOL) modified{
    return _isModified;
}

- (NSString *) name{
    return [_configuration objectForKey:@"name"];
}

#pragma mark Initialization

- (id)initWithConfiguration:(NSDictionary *)config andDelegate:(id<RCFeedDelegate>)delegate{
	self=[super init];
    self.delegate=delegate;
    _state=kUndefined;
	_responseData = [NSMutableData new];
    _configuration = [config retain];
	return self;
}

- (void)run{
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[_configuration valueForKey:@"url"]]];
	NSURLConnection * connection=[[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];//TODO: segfault?
    if (connection) {
        _state=kHTTPsent;
        [_error release];
        _error=nil;
    }else{
        NSDictionary *userInfo = [[NSDictionary dictionaryWithObjectsAndKeys:
                                  @"Can not create a connection.",NSLocalizedDescriptionKey,
                                  nil] autorelease];
        [_error release];
        _error=[NSError errorWithDomain:@"RSSCuew" code:_state userInfo:userInfo];
        _state=kHTTPfail;
    }
    [_delegate feedStateChanged:self];
}

#pragma mark HTTP

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [_responseData setLength:0];
    _state=kHTTPresposne;
    [_delegate feedStateChanged:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_responseData appendData:data];
    _state=kHTTPdata;
    [_delegate feedStateChanged:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [_error release];
    _error=[error retain];
    _state=kHTTPfail;
    [_delegate feedFailed:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    _state=kHTTPfinished;
    [_delegate feedStateChanged:self];
    
	NSXMLParser * parser=[[[NSXMLParser alloc] initWithData:_responseData] autorelease];
	[parser setDelegate:self];
	[parser setShouldResolveExternalEntities:NO];
	_state=kParserNothingMet;
    [_delegate feedStateChanged:self];
	[parser parse];
    
    if (_state!=kParserError){
    NSError * pe=[parser parserError];
        if (pe!=nil){
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @"Feed is invalid",NSLocalizedDescriptionKey,
                                      [NSString stringWithFormat:@"The feed seems to be broken:\n\n%@",[pe localizedDescription],nil ],NSLocalizedRecoverySuggestionErrorKey,
                                      nil];
            _state=kParserError;
            [_error release];
            _error=[NSError errorWithDomain:@"RSSCue" code:_state userInfo:userInfo];        
        }
    }

    if (_state==kHTTPfail || _state==kParserError)
        [_delegate feedFailed:self];
    else
        [_delegate feedSuccess:self];
    _state=kFinished;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection
			 willSendRequest:(NSURLRequest *)request
			redirectResponse:(NSURLResponse *)redirectResponse
{
    self.effectiveURL = [request URL];//handle redirection
    return request;
}

#pragma mark XML

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {

    if (_state==kParserError){
        return;
    }else if (_state==kParserNothingMet){
		if ( [elementName isEqualToString:@"feed"]) {
			_isAtom=YES;
		}else if ( [elementName isEqualToString:@"rss"]) {
			_isAtom=NO;
		}else {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @"Feed is invalid",NSLocalizedDescriptionKey,
                                      [NSString stringWithFormat:@"The proper feed must contatin \"atom\" or \"feed\" as its first elemenet but \"%@\" has been met",elementName,nil ],NSLocalizedRecoverySuggestionErrorKey,
                                      nil];
            _state=kParserError;
            [_error release];
            _error=[NSError errorWithDomain:@"RSSCue" code:_state userInfo:userInfo];
            return;
		}
		_state=kParserHeaderMet;
        [_delegate feedStateChanged:self];
	}else if (_state==kParserHeaderMet){
		if ( [elementName isEqualToString:@"title"]) {
			_waitFor=kWaitForTitle;
		}else if ( [elementName isEqualToString:@"description"]) {
			_waitFor=kWaitForDescription;
		}else if ( [elementName isEqualToString:@"link"]) {
			_waitFor=kWaitForLink;
		}else if ( [elementName isEqualToString:@"item"]) {
            NSAssert(_newItems==nil,@"_newItems must be nill on parse start");
            _newItems=[[NSMutableArray arrayWithCapacity:25] retain];
            _state=kParserItemMet;
			_item = [RCItem new];
            [_delegate feedStateChanged:self];                            
		}
	}else if (_state==kParserItemMet){
		if ( [elementName isEqualToString:@"title"]) {
			_waitFor=kWaitForTitle;
		}else if ( [elementName isEqualToString:@"description"]) {
			_waitFor=kWaitForDescription;
		}else if ( [elementName isEqualToString:@"link"]) {
			_waitFor=kWaitForLink;
		}else if ( [elementName isEqualToString:@"pubDate"]) {
			_waitFor=kWaitForDate;
		}else if ( [elementName isEqualToString:@"item"]) {
            [_newItems addObject:_item];
            [_item release];
			_item = [RCItem new];
		}
	}else {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"Must never happen",NSLocalizedDescriptionKey,
                                   nil];
        _state=kParserError;
        [_error release];
        _error=[NSError errorWithDomain:@"RSSCue" code:_state userInfo:userInfo];

	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if (_state==kParserHeaderMet){
		switch (_waitFor) {
			case kWaitForTitle:
				self.title=string;_waitFor=kNoWait;
				break;
			case kWaitForDescription:
				self.description=string;_waitFor=kNoWait;
				break;
			case kWaitForLink:
				self.link=string;_waitFor=kNoWait;
				break;
			default:
				break;
		}
	}else if (_state==kParserItemMet) {
		switch (_waitFor) {
			case kWaitForTitle:
				_item.title=string;_waitFor=kNoWait;
				break;
			case kWaitForDescription:
				_item.description=string;_waitFor=kNoWait;
				break;
			case kWaitForLink:
				_item.link=string;_waitFor=kNoWait;
				break;
			case kWaitForDate:
				_item.date=[NSDate dateWithString:string];_waitFor=kNoWait;
				break;
			default:
				break;
		}		
	}
}
- (void)parserDidEndDocument:(NSXMLParser *) parser{
    
    if (_state==kParserNothingMet) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"Feed is invalid",NSLocalizedDescriptionKey,
                                  @"Feed seems to be empty",NSLocalizedRecoverySuggestionErrorKey,
                                  nil];
        _state=kParserError;
        [_error release];
        _error=[NSError errorWithDomain:@"RSSCue" code:_state userInfo:userInfo];
    }
    
    if (_state==kParserError){
        [_items release]; 
		_items=nil;
    }else{
        if (_items==nil){
            _items=[_newItems retain];
        }else {            
            NSMutableArray *result=[NSMutableArray arrayWithCapacity:[_newItems count]];
            BOOL exists;
            for (RCItem *i in _newItems){
                exists=NO;
                for (RCItem *ii in _items){
                    if ([i isSameAs:ii]){
                        [result addObject:ii];
                        exists=YES;
                        break;
                    }
                }
                if (!exists){
                    [result addObject:i];
                }
                
            }
            [_items release];
            _items=[result retain];
        }
        _state=kParserFinished;
        [_delegate feedStateChanged:self];
    }
    [_newItems release];
    _newItems=nil;
}

@end
