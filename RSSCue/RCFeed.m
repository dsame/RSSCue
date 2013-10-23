//
//  RGFeed.m
//  RssGrowler
//
//  Created by Sergey Dolin on 10/9/13.
//  Copyright 2013 DSA. All rights reserved.
//

#import "RCFeed.h"
#import "NSString+Filtered.h"
#import "NSUserDefaults+FeedConfig.h"

typedef enum {
    kNoWait=0,
	kWaitForTitle=1,
	kWaitForDescription=2,
	kWaitForLink=3,
    kWaitForDate=4
} WAITS;

@interface RCFeed()  {    

}
@property (retain) NSMutableData* responseData;
@property (retain) NSURLConnection *connection;
@end

@implementation RCFeed
@synthesize link=_link;
@synthesize title=_title;
@synthesize uuid=_uuid;
@synthesize description=_description;
@synthesize items=_items;
@synthesize delegate=_delegate;
@synthesize error=_error;
@synthesize state=_state;
@synthesize effectiveURL=_effectiveURL;
@synthesize reported=_reported;
@synthesize responseData=_responseData;
@synthesize connection=_connection;


#pragma mark utilities and accessros

- (NSString *) type{
    if (_isAtom) return @"Atom"; else return @"RSS";
}

- (NSMutableDictionary*) configuration{
    NSMutableDictionary* c=[NSUserDefaults configForFeedByUUID:_uuid];
    NSAssert(c!=nil, @"There's no config for UUID=%@", _uuid);
    return c;
}

- (NSString *) name{
    return [self.configuration objectForKey:@"name"];
}


#pragma mark Initialization

- (id)initWithUUID:(NSString *)uuid andDelegate:(id<RCFeedDelegate>)delegate{
	self=[super init];
    self.title=@"";
    self.description=@"";
    self.delegate=delegate;
    _uuid=[uuid retain];
    _state=kUndefined;
	return self;
}

- (void)dealloc{
    [_delegate release];
    [_description release];
    [_effectiveURL release];
    [_error release];
    [_items release];
    [_link release];
    [_title release];
    [_uuid release];
    [super dealloc];
}
- (void)run{
    [_error release];
    _error=nil;
    NSDictionary * configuration=[self configuration];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[configuration valueForKey:@"url"]]];
    NSAssert(self.connection==nil, @"The previous connections was not freed, memory leak");
	_connection=[[NSURLConnection alloc] initWithRequest:request delegate:self];
   
    if (self.connection) {
        _state=kHTTPsent;
    }else{
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"Can not create a connection.",NSLocalizedDescriptionKey,
                                  nil];
        _error=[[NSError errorWithDomain:@"RSSCuew" code:_state userInfo:userInfo] retain];
        _state=kHTTPfail;
        self.connection=nil;
    }
    [_delegate feedStateChanged:self];
}

