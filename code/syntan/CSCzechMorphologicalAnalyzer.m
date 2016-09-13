//
//  CzechMorphologicalAnalyzer.m
//  CzSk
//
//  Created by Petr Homola on 21.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CSCzechMorphologicalAnalyzer.h"
#import "QX_String.h"

#define PREFIX_NE		1
#define PREFIX_NEJ		2

@implementation CSCzechMorphologicalAnalyzer
- (id)init {
	if (self = [super init]) {
		[self load];
	}
	return self;
}

- (id)initWithParameters:(NSDictionary*)params {
	if (self = [super init]) {
		parameters = [params retain];
		[self load];
	}
	return self;
}

- (void)dealloc {
	[prefixes release];
	[paradigms release];
	[tagMap release];
	[super dealloc];
}

- (void)load {
	prefixes = [[NSMutableDictionary alloc] init];
	paradigms = [[NSMutableDictionary alloc] init];
	tagMap = [[NSMutableDictionary alloc] init];
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString: @"|"];
	
	NSString* fileName = parameters != nil ? [parameters objectForKey: @"file"] : @"/Users_XXX/phomola/dev/data/czm.il2.utf8";
	FILE* file = fopen([fileName UTF8String], "r");
	char line[1000]; //int n = 0;
	while (fgets(line, 1000, file) != NULL) {
		//if (++n % 1000 == 0) NSLog(@"%d", n);
		if (line[0] == 'R') {
			NSArray* array = [[NSString stringWithUTF8String: line] splitBy: separators];
			NSString* paradigm = [array objectAtIndex: 1];
			NSString* prefix = [[array objectAtIndex: 2] lowercaseString];
			NSString* lemma = [[array objectAtIndex: 3] lowercaseString];
			id tagset = [array objectAtIndex: 4];
			if ([tagset isEqual: @"0"]) tagset = [NSNull null];
			else {
				id longTagset = [array objectAtIndex: 5];
				//if ([tagMap objectForKey: longTagset] != nil && ![[tagMap objectForKey: longTagset] isEqual: tagset]) NSLog(@"!!!");
				[tagMap setObject: tagset forKey: longTagset];
			}
			NSMutableArray* info = [prefixes objectForKey: prefix];
			if (info == nil) {
				info = [NSMutableArray array];
				[prefixes setObject: info forKey: prefix];
			}
			[info addObject: [NSArray arrayWithObjects: paradigm, lemma, tagset, nil]];
		} else if (line[0] == 'E') {
			NSArray* array = [[NSString stringWithUTF8String: line] splitBy: separators];
			NSString* paradigm = [array objectAtIndex: 1];
			id ending = [array objectAtIndex: 4];
			if ([ending isEqual: @"0"]) ending = [NSNull null];
			NSString* tagset = [array objectAtIndex: 5];
			id longTagset = [array objectAtIndex: 6];
			//if ([tagMap objectForKey: longTagset] != nil && ![[tagMap objectForKey: longTagset] isEqual: tagset]) NSLog(@"!!!");
			[tagMap setObject: tagset forKey: longTagset];
			//if ([longTagset rangeOfString: @"NNFP4-"].location == 0) NSLog(@"OK: %@", longTagset);
			NSMutableArray* info = [paradigms objectForKey: paradigm];
			if (info == nil) {
				info = [NSMutableArray array];
				[paradigms setObject: info forKey: paradigm];
			}
			[info addObject: [NSArray arrayWithObjects: ending, tagset, nil]];
		}
	}
	fclose(file);
	[pool release];
}

