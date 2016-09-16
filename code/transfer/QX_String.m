//
//  QX_String.m
//

#import "QX_String.h"

@implementation NSString (QXString)

+ (NSString*)stringWithArray:(NSArray*)array {
	return [self stringWithArray: array omit: nil];
}

+ (NSString*)stringWithArray:(NSArray*)array omit:(NSString*)omit {
	NSCharacterSet* leftTight = [NSCharacterSet characterSetWithCharactersInString: @"([{\'\"<„"];
	NSCharacterSet* rightTight = [NSCharacterSet characterSetWithCharactersInString: @",.;:)]}\'\">“!?"];
	NSMutableString* string = [NSMutableString string];
	NSEnumerator* enumerator = [array objectEnumerator];
	id obj; unichar prev = 0, curr;
	while ((obj = [enumerator nextObject])) {
		if ([obj isEqual: omit]) continue;
		if ([obj length] == 1) curr = [obj characterAtIndex: 0]; else curr = 0;
		if ((prev == 0 || ![leftTight characterIsMember: prev]) && (curr == 0 || ![rightTight characterIsMember: curr]))
			[string appendString: @" "];
		[string appendFormat: @"%@", obj];
		prev = curr;
	}
	return [string trim];
}

- (NSString*)plainAsciiString {
	static NSString* specChars  = @"йцукенгшщзхъфывапролджэёячсмитьбю";
	static NSString* asciiChars = @"jcukengs#yx\"fyvaproldzeeacsmit\'bu";
	NSMutableString* result = [NSMutableString string];
	int i;
	for (i = 0; i < self.length; i++) {
		NSString* chr = [self substringWithRange: NSMakeRange(i, 1)];
		NSRange range = [specChars rangeOfString: chr];
		if (range.location != NSNotFound)
			chr = [asciiChars substringWithRange: NSMakeRange(range.location, 1)];
		[result appendString: chr];
	}
	return result;
}

- (NSString*)trim {
	if ([self isEqual: @""]) return @"";
	// unsigned zpusobuje chybu v gnustepu
	unsigned pos = 0;
	while (pos < self.length
	  && [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember: [self characterAtIndex: pos]])
		pos++;
	NSString* tmp = [self substringFromIndex: pos];
	pos = tmp.length - 1;
	while (pos >= 0
	  && [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember: [tmp characterAtIndex: pos]])
		pos--;
	return [tmp substringToIndex: pos + 1];
}

- (NSArray*)tokenizeHomogenous:(BOOL)homogenous {
	id tokens = [self tokenize];
	if (homogenous) {
		NSEnumerator* enumerator = [tokens objectEnumerator];
		tokens = [NSMutableArray arrayWithCapacity: [tokens count]];
		NSString* token;
		while (token = [enumerator nextObject]) {
			if (token.length == 0) continue;
			BOOL wasDigit = ![[NSCharacterSet decimalDigitCharacterSet] characterIsMember: [token characterAtIndex: 0]];
			NSMutableString* smallToken = nil;
			unsigned i;
			for (i = 0; i < token.length; i++) {
				BOOL isDigit = [[NSCharacterSet decimalDigitCharacterSet] characterIsMember: [token characterAtIndex: i]];
				if (wasDigit != isDigit) {
					wasDigit = isDigit;
					if (smallToken != nil) [tokens addObject: smallToken];
					smallToken = [NSMutableString string];
				}
				[smallToken appendString: [token substringWithRange: NSMakeRange(i, 1)]];
			}
			[tokens addObject: smallToken];
			//NSLog(@"small token: %@", smallToken);
		}
	}
	return tokens;
}

