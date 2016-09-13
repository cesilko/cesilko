//
//  CSListParser.h
//  Ressourcenplanung
//
//  Created by Petr Homola on 8.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>

// parser pro s-vyrazy

@interface LXListParser : NSObject {
	NSScanner* scanner;
}
- (id)initWithString:(NSString*)string;
+ (id)listParserWithString:(NSString*)string;
- (NSArray*)parse;
- (NSArray*)parse:(BOOL)parseInitialBracket;
@end
