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
		parameters = params;
		[self load];
	}
	return self;
}


- (void)load {
	prefixes = [[NSMutableDictionary alloc] init];
	paradigms = [[NSMutableDictionary alloc] init];
	tagMap = [[NSMutableDictionary alloc] init];
	@autoreleasepool {
		NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString: @"|"];
		
		NSString* fileName = parameters != nil ? parameters[@"file"] : @"/Users_XXX/phomola/dev/data/czm.il2.utf8";
		FILE* file = fopen(fileName.UTF8String, "r");
		char line[1000]; //int n = 0;
		while (fgets(line, 1000, file) != NULL) {
			//if (++n % 1000 == 0) NSLog(@"%d", n);
			if (line[0] == 'R') {
				NSArray* array = [@(line) splitBy: separators];
				NSString* paradigm = array[1];
				NSString* prefix = [array[2] lowercaseString];
				NSString* lemma = [array[3] lowercaseString];
				id tagset = array[4];
				if ([tagset isEqual: @"0"]) tagset = [NSNull null];
				else {
					id longTagset = array[5];
					//if ([tagMap objectForKey: longTagset] != nil && ![[tagMap objectForKey: longTagset] isEqual: tagset]) NSLog(@"!!!");
					tagMap[longTagset] = tagset;
				}
				NSMutableArray* info = prefixes[prefix];
				if (info == nil) {
					info = [NSMutableArray array];
					prefixes[prefix] = info;
				}
				[info addObject: @[paradigm, lemma, tagset]];
			} else if (line[0] == 'E') {
				NSArray* array = [@(line) splitBy: separators];
				NSString* paradigm = array[1];
				id ending = array[4];
				if ([ending isEqual: @"0"]) ending = [NSNull null];
				NSString* tagset = array[5];
				id longTagset = array[6];
				//if ([tagMap objectForKey: longTagset] != nil && ![[tagMap objectForKey: longTagset] isEqual: tagset]) NSLog(@"!!!");
				tagMap[longTagset] = tagset;
				//if ([longTagset rangeOfString: @"NNFP4-"].location == 0) NSLog(@"OK: %@", longTagset);
				NSMutableArray* info = paradigms[paradigm];
				if (info == nil) {
					info = [NSMutableArray array];
					paradigms[paradigm] = info;
				}
				[info addObject: @[ending, tagset]];
			}
		}
		fclose(file);
	}
}