- (NSArray*)tokenize {
	NSCharacterSet* marginalCharacters = [NSCharacterSet characterSetWithCharactersInString: @",.;:()[]{}\'\"<>„“!?"];
	NSCharacterSet* internalCharacters = [NSCharacterSet characterSetWithCharactersInString: @"-/+*.,\\\'"];
	NSCharacterSet* colonCharacter = [NSCharacterSet characterSetWithCharactersInString: @":"];
	NSMutableArray* tokens = [NSMutableArray arrayWithCapacity: self.length];
	id rawTokens = [self split];
	NSEnumerator* enumerator = [rawTokens objectEnumerator];
	NSString* rawToken;
	rawTokens = [NSMutableArray array];
	while (rawToken = [enumerator nextObject]) {
		NSArray* segments = [rawToken splitBy: colonCharacter];
		//NSLog(@"########## %@", segments);
		NSEnumerator* enumerator2 = [segments objectEnumerator];
		NSString* segment; BOOL first = YES;
		while ((segment = [enumerator2 nextObject])) {
			if (first) first = NO; else [rawTokens addObject: @":"];
			[rawTokens addObject: segment];
		}
	}
	enumerator = [rawTokens objectEnumerator];
	while (rawToken = [enumerator nextObject]) {
		if (rawToken.length == 1) {
			[tokens addObject: rawToken];
			continue;
		}
		NSRange range = [rawToken rangeOfString: @"."];
		if (range.location != NSNotFound) {
			//NSLog(@"########## %@ %u %u", rawToken, range.location, NSNotFound);
			[tokens addObject: [rawToken substringToIndex: range.location]];
			[tokens addObject: @"."];
			[tokens addObject: [rawToken substringFromIndex: range.location + 1]];
			continue;
		}
		unsigned from = 0, to = rawToken.length;
		if (to == 0) continue;
		unichar c = [rawToken characterAtIndex: from];
		if ([marginalCharacters characterIsMember: c]) {
			NSString* token = [NSString stringWithCharacters: &c length: 1];
			[tokens addObject: token];
			from++;
		}
		NSMutableArray* followingTokens = [NSMutableArray array];
		c = [rawToken characterAtIndex: to - 1];
		while ([marginalCharacters characterIsMember: c]) {
			NSString* followingToken = [NSString stringWithCharacters: &c length: 1];
			[followingTokens addObject: followingToken];
			to--;
			c = [rawToken characterAtIndex: to - 1];
		}
		//NSLog(@"'%@' -- '%@' %u %u", self, rawToken, from, to);
		if (from >= to) [tokens addObject: rawToken];
		else [tokens addObject: [rawToken substringWithRange: NSMakeRange(from, to - from)]];
		if (followingTokens.count > 0) [tokens addObjectsFromArray: followingTokens];
	}
	enumerator = [tokens objectEnumerator];
	tokens = [NSMutableArray arrayWithCapacity: self.length];
	while (rawToken = [enumerator nextObject]) {
		[tokens addObjectsFromArray: [rawToken splitBy: internalCharacters keepSeparators: YES]];
		/*NSRange range = [rawToken rangeOfString: @"-"];
		if (range.location == NSNotFound) [tokens addObject: rawToken];
		else {
			[tokens addObject: [rawToken substringToIndex: range.location]];
			[tokens addObject: @"-"];
			[tokens addObject: [rawToken substringFromIndex: range.location + 1]];
		}*/
	}
	return tokens;
}

