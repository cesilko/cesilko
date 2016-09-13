//
//  CSListParser.m
//  Ressourcenplanung
//
//  Created by Petr Homola on 8.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "LXListParser.h"

static NSMutableCharacterSet* specialCharacters;
static NSMutableCharacterSet* emptyCharacterSet;

@implementation LXListParser
+ (void)initialize {
	specialCharacters = [[NSMutableCharacterSet alloc] init];
	[specialCharacters addCharactersInString: @") \t\r\n"];
	emptyCharacterSet = [[NSMutableCharacterSet alloc] init];
}

- (id)initWithString:(NSString*)string {
	if (self = [super init]) {
		scanner = [[NSScanner alloc] initWithString: string];
		[scanner setCharactersToBeSkipped: emptyCharacterSet];
	}
	return self;
}

+ (id)listParserWithString:(NSString*)string {
	return [[[LXListParser alloc] initWithString: string] autorelease];
}

- (NSArray*)parse {
	return [self parse: YES];
}

- (NSArray*)parse:(BOOL)parseInitialBracket {
	NSMutableArray* result = [NSMutableArray arrayWithCapacity: 10];
	NSString* scanned;
	if (parseInitialBracket) {
		[scanner scanCharactersFromSet: [NSCharacterSet whitespaceAndNewlineCharacterSet] intoString: &scanned];
		BOOL parsed = [[scanner string] characterAtIndex: [scanner scanLocation]] == '(';
		if (!parsed) {
			NSLog(@"'(' expected");
			return nil;
		} else [scanner setScanLocation: [scanner scanLocation] + 1];
	}
	while (YES) {
		BOOL parsed = [scanner scanCharactersFromSet: [NSCharacterSet whitespaceAndNewlineCharacterSet] intoString: &scanned];
		parsed = [[scanner string] characterAtIndex: [scanner scanLocation]] == '(';
		if (parsed) {
			[scanner setScanLocation: [scanner scanLocation] + 1];
			NSArray* array = [self parse: NO];
			[result addObject: array];
			continue;
		}
		parsed = [scanner scanUpToCharactersFromSet: specialCharacters intoString: &scanned];
		if (!parsed) {
			[scanner scanCharactersFromSet: [NSCharacterSet whitespaceAndNewlineCharacterSet] intoString: &scanned];
			parsed = [[scanner string] characterAtIndex: [scanner scanLocation]] == ')';
			if (parsed) { [scanner setScanLocation: [scanner scanLocation] + 1]; break; }
			else {
				NSLog(@"identifier(s) or ')'");
				return nil;
			}
		}
		[result addObject: scanned];
	}
	return result;
}

- (void)dealloc {
	[scanner release];
	[super dealloc];
}
@end