- (void)enrich:(NSMutableDictionary*)dict {
	NSString* tags = [dict objectForKey: @"tags"];
	if ([tags isEqual: @"UNKNOWN"]) {
		[dict setObject: @"unknown" forKey: @"type"];
		[dict setObject: @"unknown" forKey: @"pos"];
		return;
	}
	// negace
	if ([tags rangeOfString: @"_N"].location == [tags length] - 2) {
		[dict setObject: @"1" forKey: @"negation"];
	}
	unichar pos = [tags characterAtIndex: 0];
	//NSLog(@"---- %@ %@", [dict objectForKey: @"lemma"], tags);
	switch (pos) {
		case 'D':
			if ([tags length] > 2) [self addDegree: [tags characterAtIndex: 2] toDictionary: dict];
			if ([tags length] > 3) [self addNegation: [tags characterAtIndex: 3] toDictionary: dict];
			[dict setObject: @"word" forKey: @"type"];
			[dict setObject: @"adv" forKey: @"pos"];
			break;
		case 'T':
			[dict setObject: @"word" forKey: @"type"];
			[dict setObject: @"part" forKey: @"pos"];
			break;
		case 'J':
			[dict setObject: @"word" forKey: @"type"];
			[dict setObject: @"conj" forKey: @"pos"];
			break;
		case 'R':
			[dict setObject: @"word" forKey: @"type"];
			[dict setObject: @"prep" forKey: @"pos"];
			if ([tags length] == 2) [self addCase: [tags characterAtIndex: 1] toDictionary: dict];
			else [self addCase: [tags characterAtIndex: 2] toDictionary: dict];
			break;
		case 'N':
			[dict setObject: @"word" forKey: @"type"];
			[dict setObject: @"n" forKey: @"pos"];
			[self addGender: [tags characterAtIndex: 1] toDictionary: dict];
			[self addNumber: [tags characterAtIndex: 2] toDictionary: dict];
			[self addCase: [tags characterAtIndex: 3] toDictionary: dict];
			break;
		case 'P':
			[dict setObject: @"word" forKey: @"type"];
			[dict setObject: @"pron" forKey: @"pos"];
			if ([tags characterAtIndex: 1] == 'R') {
				if ([tags characterAtIndex: 2] == 'C') { // reflexive pronoun
					[self addCase: [tags characterAtIndex: 4] toDictionary: dict];
					[dict setObject: @"refl" forKey: @"prontype"];
				} else if ([tags characterAtIndex: 2] == 'X') { // long reflexive pronoun (e.g. sebe)
					[dict setObject: @"long_refl" forKey: @"prontype"];
					[self addCase: [tags characterAtIndex: 3] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == 'S') { // reflexive possessive pronoun
					[dict setObject: @"poss" forKey: @"prontype"];
					[dict setObject: @"refl" forKey: @"person"];
					[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 4] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 5] toDictionary: dict];
				} else { NSLog(@"unknown pron subsubtype"); NSLog(@"---- %@ %@ %@", [dict objectForKey: @"form"], [dict objectForKey: @"lemma"], tags); exit(1); }
			} else if ([tags characterAtIndex: 1] == 'I') {
				if ([tags characterAtIndex: 2] == 'F') { // některý
					[dict setObject: @"indef" forKey: @"prontype"];
					[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 4] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 5] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == 'C') { // něco
					[dict setObject: @"indef" forKey: @"prontype"];
					[self addCase: [tags characterAtIndex: 3] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == 'K') { // někdo
					[dict setObject: @"indef" forKey: @"prontype"];
					[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 4] toDictionary: dict];
				} else { NSLog(@"unknown pron subsubtype"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			} else if ([tags characterAtIndex: 1] == 'A') {
				if ([tags characterAtIndex: 2] == 'E') {
					[dict setObject: @"rel" forKey: @"prontype"];
					[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 4] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 5] toDictionary: dict];
				} else { NSLog(@"unknown pron subsubtype"); NSLog(@"---- %@ %@", [dict objectForKey: @"lemma"], tags); exit(1); }
			} else if ([tags characterAtIndex: 1] == 'Q') {
				if ([tags characterAtIndex: 2] == 'F') {
					[dict setObject: @"rel" forKey: @"prontype"];
					[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 4] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 5] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == 'C') {
					[dict setObject: @"interr" forKey: @"prontype"];
					[self addCase: [tags characterAtIndex: 3] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == 'K') {
					[dict setObject: @"interr" forKey: @"prontype"];
					[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 4] toDictionary: dict];
				} else { NSLog(@"unknown pron subsubtype"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			} else if ([tags characterAtIndex: 1] == 'P') {
				if ([tags characterAtIndex: 2] == '3' && [tags characterAtIndex: 3] == 'R') {
					[dict setObject: @"pers" forKey: @"prontype"];
					[dict setObject: @"prep" forKey: @"pronsubtype"];
					[dict setObject: @"3" forKey: @"person"];
					[self addGender: [tags characterAtIndex: 4] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 5] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 6] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == '3') {
					[dict setObject: @"pers" forKey: @"prontype"];
					[dict setObject: @"3" forKey: @"person"];
					[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 4] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 5] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == '1') {
					[dict setObject: @"pers" forKey: @"prontype"];
					[dict setObject: @"1" forKey: @"person"];
					int delta = 0;
					BOOL enclitical = [tags characterAtIndex: 3] == 'C';
					if (enclitical) {
						[dict setObject: @"1" forKey: @"encl"];
						delta = 1;
					}
					[self addNumber: [tags characterAtIndex: 3 + delta] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 4 + delta] toDictionary: dict];
				} else { NSLog(@"unknown pron subsubtype"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			} else if ([tags characterAtIndex: 1] == 'S') {
				if ([tags characterAtIndex: 2] == '1') {
					[dict setObject: @"poss" forKey: @"prontype"];
					[dict setObject: @"1" forKey: @"person"];
					[self addPronNumber: [tags characterAtIndex: 3] toDictionary: dict];
					[self addGender: [tags characterAtIndex: 4] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 5] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 6] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == '3') {
					[dict setObject: @"poss" forKey: @"prontype"];
					[dict setObject: @"3" forKey: @"person"];
					[self addPronGender: [tags characterAtIndex: 3] toDictionary: dict];
					[self addPronNumber: [tags characterAtIndex: 4] toDictionary: dict];
					[self addGender: [tags characterAtIndex: 5] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 6] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 7] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == 'E') {
					[dict setObject: @"poss_rel" forKey: @"prontype"];
					[self addPronNumber: [tags characterAtIndex: 4] toDictionary: dict];
					[self addGender: [tags characterAtIndex: 5] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 6] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 7] toDictionary: dict];
				} else { NSLog(@"unknown pron subsubtype"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			} else if ([tags characterAtIndex: 1] == 'N') {
				if ([tags characterAtIndex: 2] == 'F') {
					[dict setObject: @"neg" forKey: @"prontype"]; // žádný
					[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 4] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 5] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == 'C') { // nic
					[dict setObject: @"neg" forKey: @"prontype"];
					[self addCase: [tags characterAtIndex: 3] toDictionary: dict];
				} else { NSLog(@"unknown pron subsubtype"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			} else if ([tags characterAtIndex: 1] == 'D') {
				[dict setObject: @"dem" forKey: @"prontype"];
				[self addGender: [tags characterAtIndex: 2] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 3] toDictionary: dict];
				[self addCase: [tags characterAtIndex: 4] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'L') { // všechen
				[dict setObject: @"indef2" forKey: @"prontype"];
				[self addGender: [tags characterAtIndex: 2] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 3] toDictionary: dict];
				[self addCase: [tags characterAtIndex: 4] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'E') { // což
				[dict setObject: @"rel_z" forKey: @"prontype"];
				[self addCase: [tags characterAtIndex: 2] toDictionary: dict];
			} else { NSLog(@"unknown pron subtype"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			break;
		case 'A':
			[dict setObject: @"word" forKey: @"type"];
			[dict setObject: @"a" forKey: @"pos"];
			if ([tags characterAtIndex: 1] == 'V' && [tags characterAtIndex: 2] == 'G') {
				[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 4] toDictionary: dict];
				[self addCase: [tags characterAtIndex: 5] toDictionary: dict];
				[self addDegree: [tags characterAtIndex: 6] toDictionary: dict];
				[dict setObject: @"actpart" forKey: @"atype"];
			} else if ([tags characterAtIndex: 1] == 'S' && [tags characterAtIndex: 2] == 'M') {
				[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 4] toDictionary: dict];
				[self addCase: [tags characterAtIndex: 5] toDictionary: dict];
				[dict setObject: @"poss" forKey: @"atype"];
			} else if ([tags characterAtIndex: 1] == 'C') {
				[self addGender: [tags characterAtIndex: 2] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 3] toDictionary: dict];
				[self addNegation: [tags characterAtIndex: 4] toDictionary: dict];
				[dict setObject: @"short" forKey: @"atype"];
			} else {
				[self addGender: [tags characterAtIndex: 1] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 2] toDictionary: dict];
				[self addCase: [tags characterAtIndex: 3] toDictionary: dict];
				[self addDegree: [tags characterAtIndex: 4] toDictionary: dict];
				[self addNegation: [tags characterAtIndex: 5] toDictionary: dict];
				[dict setObject: @"long" forKey: @"atype"];
			}
			break;
		case 'C':
			[dict setObject: @"word" forKey: @"type"];
			[dict setObject: @"num" forKey: @"pos"];
			if ([tags characterAtIndex: 1] == 'M') {
				[dict setObject: @"adv_ord" forKey: @"numtype"];
			} else if ([tags characterAtIndex: 1] == 'I') {
				[dict setObject: @"indef" forKey: @"numtype"];
				[self addCase: [tags characterAtIndex: 2] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'G') {
				[dict setObject: @"card" forKey: @"numtype"];
				[self addGender: [tags characterAtIndex: 2] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 3] toDictionary: dict];
				[self addCase: [tags characterAtIndex: 4] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'D') {
				[dict setObject: @"card_pl" forKey: @"numtype"];
				[self addGender: [tags characterAtIndex: 2] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 3] toDictionary: dict];
				[self addCase: [tags characterAtIndex: 4] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'B') {
				[dict setObject: @"card" forKey: @"numtype"];
				[self addNumber: [tags characterAtIndex: 2] toDictionary: dict];
				[self addCase: [tags characterAtIndex: 3] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'R') {
				[dict setObject: @"ord" forKey: @"numtype"];
				[self addGender: [tags characterAtIndex: 2] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 3] toDictionary: dict];
				[self addCase: [tags characterAtIndex: 4] toDictionary: dict];
			} else { NSLog(@"unknown numeral subtype"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			break;
		case 'V':
			[dict setObject: @"word" forKey: @"type"];
			[dict setObject: @"verb" forKey: @"pos"];
			if ([tags characterAtIndex: 1] == 'R') {
				[dict setObject: @"lpart" forKey: @"vform"];
				[dict setObject: @"act" forKey: @"voice"];
				[dict setObject: @"past" forKey: @"tense"];
				[self addGender: [tags characterAtIndex: 2] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 3] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'S') {
				[dict setObject: @"part_short" forKey: @"vform"];
				[dict setObject: @"pas" forKey: @"voice"];
				[dict setObject: @"past" forKey: @"tense"];
				[self addGender: [tags characterAtIndex: 2] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 3] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'V') {
				[dict setObject: @"transgr" forKey: @"vform"];
				[dict setObject: @"act" forKey: @"voice"];
				[dict setObject: @"past" forKey: @"tense"];
				[self addNumber: [tags characterAtIndex: 2] toDictionary: dict];
				[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'G') {
				[dict setObject: @"transgr" forKey: @"vform"];
				[dict setObject: @"act" forKey: @"voice"];
				[dict setObject: @"pres" forKey: @"tense"];
				[self addNumber: [tags characterAtIndex: 2] toDictionary: dict];
				[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'P') {
				[dict setObject: @"fin" forKey: @"vform"];
				[dict setObject: @"act" forKey: @"voice"];
				[dict setObject: @"pres" forKey: @"tense"];
				[self addNumber: [tags characterAtIndex: 2] toDictionary: dict];
				[self addPerson: [tags characterAtIndex: 3] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'M') {
				[dict setObject: @"imp" forKey: @"vform"];
				[dict setObject: @"act" forKey: @"voice"];
				[dict setObject: @"pres" forKey: @"tense"];
				[self addNumber: [tags characterAtIndex: 2] toDictionary: dict];
				[self addPerson: [tags characterAtIndex: 3] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'C') {
				[dict setObject: @"cond" forKey: @"vform"];
				[dict setObject: @"act" forKey: @"voice"];
				[dict setObject: @"pres" forKey: @"tense"];
				[self addNumber: [tags characterAtIndex: 2] toDictionary: dict];
				[self addPerson: [tags characterAtIndex: 3] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'U') {
				[dict setObject: @"fin" forKey: @"vform"];
				[dict setObject: @"act" forKey: @"voice"];
				[dict setObject: @"fut" forKey: @"tense"];
				[self addNumber: [tags characterAtIndex: 2] toDictionary: dict];
				[self addPerson: [tags characterAtIndex: 3] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'F') {
				[dict setObject: @"inf" forKey: @"vform"];
				[dict setObject: @"act" forKey: @"voice"];
				[dict setObject: @"pres" forKey: @"tense"];
			} else { NSLog(@"unknown verb subtype"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			break;
		case 'I':
			[dict setObject: @"word" forKey: @"type"];
			[dict setObject: @"interj" forKey: @"pos"];
			break;
		case 'H':
			if ([tags isEqual: @"HYPH"]) {
				[dict setObject: @"word" forKey: @"type"];
				[dict setObject: @"a" forKey: @"pos"];
				[dict setObject: @"hyph" forKey: @"atype"];
			} else { NSLog(@"unknown pos"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			break;
		case 'X':
			if ([tags length] == 1) {
				[dict setObject: @"word" forKey: @"type"];
				[dict setObject: @"x_unknown" forKey: @"pos"];
			} else if ([tags isEqual: @"XABBR"]) {
				[dict setObject: @"word" forKey: @"type"];
				[dict setObject: @"abbr" forKey: @"pos"];
			} else { NSLog(@"unknown pos"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			break;
		default:
			NSLog(@"unknown pos"); NSLog(@"---- %@ %@", dict, tags); exit(1);
	}
}

- (void)addGender:(unichar)value toDictionary:(NSMutableDictionary*)dict {
	switch (value) {
		case 'M': [dict setObject: @"masca" forKey: @"gender"]; break;
		case 'I': [dict setObject: @"masci" forKey: @"gender"]; break;
		case 'F': [dict setObject: @"fem" forKey: @"gender"]; break;
		case 'N': [dict setObject: @"neut" forKey: @"gender"]; break;
		case 'X': break;
		default: NSLog(@"unknown value for gender: %c", value);
			NSLog(@"%@", dict); exit(1);
	}
}

- (void)addPronGender:(unichar)value toDictionary:(NSMutableDictionary*)dict {
	switch (value) {
		case 'M': [dict setObject: @"masca" forKey: @"prongender"]; break;
		case 'I': [dict setObject: @"masci" forKey: @"prongender"]; break;
		case 'F': [dict setObject: @"fem" forKey: @"prongender"]; break;
		case 'N': [dict setObject: @"neut" forKey: @"prongender"]; break;
		case 'X': break;
		default: NSLog(@"unknown value for prongender: %c", value);
			NSLog(@"%@", dict); exit(1);
	}
}

- (void)addNumber:(unichar)value toDictionary:(NSMutableDictionary*)dict {
	switch (value) {
		case 'S': [dict setObject: @"sg" forKey: @"number"]; break;
		case 'D': [dict setObject: @"du" forKey: @"number"]; break;
		case 'P': [dict setObject: @"pl" forKey: @"number"]; break;
		case 'X': break;
		default: NSLog(@"unknown value for number: %c", value);
			NSLog(@"%@", dict); exit(1);
	}
}

- (void)addPronNumber:(unichar)value toDictionary:(NSMutableDictionary*)dict {
	switch (value) {
		case 'S': [dict setObject: @"sg" forKey: @"pronnumber"]; break;
		case 'P': [dict setObject: @"pl" forKey: @"pronnumber"]; break;
		case 'X': break;
		default: NSLog(@"unknown value for pronnumber: %c", value);
			NSLog(@"%@", dict); exit(1);
	}
}

- (void)addNegation:(unichar)value toDictionary:(NSMutableDictionary*)dict {
	if ([dict objectForKey: @"negation"]) return;
	switch (value) {
		case '@':
		case 'A': [dict setObject: @"0" forKey: @"negation"]; break;
		case 'N': [dict setObject: @"1" forKey: @"negation"]; break;
		default: NSLog(@"unknown value for negation: %c", value);
			NSLog(@"%@", dict); exit(1);
	}
}

- (void)addDegree:(unichar)value toDictionary:(NSMutableDictionary*)dict {
	switch (value) {
		case '1':
		case '@': [dict setObject: @"1" forKey: @"degree"]; break;
		case '2':
		case '#': [dict setObject: @"2" forKey: @"degree"]; break;
		case '3':
		case '&': [dict setObject: @"3" forKey: @"degree"]; break;
		case 'B': break;
		default: NSLog(@"unknown value for degree: %c", value);
			NSLog(@"%@", dict); exit(1);
	}
}

- (void)addPerson:(unichar)value toDictionary:(NSMutableDictionary*)dict {
	switch (value) {
		case '1': [dict setObject: @"1" forKey: @"person"]; break;
		case '2': [dict setObject: @"2" forKey: @"person"]; break;
		case '3': [dict setObject: @"3" forKey: @"person"]; break;
		default: NSLog(@"unknown value for person: %c", value);
			NSLog(@"%@", dict); exit(1);
	}
}

- (void)addCase:(unichar)value toDictionary:(NSMutableDictionary*)dict {
	switch (value) {
		case '1': [dict setObject: @"nom" forKey: @"case"]; break;
		case '2': [dict setObject: @"gen" forKey: @"case"]; break;
		case '3': [dict setObject: @"dat" forKey: @"case"]; break;
		case '4': [dict setObject: @"acc" forKey: @"case"]; break;
		case '5': [dict setObject: @"voc" forKey: @"case"]; break;
		case '6': [dict setObject: @"loc" forKey: @"case"]; break;
		case '7': [dict setObject: @"ins" forKey: @"case"]; break;
		case 'X': break;
		default: NSLog(@"unknown value for case: %c", value);
			NSLog(@"%@", dict); exit(1);
	}
}

- (NSArray*)analyze:(NSString*)form {
	NSMutableArray* result = [[NSMutableArray alloc] init];
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	if ([form length] > 6 && [[form substringToIndex: 5] isEqual: @"nejne"]) {
		NSString* form2 = [form substringFromIndex: 5];
		NSArray* result2 = [self analyzeCore: form2 withPrefix: (PREFIX_NEJ | PREFIX_NE) acceptUnknown: NO];
		[result addObjectsFromArray: result2];
	}
	if ([form length] > 4 && [[form substringToIndex: 3] isEqual: @"nej"]) {
		NSString* form2 = [form substringFromIndex: 3];
		NSArray* result2 = [self analyzeCore: form2 withPrefix: PREFIX_NEJ acceptUnknown: NO];
		[result addObjectsFromArray: result2];
	}
	if ([form length] > 3 && [[form substringToIndex: 2] isEqual: @"ne"]) {
		NSString* form2 = [form substringFromIndex: 2];
		NSArray* result2 = [self analyzeCore: form2 withPrefix: PREFIX_NE acceptUnknown: NO];
		[result addObjectsFromArray: result2];
	}
	NSArray* result2 = [self analyzeCore: form withPrefix: 0 acceptUnknown: [result count] == 0];
	[result addObjectsFromArray: result2];
	if ([result count] == 0) [result addObject: [NSArray arrayWithObjects: form, @"UNKNOWN", nil]];
	//NSLog(@"-- %@ %@", form, [result description]);
	[pool release];
	return result;
}

- (NSMutableArray*)analyzeCore:(NSString*)form withPrefix:(int)cutPrefix acceptUnknown:(BOOL)acceptUnknown {
	NSMutableArray* forms = [[NSMutableArray alloc] init];
	int i;
	for (i = 1; i <= [form length]; i++) {
		NSString* prefix = [form substringToIndex: i];
		NSArray* infos = [prefixes objectForKey: prefix];
		if (infos != nil) {
			NSEnumerator* enumerator = [infos objectEnumerator];
			NSArray* info;
			while (info = [enumerator nextObject]) {
				NSString* paradigm = [info objectAtIndex: 0];
				NSString* lemma = [info objectAtIndex: 1];
				if ([lemma rangeOfString: @"`"].location != NSNotFound) {
					NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString: @"`"];
					lemma = [[lemma splitBy: separators] objectAtIndex: 0];
				}
				id tagset = [info objectAtIndex: 2];
				NSArray* infos2 = [paradigms objectForKey: paradigm];
				NSEnumerator* enumerator2 = [infos2 objectEnumerator];
				NSArray* info2;
				while (info2 = [enumerator2 nextObject]) {
					id ending = [info2 objectAtIndex: 0];
					if (i == [form length] && ending == [NSNull null] ||
					  i < [form length] && [ending isEqual: [form substringFromIndex: i]]) {
						id tagset2 = [info2 objectAtIndex: 1];
						if (cutPrefix > 0) {
							//NSLog(@"##### %@ %@", lemma, tagset2);
							if ((cutPrefix & PREFIX_NEJ) && ([tagset2 characterAtIndex: 0] == 'N' || [tagset2 characterAtIndex: 0] == 'V')) {
								tagset2 = @"UNKNOWN";
							//} else if (cutPrefix == PREFIX_NE && ([tagset2 characterAtIndex: 0] == 'N')) {
							//	tagset2 = @"UNKNOWN";
							} else {
								tagset2 = [tagset2 mutableCopy]; //[NSMutableString stringWithString: tagset2];
								if (cutPrefix & PREFIX_NEJ) {
									int pos = [tagset2 length] - 2;
									if (pos > 0) [tagset2 replaceCharactersInRange: NSMakeRange(pos, 1) withString: @"&"]; 
								}
								if (cutPrefix & PREFIX_NE) {
									[tagset2 appendString: @"_N"];
								}
							}
						}
						if (![tagset2 isEqual: @"UNKNOWN"] || acceptUnknown)
							[forms addObject: [NSArray arrayWithObjects: lemma, tagset != [NSNull null] ? tagset : tagset2, nil]];
							//NSLog(@"---- %@ %@", lemma, tagset2);
					}
				}
			}
		}
	}
	return [forms autorelease];
}

- (NSArray*)analyzeTaggedArray:(NSArray*)sentence {
	NSMutableArray* array = [NSMutableArray arrayWithCapacity: [sentence count]];
	NSEnumerator* enumerator0 = [sentence objectEnumerator];
	NSArray* element0; unsigned order = 0;
	while (element0 = [enumerator0 nextObject]) {
		id element; order++;
		NSString* sOrder = [[NSNumber numberWithInt: order] description];
		NSString* token = [element0 objectAtIndex: 0];
		NSString* lemma = [element0 objectAtIndex: 1];
		id tags = [element0 objectAtIndex: 2];
				NSString* lowercaseToken = [token lowercaseString];
				//NSArray* morph = [self analyze: lowercaseToken];
				//if ([token isEqual: @"SQL"]) NSLog(@"%@ %@", token, morph);
				if (tags == [NSNull null] || [tags characterAtIndex: 0] == 'X') {
					//NSLog(@"1 %@ %@ %@", token, lemma, tags);
					element = [NSDictionary dictionaryWithObjectsAndKeys: sOrder, @"order", @"unknown", @"type", token, @"form", nil];
				} else {
					id longTag = tags;
					tags = [tagMap objectForKey: longTag];
					if (tags == nil) {
						if ([longTag characterAtIndex: 10] == 'A') {
							longTag = [longTag mutableCopy];
							[longTag replaceCharactersInRange: NSMakeRange(10, 1) withString: @"@"];
							tags = [tagMap objectForKey: longTag];
						}
						if ([longTag characterAtIndex: 10] == 'N') {
							longTag = [longTag mutableCopy];
							[longTag replaceCharactersInRange: NSMakeRange(10, 1) withString: @"@"];
							tags = [tagMap objectForKey: longTag];
						}
						if ([longTag characterAtIndex: 9] == '3') {
							longTag = [longTag mutableCopy];
							[longTag replaceCharactersInRange: NSMakeRange(9, 1) withString: @"1"];
							tags = [tagMap objectForKey: longTag];
						} //else NSLog(@"%c", [longTag characterAtIndex: 9]);
					}
					if (tags == nil) {
						NSLog(@"unknown tag mapping: %@ %@ %u", lemma, longTag, [tagMap count]);
						exit(1);
					}
					//NSLog(@"2 %@ %@ %@", token, lemma, tags);
					element = [NSMutableSet set];
					//NSEnumerator* enumerator2 = [morph objectEnumerator];
					//NSArray* lemmaAndTag;
					//while (lemmaAndTag = [enumerator2 nextObject]) {
						//NSString* lemma = [lemmaAndTag objectAtIndex: 0];
						NSRange lemmaHyphen = [lemma rangeOfString: @"-"];
						NSString* pureLemma = lemmaHyphen.location == NSNotFound ? lemma : [lemma substringToIndex: lemmaHyphen.location];
						//NSString* tags = [lemmaAndTag objectAtIndex: 1];
						// sorting out one-character words which are annotated as nouns
						if ([lowercaseToken length] == 1 && [tags characterAtIndex: 0] == 'N') continue;
						if ([lowercaseToken length] == 1 && [tags characterAtIndex: 0] == 'A') continue;
						if ([lowercaseToken length] == 1 && [tags characterAtIndex: 0] == 'P') continue;
						if ([lowercaseToken length] == 1 && [tags characterAtIndex: 0] == 'V') continue;
						if ([lowercaseToken length] == 1 && [tags isEqual: @"CX"]) continue;
						//if ([token isEqual: @"SQL"]) NSLog(@"%@ %@ %@", token, lemma, tags);
						NSRange hyphen8 = [tags rangeOfString: @"-8"];
						if (hyphen8.location != NSNotFound && ![lowercaseToken isEqual: pureLemma]) continue;
						NSRange hyphen6 = [tags rangeOfString: @"-6"];
						if (hyphen6.location != NSNotFound) continue;
						NSRange hyphen1 = [tags rangeOfString: @"-1"];
						if (hyphen1.location != NSNotFound) tags = [tags substringToIndex: hyphen1.location];
						//NSLog(@"##### %@ %@", lowercaseToken, tags);
						NSMutableArray* unrolledTags = [NSMutableArray array];
						
						// unrolling gender Y
						if ([tags length] >= 4 && ([tags characterAtIndex: 0] == 'V' || [tags characterAtIndex: 0] == 'P') && [tags characterAtIndex: 3] == 'Y') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(3, 1) withString: @"M"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(3, 1) withString: @"I"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender Y
						else if ([tags length] >= 3 && ([tags characterAtIndex: 0] == 'V' || [tags characterAtIndex: 0] == 'P' || [tags characterAtIndex: 0] == 'C') && [tags characterAtIndex: 2] == 'Y') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"M"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"I"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender Y
						else if ([tags length] >= 5 && [tags characterAtIndex: 0] == 'P' && [tags characterAtIndex: 4] == 'Y') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(4, 1) withString: @"M"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(4, 1) withString: @"I"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender H
						else if ([tags length] >= 5 && [tags characterAtIndex: 0] == 'P' && [tags characterAtIndex: 4] == 'H') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(4, 1) withString: @"F"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(4, 1) withString: @"N"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender H
						else if ([tags length] >= 5 && [tags characterAtIndex: 0] == 'C' && [tags characterAtIndex: 2] == 'H') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"F"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"N"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender Z
						else if ([tags length] >= 4 && [tags characterAtIndex: 0] == 'P' && [tags characterAtIndex: 3] == 'Z') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(3, 1) withString: @"M"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(3, 1) withString: @"I"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(3, 1) withString: @"N"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender Z
						else if ([tags length] >= 4 && ([tags characterAtIndex: 0] == 'P' || [tags characterAtIndex: 0] == 'C') && [tags characterAtIndex: 2] == 'Z') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"M"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"I"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"N"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender Z
						else if ([tags length] >= 5 && [tags characterAtIndex: 0] == 'P' && [tags characterAtIndex: 4] == 'Z') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(4, 1) withString: @"M"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(4, 1) withString: @"I"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(4, 1) withString: @"N"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender T
						else if ([tags length] >= 3 && [tags characterAtIndex: 0] == 'V' && [tags characterAtIndex: 2] == 'T') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"I"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"F"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender/number Q
						else if ([tags length] >= 4 && [[tags substringWithRange: NSMakeRange(0, 4)] isEqual: @"VRQX"]) {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 2) withString: @"FS"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 2) withString: @"NP"];
							[unrolledTags addObject: mutableTags];
						}
						
						// unrolling gender/number Q
						else if ([tags length] >= 4 && [[tags substringWithRange: NSMakeRange(0, 4)] isEqual: @"VSQX"]) {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 2) withString: @"FS"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 2) withString: @"NP"];
							[unrolledTags addObject: mutableTags];
						}
						
						// unrolling gender/number Q
						else if ([tags length] >= 4 && [[tags substringWithRange: NSMakeRange(0, 4)] isEqual: @"ACQX"]) {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 2) withString: @"FS"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 2) withString: @"NP"];
							[unrolledTags addObject: mutableTags];
						} else [unrolledTags addObject: tags];
						
						NSEnumerator* enumerator3 = [unrolledTags objectEnumerator];
						while ((tags = [enumerator3 nextObject])) {
							NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								lemma, @"lemma",
								tags, @"tags",
								sOrder, @"order", @"raw_word", @"type", token, @"form", nil];
							if ([token length] > 1 && [token isEqual: [token uppercaseString]]) [dict setObject: @"all" forKey: @"capitalized"];
							else if ([token isEqual: [token capitalizedString]]) [dict setObject: @"first" forKey: @"capitalized"];
							[self enrich: dict];
							[element addObject: dict];
						}
		}
		[array addObject: element];
		element = [NSDictionary dictionaryWithObjectsAndKeys: @"shackle", @"type", nil];
		[array addObject: element];
	}
	return array;
}

- (NSArray*)analyzeArray:(NSArray*)sentence {
	NSCharacterSet* noteCharacters = [NSCharacterSet characterSetWithCharactersInString: @",.;:()[]{}\'\"<>-"];
	NSMutableArray* array = [NSMutableArray arrayWithCapacity: [sentence count]];
	NSEnumerator* enumerator = [sentence objectEnumerator];
	NSString* token; unsigned order = 0;
	while (token = [enumerator nextObject]) {
		id element; order++;
		NSString* sOrder = [[NSNumber numberWithInt: order] description];
		if ([token length] == 1 && [noteCharacters characterIsMember: [token characterAtIndex: 0]]) {
			element = [NSDictionary dictionaryWithObjectsAndKeys: sOrder, @"order", @"note", @"type", token, @"form", nil];
		} else {
			NSScanner* scanner = [NSScanner scannerWithString: token];
			int n;
			BOOL scanned = [scanner scanInt: &n];
			if (scanned == YES && [token length] == [scanner scanLocation]) {
				element = [NSDictionary dictionaryWithObjectsAndKeys: sOrder, @"order", @"number", @"type", token, @"form", nil];
			} else {
				NSString* lowercaseToken = [token lowercaseString];
				NSArray* morph = [self analyze: lowercaseToken];
				//if ([token isEqual: @"SQL"]) NSLog(@"%@ %@", token, morph);
				if (morph == nil) {
					element = [NSDictionary dictionaryWithObjectsAndKeys: sOrder, @"order", @"unknown", @"type", token, @"form", nil];
				} else {
					element = [NSMutableSet setWithCapacity: [morph count]];
					NSEnumerator* enumerator2 = [morph objectEnumerator];
					NSArray* lemmaAndTag;
					while (lemmaAndTag = [enumerator2 nextObject]) {
						NSString* lemma = [lemmaAndTag objectAtIndex: 0];
						NSRange lemmaHyphen = [lemma rangeOfString: @"-"];
						NSString* pureLemma = lemmaHyphen.location == NSNotFound ? lemma : [lemma substringToIndex: lemmaHyphen.location];
						NSString* tags = [lemmaAndTag objectAtIndex: 1];
						// sorting out one-character words which are annotated as nouns
						if ([lowercaseToken length] == 1 && [tags characterAtIndex: 0] == 'N') continue;
						if ([lowercaseToken length] == 1 && [tags characterAtIndex: 0] == 'A') continue;
						if ([lowercaseToken length] == 1 && [tags characterAtIndex: 0] == 'P') continue;
						if ([lowercaseToken length] == 1 && [tags characterAtIndex: 0] == 'V') continue;
						if ([lowercaseToken length] == 1 && [tags isEqual: @"CX"]) continue;
						//if ([token isEqual: @"SQL"]) NSLog(@"%@ %@ %@", token, lemma, tags);
						NSRange hyphen8 = [tags rangeOfString: @"-8"];
						if (hyphen8.location != NSNotFound && ![lowercaseToken isEqual: pureLemma]) continue;
						NSRange hyphen6 = [tags rangeOfString: @"-6"];
						if (hyphen6.location != NSNotFound) continue;
						NSRange hyphen1 = [tags rangeOfString: @"-1"];
						if (hyphen1.location != NSNotFound) tags = [tags substringToIndex: hyphen1.location];
						//NSLog(@"##### %@ %@", lowercaseToken, tags);
						NSMutableArray* unrolledTags = [NSMutableArray array];
						
						// unrolling gender Y
						if ([tags length] >= 4 && ([tags characterAtIndex: 0] == 'V' || [tags characterAtIndex: 0] == 'P') && [tags characterAtIndex: 3] == 'Y') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(3, 1) withString: @"M"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(3, 1) withString: @"I"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender Y
						else if ([tags length] >= 3 && ([tags characterAtIndex: 0] == 'V' || [tags characterAtIndex: 0] == 'P' || [tags characterAtIndex: 0] == 'C') && [tags characterAtIndex: 2] == 'Y') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"M"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"I"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender Y
						else if ([tags length] >= 5 && [tags characterAtIndex: 0] == 'P' && [tags characterAtIndex: 4] == 'Y') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(4, 1) withString: @"M"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(4, 1) withString: @"I"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender H
						else if ([tags length] >= 5 && [tags characterAtIndex: 0] == 'P' && [tags characterAtIndex: 4] == 'H') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(4, 1) withString: @"F"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(4, 1) withString: @"N"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender H
						else if ([tags length] >= 5 && [tags characterAtIndex: 0] == 'C' && [tags characterAtIndex: 2] == 'H') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"F"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"N"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender Z
						else if ([tags length] >= 4 && [tags characterAtIndex: 0] == 'P' && [tags characterAtIndex: 3] == 'Z') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(3, 1) withString: @"M"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(3, 1) withString: @"I"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(3, 1) withString: @"N"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender Z
						else if ([tags length] >= 4 && ([tags characterAtIndex: 0] == 'P' || [tags characterAtIndex: 0] == 'C') && [tags characterAtIndex: 2] == 'Z') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"M"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"I"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"N"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender Z
						else if ([tags length] >= 5 && [tags characterAtIndex: 0] == 'P' && [tags characterAtIndex: 4] == 'Z') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(4, 1) withString: @"M"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(4, 1) withString: @"I"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(4, 1) withString: @"N"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender T
						else if ([tags length] >= 3 && [tags characterAtIndex: 0] == 'V' && [tags characterAtIndex: 2] == 'T') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"I"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"F"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender/number Q
						else if ([tags length] >= 4 && [[tags substringWithRange: NSMakeRange(0, 4)] isEqual: @"VRQX"]) {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 2) withString: @"FS"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 2) withString: @"NP"];
							[unrolledTags addObject: mutableTags];
						}
						
						// unrolling gender/number Q
						else if ([tags length] >= 4 && [[tags substringWithRange: NSMakeRange(0, 4)] isEqual: @"VSQX"]) {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 2) withString: @"FS"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 2) withString: @"NP"];
							[unrolledTags addObject: mutableTags];
						}
						
						// unrolling gender/number Q
						else if ([tags length] >= 4 && [[tags substringWithRange: NSMakeRange(0, 4)] isEqual: @"ACQX"]) {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 2) withString: @"FS"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 2) withString: @"NP"];
							[unrolledTags addObject: mutableTags];
						} else [unrolledTags addObject: tags];
						
						NSEnumerator* enumerator3 = [unrolledTags objectEnumerator];
						while ((tags = [enumerator3 nextObject])) {
							NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								lemma, @"lemma",
								tags, @"tags",
								sOrder, @"order", @"raw_word", @"type", token, @"form", nil];
							if ([token length] > 1 && [token isEqual: [token uppercaseString]]) [dict setObject: @"all" forKey: @"capitalized"];
							else if ([token isEqual: [token capitalizedString]]) [dict setObject: @"first" forKey: @"capitalized"];
							[self enrich: dict];
							[element addObject: dict];
						}
					}
				}
			}
		}
		[array addObject: element];
		element = [NSDictionary dictionaryWithObjectsAndKeys: @"shackle", @"type", nil];
		[array addObject: element];
	}
	return array;
}
@end