#pragma mark HTTP

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.responseData = [NSMutableData dataWithLength:0];
    _state=kHTTPresposne;
    [_delegate feedStateChanged:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
    _state=kHTTPdata;
    [_delegate feedStateChanged:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.responseData = nil;
    self.connection=nil;
    [_error release];
    _error=[error retain];
    _state=kHTTPfail;
    [_delegate feedFailed:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.connection=nil;
    _state=kHTTPfinished;
    [_delegate feedStateChanged:self];
       
    NSXMLParser * parser=[[[NSXMLParser alloc] initWithData:_responseData] autorelease];
	[parser setDelegate:self];
	[parser setShouldResolveExternalEntities:NO];
	_state=kParserNothingMet;
    _waitFor=kNoWait;
 
    
    NSAssert(_newItems==nil,@"_newItems must be nil on parse start");
    NSAssert(_item==nil,@"_item must be nil on parse start");
    _newItems=[[NSMutableArray arrayWithCapacity:25] retain];
    _item = [RCItem new];
    self.description=@"";
    self.title=@"";
    
    [_delegate feedStateChanged:self];
	[parser parse];
    self.responseData=nil;
    
    if (_state!=kParserError){
        
    NSError * pe=[parser parserError];
        if (pe!=nil){
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @"Feed is invalid",NSLocalizedDescriptionKey,
                                      [NSString stringWithFormat:@"The feed seems to be broken:\n\n%@",[pe localizedDescription],nil ],NSLocalizedRecoverySuggestionErrorKey,
                                      nil];
            _state=kParserError;
            [_error release];
            _error=[[NSError errorWithDomain:@"RSSCue" code:_state userInfo:userInfo] retain];        
        }
    }

    if (_state==kHTTPfail || _state==kParserError)
        [_delegate feedFailed:self];
    else
        [_delegate feedSuccess:self];
    [_newItems release];
    _newItems=nil;
    [_item release];
    _item=nil;    
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
    _inTag=NO;
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
            _error=[[NSError errorWithDomain:@"RSSCue" code:_state userInfo:userInfo] retain];
            return; //do not abort parsing in order to call releases on DidEnd
		}
		_state=kParserHeaderMet;
        [_delegate feedStateChanged:self];

	}else if (_state==kParserHeaderMet){
		if ( [elementName isEqualToString:@"title"]) {
			_waitFor=kWaitForTitle;
		}else if ( [elementName isEqualToString:@"description"] || [elementName isEqualToString:@"subtitle"]) {
			_waitFor=kWaitForDescription;
		}else if ( [elementName isEqualToString:@"link"]) {
            if (_isAtom){
                if (!_atomSelfLink || [[attributeDict objectForKey:@"rel"] isEqualToString:@"self"]){
                    if (!_atomSelfLink) _atomSelfLink=YES;
                    self.link=[attributeDict objectForKey:@"href"];
                    _waitFor=kNoWait;
                }
            }else
                _waitFor=kWaitForLink;
		}else if ( [elementName isEqualToString:@"image"]) {
			_state=kParserImageMet;
		}else if ( [elementName isEqualToString:@"item"]|| [elementName isEqualToString:@"entry"]) {
            _atomSummary=NO;
            _atomContent=NO;
            _atomSelfLink=NO;
            _state=kParserItemMet;
            [_delegate feedStateChanged:self];                            
		}
	}else if (_state==kParserItemMet){
		if ( [elementName isEqualToString:@"title"]) {
			_waitFor=kWaitForTitle;
		}else if (!_isAtom && [elementName isEqualToString:@"description"]) {
			_waitFor=kWaitForDescription;
		}else if (_isAtom && [elementName isEqualToString:@"summary"]) {
			_waitFor=kWaitForDescription;
            _atomSummary=YES;
            if (_atomContent){
                _item.description=@"";
            }
		}else if (_isAtom && !_atomSummary && [elementName isEqualToString:@"content"]) {
			_waitFor=kWaitForDescription;    
            _atomContent=YES;
		}else if ( [elementName isEqualToString:@"link"]) {
            if (_isAtom){
                _item.link=[attributeDict objectForKey:@"href"];
                _waitFor=kNoWait;
            }else
                _waitFor=kWaitForLink;
		}else if ( [elementName isEqualToString:@"pubDate"] || [elementName isEqualToString:@"updated"]) {
			_waitFor=kWaitForDate;
		}else if ( [elementName isEqualToString:@"item"]|| [elementName isEqualToString:@"entry"]) {
            [_newItems addObject:_item];
            [_item release];
			_item = [RCItem new];
		}else{
            _waitFor=kNoWait;
        }
    }else if (_state==kParserImageMet){
        if ( [elementName isEqualToString:@"item"]|| [elementName isEqualToString:@"entry"]) {
            _state=kParserItemMet;
            [_delegate feedStateChanged:self];                            
		}
	}else {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"Must never happen",NSLocalizedDescriptionKey,
                                   nil];
        _state=kParserError;
        [_error release];
        _error=[[NSError errorWithDomain:@"RSSCue" code:_state userInfo:userInfo] retain];

	}

}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if ([string isEqualToString:@"<"]){
        _inTag=YES; return;
    }
    if ([string isEqualToString:@">"]){
        _inTag=NO; return;
    }
    if (_inTag==YES) {
        return;
    };
	if (_state==kParserHeaderMet){
		switch (_waitFor) {
			case kWaitForTitle:
				self.title=[self.title concatString:[string flatternHTML] withLimit:128];
				break;
			case kWaitForDescription:
				self.description=[self.description concatString:[string flatternHTML] withLimit:256];
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
				_item.title=[_item.title concatString:[string flatternHTML] withLimit:128];
				break;
			case kWaitForDescription:
                _item.description=[_item.description concatString:[string flatternHTML] withLimit:200];
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
        _error=[[NSError errorWithDomain:@"RSSCue" code:_state userInfo:userInfo] retain];
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
}

-(void) makeUnreported{
    for (RCItem* i in _items){
        i.reported=NO;
    }
}

@end
