//
//  RGFeed.m
//  RssGrowler
//
//  Created by Sergey Dolin on 10/9/13.
//  Copyright 2013 DSA. All rights reserved.
//

#import "RGFeed.h"


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

@implementation RGFeed
@synthesize url;
@synthesize link;
@synthesize title;
@synthesize description;
@synthesize items;

- (id)initWithURL:(NSURL *)aUrl {
	self=[self init];
	url=[aUrl retain];
	responseData = [NSMutableData new];
	return self;
}
+ (RGFeed *)feedWithURL:(NSURL *)aUrl {
	return [[RGFeed alloc] initWithURL:aUrl];
}

- (void)run{
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	[[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
}

// HTTP
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[NSAlert alertWithError:error] runModal];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSXMLParser * parser=[[NSXMLParser alloc] initWithData:responseData];
	state=kNothingMet;
	newItems=[NSMutableArray arrayWithCapacity:25];
	[parser setDelegate:self];
	[parser setShouldResolveExternalEntities:NO];
	[parser parse];
}
- (NSURLRequest *)connection:(NSURLConnection *)connection
			 willSendRequest:(NSURLRequest *)request
			redirectResponse:(NSURLResponse *)redirectResponse
{
    [url autorelease];
    url = [[request URL] retain];
    return request;
}
// XML
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	//NSLog(@"elementName: %@",elementName);
	if (state==kNothingMet){
		if ( [elementName isEqualToString:@"feed"]) {
			isAtom=YES;
		}else if ( [elementName isEqualToString:@"rss"]) {
			isAtom=NO;
		}else {
			NSAssert(FALSE,@"Strange element \"%@\" has been met. Only feed or rss expected",elementName);
		}
		state=kHeaderMet;
	}else if (state==kHeaderMet){
		if ( [elementName isEqualToString:@"title"]) {
			waitFor=kWaitForTitle;
		}else if ( [elementName isEqualToString:@"description"]) {
			waitFor=kWaitForDescription;
		}else if ( [elementName isEqualToString:@"link"]) {
			waitFor=kWaitForLink;
		}else if ( [elementName isEqualToString:@"item"]) {
			if (state==kItemMet){
				[newItems addObject:item];
			}
			item = [RGItem new];
			state=kItemMet;
		}
	}else if (state==kItemMet){
		if ( [elementName isEqualToString:@"title"]) {
			waitFor=kWaitForTitle;
		}else if ( [elementName isEqualToString:@"description"]) {
			waitFor=kWaitForDescription;
		}else if ( [elementName isEqualToString:@"link"]) {
			waitFor=kWaitForLink;
		}
	}else {
		NSAssert(FALSE,@"Must not happen ever");
	}
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	//NSLog(@"caracters: %@",string);
	if (state==kHeaderMet){
		switch (waitFor) {
			case kWaitForTitle:
				title=string;
				break;
			case kWaitForDescription:
				description=string;
				break;
			case kWaitForLink:
				link=string;				
				break;
			default:
				break;
		}
	}else if (state==kItemMet) {
		switch (waitFor) {
			case kWaitForTitle:
				title=string;
				break;
			case kWaitForDescription:
				description=string;
				break;
			case kWaitForLink:
				link=string;				
				break;
			default:
				break;
		}		
	}
}
- (void)parserDidEndDocument:(NSXMLParser *) parser{
	BOOL isModified=NO;
	if (items==nil){
		isModified=YES;
	}else {
		isModified=[items isEqualToArray:newItems];
	}
	if (isModified) {
		items=newItems;
		newItems=nil;
	}
	//NSLog(@"Modified: %@",isModified);
}

@end
