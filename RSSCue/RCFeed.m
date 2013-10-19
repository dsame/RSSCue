//
//  RGFeed.m
//  RssGrowler
//
//  Created by Sergey Dolin on 10/9/13.
//  Copyright 2013 DSA. All rights reserved.
//

#import "RCFeed.h"


typedef enum {
	kNothingMet = 1,
	kHeaderMet = 2,
	kItemMet = 3
} METS;

typedef enum {
	kWaitForTitle=1,
	kWaitForDescription=2,
	kWaitForLink=3
} WAITS;

@implementation RCFeed
@synthesize url=_url;
@synthesize link=_link;
@synthesize title=_title;
@synthesize description=_description;
@synthesize items=_items;

#pragma mark Initialization

- (id)initWithURL:(NSURL *)aUrl {
	self=[self init];
	self.url=aUrl;
	_responseData = [NSMutableData new];
	return self;
}
+ (RCFeed *)feedWithURL:(NSURL *)aUrl {
	return [[RCFeed alloc] initWithURL:aUrl];
}

- (void)run{
	NSURLRequest *request = [NSURLRequest requestWithURL:_url];
	[[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];//TODO: segfault?
}

#pragma mark HTTP

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [_responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    //TODO: better handle
    [[NSAlert alertWithError:error] runModal];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSXMLParser * parser=[[[NSXMLParser alloc] initWithData:_responseData] autorelease];
    [_newItems release];
	_newItems=[NSMutableArray arrayWithCapacity:25];
	[parser setDelegate:self];
	[parser setShouldResolveExternalEntities:NO];
	_state=kNothingMet;
	[parser parse];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection
			 willSendRequest:(NSURLRequest *)request
			redirectResponse:(NSURLResponse *)redirectResponse
{
    [_url autorelease];
    _url = [[request URL] retain];//handle redirection
    return request;
}

#pragma mark XML

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {

	if (_state==kNothingMet){
		if ( [elementName isEqualToString:@"feed"]) {
			_isAtom=YES;
		}else if ( [elementName isEqualToString:@"rss"]) {
			_isAtom=NO;
		}else {
			NSAssert(FALSE,@"Strange element \"%@\" has been met. Only feed or rss expected",elementName);
		}
		_state=kHeaderMet;
	}else if (_state==kHeaderMet){
		if ( [elementName isEqualToString:@"title"]) {
			_waitFor=kWaitForTitle;
		}else if ( [elementName isEqualToString:@"description"]) {
			_waitFor=kWaitForDescription;
		}else if ( [elementName isEqualToString:@"link"]) {
			_waitFor=kWaitForLink;
		}else if ( [elementName isEqualToString:@"item"]) {
			if (_state==kItemMet){
				[_newItems addObject:_item];
			}
            [_item release];
			_item = [RGItem new];
			_state=kItemMet;
		}
	}else if (_state==kItemMet){
		if ( [elementName isEqualToString:@"title"]) {
			_waitFor=kWaitForTitle;
		}else if ( [elementName isEqualToString:@"description"]) {
			_waitFor=kWaitForDescription;
		}else if ( [elementName isEqualToString:@"link"]) {
			_waitFor=kWaitForLink;
		}
	}else {
		NSAssert(FALSE,@"Must not happen ever");
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	//NSLog(@"caracters: %@",string);
	if (_state==kHeaderMet){
		switch (_waitFor) {
			case kWaitForTitle:
				self.title=string;
				break;
			case kWaitForDescription:
				self.description=string;
				break;
			case kWaitForLink:
				self.link=string;				
				break;
			default:
				break;
		}
	}else if (_state==kItemMet) {
		switch (_waitFor) {
			case kWaitForTitle:
				self.title=string;
				break;
			case kWaitForDescription:
				self.description=string;
				break;
			case kWaitForLink:
				self.link=string;				
				break;
			default:
				break;
		}		
	}
}
- (void)parserDidEndDocument:(NSXMLParser *) parser{
	BOOL isModified=NO;
	if (_items==nil){
		isModified=YES;
	}else {
		isModified=[_items isEqualToArray:_newItems];
	}
	if (isModified) {
        [_items release]; 
		_items=_newItems;
		_newItems=nil;
	}
}

@end