- (NSArray*)split {
	return [self splitBy: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSArray*)splitBy:(NSCharacterSet*)separators {
	return [self splitBy: separators keepSeparators: NO];
}

- (NSArray*)splitBy:(NSCharacterSet*)separators keepSeparators:(BOOL)keepSeparators {
	NSMutableArray* array = [NSMutableArray arrayWithCapacity: self.length];
	if (self.length == 0) return array;
	unsigned pos = 0, i;
	for (i = 1; i < self.length; i++) {
		if ([separators characterIsMember: [self characterAtIndex: i]]) {
			NSString* token = [[self substringWithRange: NSMakeRange(pos, i - pos)] trim];
			/*if ([token length] > 0)*/ [array addObject: token];
			if (keepSeparators) [array addObject: [self substringWithRange: NSMakeRange(i, 1)]];
			pos = i + 1;
		}
	}
	//NSLog(@"%u %u '%@'", pos, i, self);
	@try {
		NSString* token = [[self substringWithRange: NSMakeRange(pos, i - pos)] trim];
		/*if ([token length] > 0)*/ [array addObject: token];
	} @catch (NSException* exception) {
		NSLog(@"%u %u '%@'", pos, i, self);
		exit(1);
	}
	return array;
}

- (NSString*)capitalize {
	if (self.length > 0) return [[self substringWithRange: NSMakeRange(0, 1)].capitalizedString stringByAppendingString: [self substringFromIndex: 1]];
	else return self;
}

- (NSString*)decapitalize {
	if (self.length > 0) return [[self substringWithRange: NSMakeRange(0, 1)].lowercaseString stringByAppendingString: [self substringFromIndex: 1]];
	else return self;
}

- (NSString*)lowercaseAndCapitalized {
	if (self.length > 0) return [[self substringWithRange: NSMakeRange(0, 1)].capitalizedString stringByAppendingString: [self substringFromIndex: 1].lowercaseString];
	else return self;
}

- (BOOL)isInteger {
	int i;
	for (i = 0; i < self.length; i++) {
		unichar chr = [self characterAtIndex: i];
		if (chr < '0' || chr > '9') return NO;
	}
	return YES;
}

+ (NSString*)completize:(NSArray*)array {
	NSCharacterSet* leftSigns = [NSCharacterSet characterSetWithCharactersInString: @"([{<"];
	NSCharacterSet* rightSigns = [NSCharacterSet characterSetWithCharactersInString: @")]}>,.;:!?"];
	NSMutableString* result = [[NSMutableString alloc] init];
	NSEnumerator* enumerator = [array objectEnumerator];
	NSArray* forms; BOOL precedingSpace = NO;
	while (forms = [enumerator nextObject]) {
		//if ([forms count] > 1) NSLog(@"more form variants available: %@", [forms description]);
		// let's take the shortest form for the morph. output
		NSEnumerator* enumerator2 = [forms objectEnumerator];
		NSString *form = nil, *el; unsigned minLength = UINT_MAX;
		while ((el = [enumerator2 nextObject])) {
			if (minLength > el.length) {
				minLength = el.length;
				form = el;
			}
		}
		//NSLog(@"completizing: %@", array);
		if (form != nil) {
			if (precedingSpace && ![rightSigns characterIsMember: [form characterAtIndex: 0]]) [result appendString: @" "];
			[result appendString: form];
			if ([leftSigns characterIsMember: [form characterAtIndex: 0]]) precedingSpace = NO; else precedingSpace = YES;
		}
	}
	//NSLog(@"########## %@", result);
	
	// joining words by ≈≈
	//[result replaceOccurrencesOfString: @"≈≈ " withString: @"" options: 0 range: NSMakeRange(0, [result length])];
	[result appendString: @"  "];
	NSMutableString* result2 = [NSMutableString string];
	NSMutableString* lastWord = [NSMutableString string];
	NSString *prevChar = nil, *currChar; unsigned lastWordPos = 0, i;
	for (i = 0; i < result.length; i++) {
		currChar = [result substringWithRange: NSMakeRange(i, 1)];
		if ([prevChar isEqual: @" "] || [prevChar isEqual: @"("]) {
			lastWordPos = i;
			[result2 appendString: lastWord];
			lastWord = [NSMutableString string];
		}
		if ([prevChar isEqual: @"≈"] && [currChar isEqual: @"≈"]) {
			NSString* prefix = [lastWord substringToIndex: lastWord.length - 1];
			NSString* tmp = [result substringWithRange: NSMakeRange(i + 2, 1)];
			if ([tmp isEqual: [tmp capitalize]]) {
				[result2 appendString: [prefix capitalize]];
				lastWord = [NSMutableString string];
				[lastWord appendString: tmp.lowercaseString];
			} else {
				[result2 appendString: prefix];
				lastWord = [NSMutableString string];
				[lastWord appendString: tmp];
			}
			i += 2;
			currChar = @" ";
		} else [lastWord appendString: currChar];
		prevChar = currChar;
	}
	return [result2 trim];
}

@end

@implementation NSMutableString (QXString)

- (unsigned)_replaceOccurrencesOfString:(NSString*)target withString:(NSString*)replacement options:(unsigned)opts range:(NSRange)searchRange {
	unsigned count = 0;
	while (YES) {
		NSRange range = [self rangeOfString: target options: opts range: searchRange];
		if (range.location == NSNotFound) break;
		[self deleteCharactersInRange: range];
		[self insertString: replacement atIndex: range.location];
		count++;
	}
	return count;
}

@end
