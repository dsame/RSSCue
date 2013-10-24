//
//  NSString+Filtered.m
//  RSSCue
//
//  Created by Sergey Dolin on 10/21/13.
//  Copyright (c) 2013 DSA. All rights reserved.
//

#import "NSString+Filtered.h"

@implementation NSString (Filtered)

- (NSString *) flatternHTML
{
	NSString *result = self;
	
	if (![self isEqualToString:@""])	
	{
        //result=[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        NSArray* words = [self componentsSeparatedByCharactersInSet :[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        words = [words filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self <> ''"]];
        
        
        result = [[[[[[[[[words componentsJoinedByString:@" "] 
                         stringByReplacingOccurrencesOfString: @"&apos;" withString:@"'"]                  
                        stringByReplacingOccurrencesOfString: @"&dash;" withString:@"-"]                  
                       stringByReplacingOccurrencesOfString: @"&copy;" withString:@"©"]                  
                      stringByReplacingOccurrencesOfString: @"&lt;" withString:@"<"]                  
                     stringByReplacingOccurrencesOfString: @"&gt;" withString:@">"]                  
                    stringByReplacingOccurrencesOfString: @"&amp;" withString:@"&"]                  
                   stringByReplacingOccurrencesOfString: @"&nbsp;" withString:@" "]                  
                  stringByReplacingOccurrencesOfString: @"&quot;" withString:@"\""];
    }
	return result;
}
- (NSString *)concatString:(NSString *)aString withLimit:(int)aLimit{
    if (aString==nil) return self;
    if ([aString isEqualToString:@""]) return self;
    if (self.length>=aLimit) {
        return self;
    }
    if (self.length+aString.length>=aLimit) {
        return [NSString stringWithFormat:@"%@%@",self,[aString substringToIndex:(aLimit-self.length)]];
    }else{
        return [NSString stringWithFormat:@"%@%@",self,aString];         
    }
}

@end
