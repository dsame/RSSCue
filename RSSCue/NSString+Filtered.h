//
//  NSString+Filtered.h
//  RSSCue
//
//  Created by Sergey Dolin on 10/21/13.
//  Copyright (c) 2013 DSA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Filtered)
-(NSString *) flatternHTML;
-(NSString *) concatString:(NSString *)aString withLimit:(int)aLimit;
@end