- (void)enrich:(NSMutableDictionary*)dict {
	NSString* tags = dict[@"tags"];
	if ([tags isEqual: @"UNKNOWN"]) {
		dict[@"type"] = @"unknown";
		dict[@"pos"] = @"unknown";
		return;
	}
	// negace
	if ([tags rangeOfString: @"_N"].location == tags.length - 2) {
		dict[@"negation"] = @"1";
	}
	unichar pos = [tags characterAtIndex: 0];
	//NSLog(@"---- %@ %@", [dict objectForKey: @"lemma"], tags);
	switch (pos) {
		case 'D':
			if (tags.length > 2) [self addDegree: [tags characterAtIndex: 2] toDictionary: dict];
			if (tags.length > 3) [self addNegation: [tags characterAtIndex: 3] toDictionary: dict];
			dict[@"type"] = @"word";
			dict[@"pos"] = @"adv";
			break;
		case 'T':
			dict[@"type"] = @"word";
			dict[@"pos"] = @"part";
			break;
		case 'J':
			dict[@"type"] = @"word";
			dict[@"pos"] = @"conj";
			break;
		case 'R':
			dict[@"type"] = @"word";
			dict[@"pos"] = @"prep";
			if (tags.length == 2) [self addCase: [tags characterAtIndex: 1] toDictionary: dict];
			else [self addCase: [tags characterAtIndex: 2] toDictionary: dict];
			break;
		case 'N':
			dict[@"type"] = @"word";
			dict[@"pos"] = @"n";
			[self addGender: [tags characterAtIndex: 1] toDictionary: dict];
			[self addNumber: [tags characterAtIndex: 2] toDictionary: dict];
			[self addCase: [tags characterAtIndex: 3] toDictionary: dict];
			break;
		case 'P':
			dict[@"type"] = @"word";
			dict[@"pos"] = @"pron";
			if ([tags characterAtIndex: 1] == 'R') {
				if ([tags characterAtIndex: 2] == 'C') { // reflexive pronoun
					[self addCase: [tags characterAtIndex: 4] toDictionary: dict];
					dict[@"prontype"] = @"refl";
				} else if ([tags characterAtIndex: 2] == 'X') { // long reflexive pronoun (e.g. sebe)
					dict[@"prontype"] = @"long_refl";
					[self addCase: [tags characterAtIndex: 3] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == 'S') { // reflexive possessive pronoun
					dict[@"prontype"] = @"poss";
					dict[@"person"] = @"refl";
					[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 4] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 5] toDictionary: dict];
				} else { NSLog(@"unknown pron subsubtype"); NSLog(@"---- %@ %@ %@", dict[@"form"], dict[@"lemma"], tags); exit(1); }
			} else if ([tags characterAtIndex: 1] == 'I') {
				if ([tags characterAtIndex: 2] == 'F') { // některý
					dict[@"prontype"] = @"indef";
					[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 4] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 5] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == 'C') { // něco
					dict[@"prontype"] = @"indef";
					[self addCase: [tags characterAtIndex: 3] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == 'K') { // někdo
					dict[@"prontype"] = @"indef";
					[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 4] toDictionary: dict];
				} else { NSLog(@"unknown pron subsubtype"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			} else if ([tags characterAtIndex: 1] == 'A') {
				if ([tags characterAtIndex: 2] == 'E') {
					dict[@"prontype"] = @"rel";
					[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 4] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 5] toDictionary: dict];
				} else { NSLog(@"unknown pron subsubtype"); NSLog(@"---- %@ %@", dict[@"lemma"], tags); exit(1); }
			} else if ([tags characterAtIndex: 1] == 'Q') {
				if ([tags characterAtIndex: 2] == 'F') {
					dict[@"prontype"] = @"rel";
					[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 4] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 5] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == 'C') {
					dict[@"prontype"] = @"interr";
					[self addCase: [tags characterAtIndex: 3] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == 'K') {
					dict[@"prontype"] = @"interr";
					[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 4] toDictionary: dict];
				} else { NSLog(@"unknown pron subsubtype"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			} else if ([tags characterAtIndex: 1] == 'P') {
				if ([tags characterAtIndex: 2] == '3' && [tags characterAtIndex: 3] == 'R') {
					dict[@"prontype"] = @"pers";
					dict[@"pronsubtype"] = @"prep";
					dict[@"person"] = @"3";
					[self addGender: [tags characterAtIndex: 4] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 5] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 6] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == '3') {
					dict[@"prontype"] = @"pers";
					dict[@"person"] = @"3";
					[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 4] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 5] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == '1') {
					dict[@"prontype"] = @"pers";
					dict[@"person"] = @"1";
					int delta = 0;
					BOOL enclitical = [tags characterAtIndex: 3] == 'C';
					if (enclitical) {
						dict[@"encl"] = @"1";
						delta = 1;
					}
					[self addNumber: [tags characterAtIndex: 3 + delta] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 4 + delta] toDictionary: dict];
				} else { NSLog(@"unknown pron subsubtype"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			} else if ([tags characterAtIndex: 1] == 'S') {
				if ([tags characterAtIndex: 2] == '1') {
					dict[@"prontype"] = @"poss";
					dict[@"person"] = @"1";
					[self addPronNumber: [tags characterAtIndex: 3] toDictionary: dict];
					[self addGender: [tags characterAtIndex: 4] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 5] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 6] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == '3') {
					dict[@"prontype"] = @"poss";
					dict[@"person"] = @"3";
					[self addPronGender: [tags characterAtIndex: 3] toDictionary: dict];
					[self addPronNumber: [tags characterAtIndex: 4] toDictionary: dict];
					[self addGender: [tags characterAtIndex: 5] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 6] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 7] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == 'E') {
					dict[@"prontype"] = @"poss_rel";
					[self addPronNumber: [tags characterAtIndex: 4] toDictionary: dict];
					[self addGender: [tags characterAtIndex: 5] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 6] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 7] toDictionary: dict];
				} else { NSLog(@"unknown pron subsubtype"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			} else if ([tags characterAtIndex: 1] == 'N') {
				if ([tags characterAtIndex: 2] == 'F') {
					dict[@"prontype"] = @"neg"; // žádný
					[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
					[self addNumber: [tags characterAtIndex: 4] toDictionary: dict];
					[self addCase: [tags characterAtIndex: 5] toDictionary: dict];
				} else if ([tags characterAtIndex: 2] == 'C') { // nic
					dict[@"prontype"] = @"neg";
					[self addCase: [tags characterAtIndex: 3] toDictionary: dict];
				} else { NSLog(@"unknown pron subsubtype"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			} else if ([tags characterAtIndex: 1] == 'D') {
				dict[@"prontype"] = @"dem";
				[self addGender: [tags characterAtIndex: 2] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 3] toDictionary: dict];
				[self addCase: [tags characterAtIndex: 4] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'L') { // všechen
				dict[@"prontype"] = @"indef2";
				[self addGender: [tags characterAtIndex: 2] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 3] toDictionary: dict];
				[self addCase: [tags characterAtIndex: 4] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'E') { // což
				dict[@"prontype"] = @"rel_z";
				[self addCase: [tags characterAtIndex: 2] toDictionary: dict];
			} else { NSLog(@"unknown pron subtype"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			break;
		case 'A':
			dict[@"type"] = @"word";
			dict[@"pos"] = @"a";
			if ([tags characterAtIndex: 1] == 'V' && [tags characterAtIndex: 2] == 'G') {
				[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 4] toDictionary: dict];
				[self addCase: [tags characterAtIndex: 5] toDictionary: dict];
				[self addDegree: [tags characterAtIndex: 6] toDictionary: dict];
				dict[@"atype"] = @"actpart";
			} else if ([tags characterAtIndex: 1] == 'S' && [tags characterAtIndex: 2] == 'M') {
				[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 4] toDictionary: dict];
				[self addCase: [tags characterAtIndex: 5] toDictionary: dict];
				dict[@"atype"] = @"poss";
			} else if ([tags characterAtIndex: 1] == 'C') {
				[self addGender: [tags characterAtIndex: 2] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 3] toDictionary: dict];
				[self addNegation: [tags characterAtIndex: 4] toDictionary: dict];
				dict[@"atype"] = @"short";
			} else {
				[self addGender: [tags characterAtIndex: 1] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 2] toDictionary: dict];
				[self addCase: [tags characterAtIndex: 3] toDictionary: dict];
				[self addDegree: [tags characterAtIndex: 4] toDictionary: dict];
				[self addNegation: [tags characterAtIndex: 5] toDictionary: dict];
				dict[@"atype"] = @"long";
			}
			break;
		case 'C':
			dict[@"type"] = @"word";
			dict[@"pos"] = @"num";
			if ([tags characterAtIndex: 1] == 'M') {
				dict[@"numtype"] = @"adv_ord";
			} else if ([tags characterAtIndex: 1] == 'I') {
				dict[@"numtype"] = @"indef";
				[self addCase: [tags characterAtIndex: 2] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'G') {
				dict[@"numtype"] = @"card";
				[self addGender: [tags characterAtIndex: 2] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 3] toDictionary: dict];
				[self addCase: [tags characterAtIndex: 4] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'D') {
				dict[@"numtype"] = @"card_pl";
				[self addGender: [tags characterAtIndex: 2] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 3] toDictionary: dict];
				[self addCase: [tags characterAtIndex: 4] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'B') {
				dict[@"numtype"] = @"card";
				[self addNumber: [tags characterAtIndex: 2] toDictionary: dict];
				[self addCase: [tags characterAtIndex: 3] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'R') {
				dict[@"numtype"] = @"ord";
				[self addGender: [tags characterAtIndex: 2] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 3] toDictionary: dict];
				[self addCase: [tags characterAtIndex: 4] toDictionary: dict];
			} else { NSLog(@"unknown numeral subtype"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			break;
		case 'V':
			dict[@"type"] = @"word";
			dict[@"pos"] = @"verb";
			if ([tags characterAtIndex: 1] == 'R') {
				dict[@"vform"] = @"lpart";
				dict[@"voice"] = @"act";
				dict[@"tense"] = @"past";
				[self addGender: [tags characterAtIndex: 2] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 3] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'S') {
				dict[@"vform"] = @"part_short";
				dict[@"voice"] = @"pas";
				dict[@"tense"] = @"past";
				[self addGender: [tags characterAtIndex: 2] toDictionary: dict];
				[self addNumber: [tags characterAtIndex: 3] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'V') {
				dict[@"vform"] = @"transgr";
				dict[@"voice"] = @"act";
				dict[@"tense"] = @"past";
				[self addNumber: [tags characterAtIndex: 2] toDictionary: dict];
				[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'G') {
				dict[@"vform"] = @"transgr";
				dict[@"voice"] = @"act";
				dict[@"tense"] = @"pres";
				[self addNumber: [tags characterAtIndex: 2] toDictionary: dict];
				[self addGender: [tags characterAtIndex: 3] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'P') {
				dict[@"vform"] = @"fin";
				dict[@"voice"] = @"act";
				dict[@"tense"] = @"pres";
				[self addNumber: [tags characterAtIndex: 2] toDictionary: dict];
				[self addPerson: [tags characterAtIndex: 3] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'M') {
				dict[@"vform"] = @"imp";
				dict[@"voice"] = @"act";
				dict[@"tense"] = @"pres";
				[self addNumber: [tags characterAtIndex: 2] toDictionary: dict];
				[self addPerson: [tags characterAtIndex: 3] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'C') {
				dict[@"vform"] = @"cond";
				dict[@"voice"] = @"act";
				dict[@"tense"] = @"pres";
				[self addNumber: [tags characterAtIndex: 2] toDictionary: dict];
				[self addPerson: [tags characterAtIndex: 3] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'U') {
				dict[@"vform"] = @"fin";
				dict[@"voice"] = @"act";
				dict[@"tense"] = @"fut";
				[self addNumber: [tags characterAtIndex: 2] toDictionary: dict];
				[self addPerson: [tags characterAtIndex: 3] toDictionary: dict];
			} else if ([tags characterAtIndex: 1] == 'F') {
				dict[@"vform"] = @"inf";
				dict[@"voice"] = @"act";
				dict[@"tense"] = @"pres";
			} else { NSLog(@"unknown verb subtype"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			break;
		case 'I':
			dict[@"type"] = @"word";
			dict[@"pos"] = @"interj";
			break;
		case 'H':
			if ([tags isEqual: @"HYPH"]) {
				dict[@"type"] = @"word";
				dict[@"pos"] = @"a";
				dict[@"atype"] = @"hyph";
			} else { NSLog(@"unknown pos"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			break;
		case 'X':
			if (tags.length == 1) {
				dict[@"type"] = @"word";
				dict[@"pos"] = @"x_unknown";
			} else if ([tags isEqual: @"XABBR"]) {
				dict[@"type"] = @"word";
				dict[@"pos"] = @"abbr";
			} else { NSLog(@"unknown pos"); NSLog(@"---- %@ %@", dict, tags); exit(1); }
			break;
		default:
			NSLog(@"unknown pos"); NSLog(@"---- %@ %@", dict, tags); exit(1);
	}
}

- (void)addGender:(unichar)value toDictionary:(NSMutableDictionary*)dict {
	switch (value) {
		case 'M': dict[@"gender"] = @"masca"; break;
		case 'I': dict[@"gender"] = @"masci"; break;
		case 'F': dict[@"gender"] = @"fem"; break;
		case 'N': dict[@"gender"] = @"neut"; break;
		case 'X': break;
		default: NSLog(@"unknown value for gender: %c", value);
			NSLog(@"%@", dict); exit(1);
	}
}

- (void)addPronGender:(unichar)value toDictionary:(NSMutableDictionary*)dict {
	switch (value) {
		case 'M': dict[@"prongender"] = @"masca"; break;
		case 'I': dict[@"prongender"] = @"masci"; break;
		case 'F': dict[@"prongender"] = @"fem"; break;
		case 'N': dict[@"prongender"] = @"neut"; break;
		case 'X': break;
		default: NSLog(@"unknown value for prongender: %c", value);
			NSLog(@"%@", dict); exit(1);
	}
}

- (void)addNumber:(unichar)value toDictionary:(NSMutableDictionary*)dict {
	switch (value) {
		case 'S': dict[@"number"] = @"sg"; break;
		case 'D': dict[@"number"] = @"du"; break;
		case 'P': dict[@"number"] = @"pl"; break;
		case 'X': break;
		default: NSLog(@"unknown value for number: %c", value);
			NSLog(@"%@", dict); exit(1);
	}
}

- (void)addPronNumber:(unichar)value toDictionary:(NSMutableDictionary*)dict {
	switch (value) {
		case 'S': dict[@"pronnumber"] = @"sg"; break;
		case 'P': dict[@"pronnumber"] = @"pl"; break;
		case 'X': break;
		default: NSLog(@"unknown value for pronnumber: %c", value);
			NSLog(@"%@", dict); exit(1);
	}
}

- (void)addNegation:(unichar)value toDictionary:(NSMutableDictionary*)dict {
	if (dict[@"negation"]) return;
	switch (value) {
		case '@':
		case 'A': dict[@"negation"] = @"0"; break;
		case 'N': dict[@"negation"] = @"1"; break;
		default: NSLog(@"unknown value for negation: %c", value);
			NSLog(@"%@", dict); exit(1);
	}
}

- (void)addDegree:(unichar)value toDictionary:(NSMutableDictionary*)dict {
	switch (value) {
		case '1':
		case '@': dict[@"degree"] = @"1"; break;
		case '2':
		case '#': dict[@"degree"] = @"2"; break;
		case '3':
		case '&': dict[@"degree"] = @"3"; break;
		case 'B': break;
		default: NSLog(@"unknown value for degree: %c", value);
			NSLog(@"%@", dict); exit(1);
	}
}

- (void)addPerson:(unichar)value toDictionary:(NSMutableDictionary*)dict {
	switch (value) {
		case '1': dict[@"person"] = @"1"; break;
		case '2': dict[@"person"] = @"2"; break;
		case '3': dict[@"person"] = @"3"; break;
		default: NSLog(@"unknown value for person: %c", value);
			NSLog(@"%@", dict); exit(1);
	}
}

- (void)addCase:(unichar)value toDictionary:(NSMutableDictionary*)dict {
	switch (value) {
		case '1': dict[@"case"] = @"nom"; break;
		case '2': dict[@"case"] = @"gen"; break;
		case '3': dict[@"case"] = @"dat"; break;
		case '4': dict[@"case"] = @"acc"; break;
		case '5': dict[@"case"] = @"voc"; break;
		case '6': dict[@"case"] = @"loc"; break;
		case '7': dict[@"case"] = @"ins"; break;
		case 'X': break;
		default: NSLog(@"unknown value for case: %c", value);
			NSLog(@"%@", dict); exit(1);
	}
}

- (NSArray*)analyze:(NSString*)form {
	NSMutableArray* result = [[NSMutableArray alloc] init];
	@autoreleasepool {
		if (form.length > 6 && [[form substringToIndex: 5] isEqual: @"nejne"]) {
			NSString* form2 = [form substringFromIndex: 5];
			NSArray* result2 = [self analyzeCore: form2 withPrefix: (PREFIX_NEJ | PREFIX_NE) acceptUnknown: NO];
			[result addObjectsFromArray: result2];
		}
		if (form.length > 4 && [[form substringToIndex: 3] isEqual: @"nej"]) {
			NSString* form2 = [form substringFromIndex: 3];
			NSArray* result2 = [self analyzeCore: form2 withPrefix: PREFIX_NEJ acceptUnknown: NO];
			[result addObjectsFromArray: result2];
		}
		if (form.length > 3 && [[form substringToIndex: 2] isEqual: @"ne"]) {
			NSString* form2 = [form substringFromIndex: 2];
			NSArray* result2 = [self analyzeCore: form2 withPrefix: PREFIX_NE acceptUnknown: NO];
			[result addObjectsFromArray: result2];
		}
		NSArray* result2 = [self analyzeCore: form withPrefix: 0 acceptUnknown: result.count == 0];
		[result addObjectsFromArray: result2];
		if (result.count == 0) [result addObject: @[form, @"UNKNOWN"]];
		//NSLog(@"-- %@ %@", form, [result description]);
		return result;
	}
}

- (NSMutableArray*)analyzeCore:(NSString*)form withPrefix:(int)cutPrefix acceptUnknown:(BOOL)acceptUnknown {
	NSMutableArray* forms = [[NSMutableArray alloc] init];
	int i;
	for (i = 1; i <= form.length; i++) {
		NSString* prefix = [form substringToIndex: i];
		NSArray* infos = prefixes[prefix];
		if (infos != nil) {
			NSEnumerator* enumerator = [infos objectEnumerator];
			NSArray* info;
			while (info = [enumerator nextObject]) {
				NSString* paradigm = info[0];
				NSString* lemma = info[1];
				if ([lemma rangeOfString: @"`"].location != NSNotFound) {
					NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString: @"`"];
					lemma = [lemma splitBy: separators][0];
				}
				id tagset = info[2];
				NSArray* infos2 = paradigms[paradigm];
				NSEnumerator* enumerator2 = [infos2 objectEnumerator];
				NSArray* info2;
				while (info2 = [enumerator2 nextObject]) {
					id ending = info2[0];
					if (((i == form.length) && (ending == [NSNull null])) ||
					  ((i < form.length) && ([ending isEqual: [form substringFromIndex: i]]))) {
						id tagset2 = info2[1];
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
							[forms addObject: @[lemma, tagset != [NSNull null] ? tagset : tagset2]];
							//NSLog(@"---- %@ %@", lemma, tagset2);
					}
				}
			}
		}
	}
	return forms;
}

- (NSArray*)analyzeTaggedArray:(NSArray*)sentence {
	NSMutableArray* array = [NSMutableArray arrayWithCapacity: sentence.count];
	NSEnumerator* enumerator0 = [sentence objectEnumerator];
	NSArray* element0; unsigned order = 0;
	while (element0 = [enumerator0 nextObject]) {
		id element; order++;
		NSString* sOrder = [NSNumber numberWithInt: order].description;
		NSString* token = element0[0];
		NSString* lemma = element0[1];
		id tags = element0[2];
				NSString* lowercaseToken = token.lowercaseString;
				//NSArray* morph = [self analyze: lowercaseToken];
				//if ([token isEqual: @"SQL"]) NSLog(@"%@ %@", token, morph);
				if (tags == [NSNull null] || [tags characterAtIndex: 0] == 'X') {
					//NSLog(@"1 %@ %@ %@", token, lemma, tags);
					element = @{@"order": sOrder, @"type": @"unknown", @"form": token};
				} else {
					id longTag = tags;
					tags = tagMap[longTag];
					if (tags == nil) {
						if ([longTag characterAtIndex: 10] == 'A') {
							longTag = [longTag mutableCopy];
							[longTag replaceCharactersInRange: NSMakeRange(10, 1) withString: @"@"];
							tags = tagMap[longTag];
						}
						if ([longTag characterAtIndex: 10] == 'N') {
							longTag = [longTag mutableCopy];
							[longTag replaceCharactersInRange: NSMakeRange(10, 1) withString: @"@"];
							tags = tagMap[longTag];
						}
						if ([longTag characterAtIndex: 9] == '3') {
							longTag = [longTag mutableCopy];
							[longTag replaceCharactersInRange: NSMakeRange(9, 1) withString: @"1"];
							tags = tagMap[longTag];
						} //else NSLog(@"%c", [longTag characterAtIndex: 9]);
					}
					if (tags == nil) {
						NSLog(@"unknown tag mapping: %@ %@ %lu", lemma, longTag, tagMap.count);
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
						if (lowercaseToken.length == 1 && [tags characterAtIndex: 0] == 'N') continue;
						if (lowercaseToken.length == 1 && [tags characterAtIndex: 0] == 'A') continue;
						if (lowercaseToken.length == 1 && [tags characterAtIndex: 0] == 'P') continue;
						if (lowercaseToken.length == 1 && [tags characterAtIndex: 0] == 'V') continue;
						if (lowercaseToken.length == 1 && [tags isEqual: @"CX"]) continue;
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
							if (token.length > 1 && [token isEqual: token.uppercaseString]) dict[@"capitalized"] = @"all";
							else if ([token isEqual: token.capitalizedString]) dict[@"capitalized"] = @"first";
							[self enrich: dict];
							[element addObject: dict];
						}
		}
		[array addObject: element];
		element = @{@"type": @"shackle"};
		[array addObject: element];
	}
	return array;
}

- (NSArray*)analyzeArray:(NSArray*)sentence {
	NSCharacterSet* noteCharacters = [NSCharacterSet characterSetWithCharactersInString: @",.;:()[]{}\'\"<>-"];
	NSMutableArray* array = [NSMutableArray arrayWithCapacity: sentence.count];
	NSEnumerator* enumerator = [sentence objectEnumerator];
	NSString* token; unsigned order = 0;
	while (token = [enumerator nextObject]) {
		id element; order++;
		NSString* sOrder = [NSNumber numberWithInt: order].description;
		if (token.length == 1 && [noteCharacters characterIsMember: [token characterAtIndex: 0]]) {
			element = @{@"order": sOrder, @"type": @"note", @"form": token};
		} else {
			NSScanner* scanner = [NSScanner scannerWithString: token];
			int n;
			BOOL scanned = [scanner scanInt: &n];
			if (scanned == YES && token.length == scanner.scanLocation) {
				element = @{@"order": sOrder, @"type": @"number", @"form": token};
			} else {
				NSString* lowercaseToken = token.lowercaseString;
				NSArray* morph = [self analyze: lowercaseToken];
				//if ([token isEqual: @"SQL"]) NSLog(@"%@ %@", token, morph);
				if (morph == nil) {
					element = @{@"order": sOrder, @"type": @"unknown", @"form": token};
				} else {
					element = [NSMutableSet setWithCapacity: morph.count];
					NSEnumerator* enumerator2 = [morph objectEnumerator];
					NSArray* lemmaAndTag;
					while (lemmaAndTag = [enumerator2 nextObject]) {
						NSString* lemma = lemmaAndTag[0];
						NSRange lemmaHyphen = [lemma rangeOfString: @"-"];
						NSString* pureLemma = lemmaHyphen.location == NSNotFound ? lemma : [lemma substringToIndex: lemmaHyphen.location];
						NSString* tags = lemmaAndTag[1];
						// sorting out one-character words which are annotated as nouns
						if (lowercaseToken.length == 1 && [tags characterAtIndex: 0] == 'N') continue;
						if (lowercaseToken.length == 1 && [tags characterAtIndex: 0] == 'A') continue;
						if (lowercaseToken.length == 1 && [tags characterAtIndex: 0] == 'P') continue;
						if (lowercaseToken.length == 1 && [tags characterAtIndex: 0] == 'V') continue;
						if (lowercaseToken.length == 1 && [tags isEqual: @"CX"]) continue;
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
						if (tags.length >= 4 && ([tags characterAtIndex: 0] == 'V' || [tags characterAtIndex: 0] == 'P') && [tags characterAtIndex: 3] == 'Y') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(3, 1) withString: @"M"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(3, 1) withString: @"I"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender Y
						else if (tags.length >= 3 && ([tags characterAtIndex: 0] == 'V' || [tags characterAtIndex: 0] == 'P' || [tags characterAtIndex: 0] == 'C') && [tags characterAtIndex: 2] == 'Y') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"M"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"I"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender Y
						else if (tags.length >= 5 && [tags characterAtIndex: 0] == 'P' && [tags characterAtIndex: 4] == 'Y') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(4, 1) withString: @"M"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(4, 1) withString: @"I"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender H
						else if (tags.length >= 5 && [tags characterAtIndex: 0] == 'P' && [tags characterAtIndex: 4] == 'H') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(4, 1) withString: @"F"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(4, 1) withString: @"N"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender H
						else if (tags.length >= 5 && [tags characterAtIndex: 0] == 'C' && [tags characterAtIndex: 2] == 'H') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"F"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"N"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender Z
						else if (tags.length >= 4 && [tags characterAtIndex: 0] == 'P' && [tags characterAtIndex: 3] == 'Z') {
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
						else if (tags.length >= 4 && ([tags characterAtIndex: 0] == 'P' || [tags characterAtIndex: 0] == 'C') && [tags characterAtIndex: 2] == 'Z') {
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
						else if (tags.length >= 5 && [tags characterAtIndex: 0] == 'P' && [tags characterAtIndex: 4] == 'Z') {
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
						else if (tags.length >= 3 && [tags characterAtIndex: 0] == 'V' && [tags characterAtIndex: 2] == 'T') {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"I"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 1) withString: @"F"];
							[unrolledTags addObject: mutableTags];
							//NSLog(@"##### unrolled %@", unrolledTags);
						}
						
						// unrolling gender/number Q
						else if (tags.length >= 4 && [[tags substringWithRange: NSMakeRange(0, 4)] isEqual: @"VRQX"]) {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 2) withString: @"FS"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 2) withString: @"NP"];
							[unrolledTags addObject: mutableTags];
						}
						
						// unrolling gender/number Q
						else if (tags.length >= 4 && [[tags substringWithRange: NSMakeRange(0, 4)] isEqual: @"VSQX"]) {
							NSMutableString* mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 2) withString: @"FS"];
							[unrolledTags addObject: mutableTags];
							mutableTags = [tags mutableCopy];
							[mutableTags replaceCharactersInRange: NSMakeRange(2, 2) withString: @"NP"];
							[unrolledTags addObject: mutableTags];
						}
						
						// unrolling gender/number Q
						else if (tags.length >= 4 && [[tags substringWithRange: NSMakeRange(0, 4)] isEqual: @"ACQX"]) {
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
							if (token.length > 1 && [token isEqual: token.uppercaseString]) dict[@"capitalized"] = @"all";
							else if ([token isEqual: token.capitalizedString]) dict[@"capitalized"] = @"first";
							[self enrich: dict];
							[element addObject: dict];
						}
					}
				}
			}
		}
		[array addObject: element];
		element = @{@"type": @"shackle"};
		[array addObject: element];
	}
	return array;
}
@end
