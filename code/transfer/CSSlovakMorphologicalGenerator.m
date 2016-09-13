//
//  CSSlovakMorphologicalGenerator.m
//  CzSk
//
//  Created by Petr Homola on 21.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CSSlovakMorphologicalGenerator.h"
#import "QX_String.h"

@implementation CSSlovakMorphologicalGenerator
- (id)init {
	if (self = [super init]) {
		fileName = @"/home/jernej/projekti/projekti/cesilko/cssl/data/skm.txt";
		[self load];
	}
	return self;
}

- (id)initWithFile:(NSString*)_fileName {
	if (self = [super init]) {
		fileName = _fileName;;
		[self load];
	}
	return self;
}

- (void)dealloc {
	[prefixes release];
	[paradigms release];
	[lemmas release];
	[super dealloc];
}

- (void)load {
	//[self load2]; exit(0);
	prefixes = [[NSMutableDictionary alloc] init];
	paradigms = [[NSMutableDictionary alloc] init];
	lemmas = [[NSMutableDictionary alloc] init];
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	//NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString: @"|"];
//JERNEJ changed this line	
	FILE* file = fopen("/home/jernej/projekti/projekti/cesilko/cssl/data/skm.txt", "r");
	char line[1000]; //int n = 0;
	while (fgets(line, 1000, file) != NULL) {
		//if (++n % 1000 == 0) NSLog(@"%d", n);
		if (line[0] == 'R') {
			//NSArray* array = [[NSString stringWithUTF8String: line] splitBy: separators];
			NSArray* array = [[NSString stringWithUTF8String: line] componentsSeparatedByString: @"|"];
			NSString* paradigm = [array objectAtIndex: 1];
			NSString* prefix = [[array objectAtIndex: 2] lowercaseString];
			NSString* lemma = [[array objectAtIndex: 3] lowercaseString];
			id tagset = [array objectAtIndex: 4];
			if ([tagset isEqual: @"0"]) tagset = [NSNull null];
			NSMutableArray* info = [prefixes objectForKey: prefix];
			if (info == nil) {
				info = [NSMutableArray array];
				[prefixes setObject: info forKey: prefix];
			}
			[info addObject: [NSArray arrayWithObjects: paradigm, lemma, tagset, nil]];
			NSMutableSet* set = [lemmas objectForKey: lemma];
			if (set == nil) {
				set = [NSMutableSet set];
				[lemmas setObject: set forKey: lemma];
			}
			[set addObject: prefix];
		} else if (line[0] == 'E') {
			//NSArray* array = [[NSString stringWithUTF8String: line] splitBy: separators];
			NSArray* array = [[NSString stringWithUTF8String: line] componentsSeparatedByString: @"|"];
			NSString* paradigm = [array objectAtIndex: 1];
			id ending = [array objectAtIndex: 4];
			if ([ending isEqual: @"0"]) ending = [NSNull null];
			NSString* tagset = [array objectAtIndex: 5];
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
	
	//NSLog(@"ok %@", [[self generate: [NSString stringWithUTF8String: "dovolený"] tagPrefix: @"A"] description]); exit(0);
}

- (NSArray*)generate:(NSString*)lemma tagPrefix:(id)tagPrefix {
	//NSLog(@"##### %@ %@", lemma, tagPrefix);
	BOOL superlative = NO;
	NSRange range = [tagPrefix rangeOfString: @"_N"];
	BOOL neg = NO;
	if (range.location != NSNotFound) {
		neg = YES;
		tagPrefix = [tagPrefix substringToIndex: range.location];
		//NSLog(@"##### ok %@ %@", lemma, tagPrefix);
	}
	// for tagged sentences
	if ([tagPrefix characterAtIndex: [tagPrefix length] - 1] == 'A') {
		if ([tagPrefix characterAtIndex: 0] != 'D') {
			//NSLog(@"@@@@@ %@ %@", lemma, tagPrefix);
			tagPrefix = [tagPrefix mutableCopy];
			[tagPrefix replaceCharactersInRange: NSMakeRange([tagPrefix length] - 1, 1) withString: @"@"];
		}
	}
	id tagPrefix2 = tagPrefix;
	if ([tagPrefix characterAtIndex: 0] == 'A' && [tagPrefix rangeOfString: @"&@"].location == [tagPrefix length] - 2) {
		superlative = YES;
		tagPrefix2 = [NSMutableString stringWithString: tagPrefix];
		[tagPrefix2 replaceCharactersInRange: NSMakeRange([tagPrefix2 length] - 2, 1) withString: @"#"];
	}
	return [self generateCore: lemma tagPrefix: tagPrefix2 superlative: superlative negation: neg];
}

- (NSArray*)generateCore:(NSString*)lemma tagPrefix:(NSString*)tagPrefix superlative:(BOOL)superlative negation:(BOOL)negation {
	NSMutableArray* forms = [NSMutableArray array];
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSSet* set = [lemmas objectForKey: lemma];
	tagPrefix = [self cutTag: tagPrefix forLemma: &lemma];
	NSEnumerator* enumerator = [set objectEnumerator];
	NSString* prefix;
	while (prefix = [enumerator nextObject]) {
		NSArray* infos = [prefixes objectForKey: prefix];
		NSEnumerator* enumerator2 = [infos objectEnumerator];
		NSArray* info;
		while (info = [enumerator2 nextObject]) {
			NSString* lemma2 = [info objectAtIndex: 1];
			if ([lemma isEqual: lemma2]) {
				id tagset = [info objectAtIndex: 2];
				if (tagset != [NSNull null] && [tagset rangeOfString: tagPrefix].location == 0) {
					if (![forms containsObject: prefix]) {
						if (!negation) [forms addObject: prefix];
						else [forms addObject: [@"ne" stringByAppendingString: prefix]];
					}
				}
				id paradigm = [info objectAtIndex: 0];
				if (paradigm != [NSNull null]) {
					infos = [paradigms objectForKey: paradigm];
					NSEnumerator* enumerator3 = [infos objectEnumerator];
					while (info = [enumerator3 nextObject]) {
						tagset = [info objectAtIndex: 1];
						if ([tagset rangeOfString: tagPrefix].location == 0) {
							id ending = [info objectAtIndex: 0];
							NSString* form = ending == [NSNull null] ? prefix : [prefix stringByAppendingString: ending];
							if (superlative) form = [@"naj" stringByAppendingString: form];
							if (![forms containsObject: form]) {
								if (!negation) [forms addObject: form];
								else [forms addObject: [@"ne" stringByAppendingString: form]];
								
							}
						}
					}
				}
			}
		}
	}
	[pool release];
	if ([forms count] == 0) {
		if (![tagPrefix isEqual: @"T"]) {
			NSString* message = [NSString stringWithFormat: @"cannot generate %@ for %@", lemma, tagPrefix];
			[[self class] log: message];
		}
		if (!negation) [forms addObject: lemma];
		else [forms addObject: [@"ne" stringByAppendingString: lemma]];
	}
	return forms;
}

- (void)load2 {
	prefixes = [[NSMutableDictionary alloc] init];
	paradigms = [[NSMutableDictionary alloc] init];
	NSMutableDictionary* redirects = [[NSMutableDictionary alloc] init];
	//NSMutableDictionary* lemmas = [[NSMutableDictionary alloc] init];
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString: @","];
	
	FILE* outFile = fopen("/Users/phomola/dev/data/skm.txt_", "w");
	
	FILE* file = fopen("/Users/phomola/dev/data/skmorf.dist", "r");
	char line[1000];
	while (fgets(line, 1000, file) != NULL) {
		if (line[0] == '#') continue;
		NSArray* array = [[NSString stringWithUTF8String: line] split];
		NSString* paradigm = [array objectAtIndex: 0];
		array = [[array objectAtIndex: 1] splitBy: separators];
		id infix = [array objectAtIndex: 0];
		if ([infix isEqual: @"0"]) infix = [NSNull null];
		NSString* redirect = [array objectAtIndex: 1];
		id lemmaEnding = [array objectAtIndex: 3];
		if ([lemmaEnding isEqual: @"0"]) lemmaEnding = [NSNull null];
		NSMutableArray* infos = [redirects objectForKey: paradigm];
		if (infos == nil) {
			infos = [NSMutableArray array];
			[redirects setObject: infos forKey: paradigm];
		}
		[infos addObject: [NSArray arrayWithObjects: infix, redirect, lemmaEnding, nil]];
	}
	fclose(file);
	
	NSCharacterSet* separators3 = [NSCharacterSet characterSetWithCharactersInString: @"]"];
	NSCharacterSet* separators4 = [NSCharacterSet characterSetWithCharactersInString: @"["];
	file = fopen("/Users/phomola/dev/data/skmorf.end", "r");
	NSString* paradigm; NSArray* array;
	while (fgets(line, 1000, file) != NULL) {
		NSString* line2 = [[NSString stringWithUTF8String: line] trim];
		if (line[0] == '#' || line[0] == '>' || [line2 length] == 0) continue;
		if (line[0] != ' ') {
			array = [line2 split];
			paradigm = [array objectAtIndex: 0];
			if ([array count] < 2) NSLog(@"!!! %@", line2);
			line2 = [array objectAtIndex: 1];
		}
		array = [line2 splitBy: separators3];
		int i;
		for (i = 0; i < [array count] - 1; i++) {
			NSArray* array2 = [[array objectAtIndex: i] splitBy: separators4];
			NSString* token = [array2 objectAtIndex: 0];
			unichar c = [token characterAtIndex: 0];
			if (c == ',' || c == '+') token = [token substringFromIndex: 1];
			id ending = token;
			if ([ending isEqual: @"0"]) ending = [NSNull null];
			NSArray* tagsets = [[array2 objectAtIndex: 1] splitBy: separators];
			NSMutableArray* infos = [paradigms objectForKey: paradigm];
			if (infos == nil) {
				infos = [NSMutableArray array];
				[paradigms setObject: infos forKey: paradigm];
			}
			[infos addObject: [NSArray arrayWithObjects: ending, tagsets, nil]];
			
			if (ending == [NSNull null]) ending = @"0";
			NSEnumerator* enumerator = [tagsets objectEnumerator];
			NSString* tagset;
			while (tagset = [enumerator nextObject]) {
				if ([ending characterAtIndex: 0] == '+') ending = [ending substringFromIndex: 1];
				fprintf(outFile, "E|%s|0|0|%s|%s|xxx\n", [paradigm UTF8String], [ending UTF8String], [tagset UTF8String]);
			}
		}
	}
	fclose(file);
	
	NSCharacterSet* separators1 = [NSCharacterSet characterSetWithCharactersInString: @"+"];
	NSCharacterSet* separators2 = [NSCharacterSet characterSetWithCharactersInString: @"/"];
	NSCharacterSet* separators5 = [NSCharacterSet characterSetWithCharactersInString: @"_"];
	file = fopen("/Users/phomola/dev/data/skmorf.stm", "r");
	//int n = 0;
	while (fgets(line, 1000, file) != NULL) {
		//if (++n % 1000 == 0) NSLog(@"%d", n);
		if (line[0] == '#') continue;
		NSArray* array = [[NSString stringWithUTF8String: line] split];
		NSString* prefix = [array objectAtIndex: 0];
		NSString* paradigm = [array objectAtIndex: 1];
		array = [[[array objectAtIndex: 2] substringFromIndex: 1] splitBy: separators1];
		NSString* lemma = [array objectAtIndex: 0];
		lemma = [[lemma splitBy: separators5] objectAtIndex: 0];
		id tagsets = [NSNull null];
		if ([array count] == 2) {
			NSString* tmp = [[[array objectAtIndex: 1] splitBy: separators5] objectAtIndex: 0];
			tagsets = [tmp splitBy: separators2];
		}
		NSMutableArray* infos = [prefixes objectForKey: prefix];
		if (infos == nil) {
			infos = [NSMutableArray array];
			[prefixes setObject: infos forKey: prefix];
		}
		NSRange range = [lemma rangeOfString: @"`"];
		if (range.location != NSNotFound) {
			NSRange range2 = [lemma rangeOfString: @"-"];
			if (range2.location == NSNotFound) lemma = [lemma substringToIndex: range.location];
			else lemma = [[lemma substringToIndex: range.location] stringByAppendingString: [lemma substringFromIndex: range2.location]];
		}
		[infos addObject: [NSArray arrayWithObjects: paradigm, lemma, tagsets, nil]];
		
		infos = [paradigms objectForKey: paradigm];
		//if ([prefix isEqual: @"dovol"]) NSLog(@"1 -- %@ %@ %@ %d", paradigm, lemma, [tagsets description], infos == nil);
		if (infos != nil || tagsets != [NSNull null]) {
			if (tagsets == [NSNull null]) {
				if (![paradigm isEqual: @"0"]) fprintf(outFile, "R|%s|%s|%s|0|xxx\n", [paradigm UTF8String], [prefix UTF8String], [lemma UTF8String]);
			} else {
				NSEnumerator* enumerator = [tagsets objectEnumerator];
				NSString* tagset;
				while (tagset = [enumerator nextObject]) {
					fprintf(outFile, "R|%s|%s|%s|%s|xxx\n", [paradigm UTF8String], [prefix UTF8String], [lemma UTF8String], [tagset UTF8String]);
				}
			}
		}
		if (![paradigm isEqual: @"0"]) {
			infos = [redirects objectForKey: paradigm];
			//if ([prefix isEqual: @"dovol"]) NSLog(@"2 -- %@ %@ %@ %d", paradigm, lemma, [tagsets description], infos == nil);
			if (infos != nil) {
				NSEnumerator* enumerator = [infos objectEnumerator];
				NSArray* info;
				while (info = [enumerator nextObject]) {
					id infix = [info objectAtIndex: 0];
					NSString* redirect = [info objectAtIndex: 1];
					id lemmaEnding = [info objectAtIndex: 2];
					NSString* prefix2 = infix == [NSNull null] ? prefix : [prefix stringByAppendingString: infix];
					if (lemmaEnding != [NSNull null] && [lemmaEnding characterAtIndex: 0] == '+') {
						NSEnumerator* enumerator2 = [[[lemmaEnding substringFromIndex: 1] splitBy: separators2] objectEnumerator];
						NSString* tag;
						while ((tag = [enumerator2 nextObject])) {
							//NSLog(@"%@", [prefix stringByAppendingString: infix]);
							fprintf(outFile, "R|%s|%s|%s|%s|xxx\n", [redirect UTF8String], [(infix == [NSNull null] ? prefix : [prefix stringByAppendingString: infix]) UTF8String], [lemma UTF8String], [tag UTF8String]);
							//if ([lemma length] >= 5 && [[lemma substringToIndex: 5] isEqual: [NSString stringWithUTF8String: "vedúc"]]) NSLog(@"#### %@ %@ %@ %@ %@", lemma, tag, prefix, infix, redirect);
						}
					} else {
						NSString* lemma2 = lemmaEnding == [NSNull null] ? lemma : [prefix stringByAppendingString: lemmaEnding];
						NSRange range = [lemma2 rangeOfString: @"+"];
						if (range.location != NSNotFound) {
							NSEnumerator* enumerator2 = [[[lemma2 substringFromIndex: range.location + 1] splitBy: separators2] objectEnumerator];
							lemma2 = [lemma2 substringToIndex: range.location];
							NSString* tag;
							while ((tag = [enumerator2 nextObject])) {
								fprintf(outFile, "R|%s|%s|%s|%s|xxx\n", [redirect UTF8String], [prefix2 UTF8String], [lemma2 UTF8String], [tag UTF8String]);
							}
						} else {
							fprintf(outFile, "R|%s|%s|%s|0|xxx\n", [redirect UTF8String], [prefix2 UTF8String], [lemma2 UTF8String]);
						}
					}
				}
			}
		}
	}
	fclose(file);
	
	fclose(outFile); exit(0);
	[pool release]; /**/
}

- (NSArray*)generateArray:(NSArray*)sentence {
	NSMutableArray* result = [NSMutableArray arrayWithCapacity: [sentence count]];
	NSEnumerator* enumerator = [sentence objectEnumerator];
	NSArray* array;
	while (array = [enumerator nextObject]) {
		NSArray* target = [self generateSentence: array];
		[result addObject: target];
	}
	return result;
}

- (NSString*)cutTag:(NSString*)tag forLemma:(NSString**)lemma {
	if ([tag rangeOfString: @"DB"].location == 0) return @"T";
	if ([tag rangeOfString: @"VPS2A"].location == 0) return @"VPS2@";
	if ([tag rangeOfString: @"VPS3A"].location == 0) return @"VPS3@";
	if ([tag rangeOfString: @"VG"].location == 0) return @"VT@";
	if ([tag rangeOfString: @"VV"].location == 0) return @"VT@";
	if ([tag rangeOfString: @"VC"].location == 0) { *lemma = @"by"; return @"VC@"; }
	//if ([tag isEqual: @""]) return @"";
	
	if ([tag isEqual: @"VRMS@"]) return @"VRYS@";
	if ([tag isEqual: @"VRIS@"]) return @"VRYS@";
	if ([tag isEqual: @"VRMP@"]) return @"VRXP@";
	if ([tag isEqual: @"VRIP@"]) return @"VRXP@";
	if ([tag isEqual: @"VRNP@"]) return @"VRXP@";
	if ([tag isEqual: @"VRFP@"]) return @"VRXP@";
	if ([tag isEqual: @"VRTP@"]) return @"VRXP@";
	
	if ([tag isEqual: @"CRNP2"]) return @"CRXP2";
	if ([tag isEqual: @"CRIP2"]) return @"CRXP2";
	if ([tag isEqual: @"CRFP2"]) return @"CRXP2";
	if ([tag isEqual: @"CRMP2"]) return @"CRXP2";
	if ([tag isEqual: @"CRNP6"]) return @"CRXP6";
	if ([tag isEqual: @"CRIP6"]) return @"CRXP6";
	if ([tag isEqual: @"CRFP6"]) return @"CRXP6";
	if ([tag isEqual: @"CRMP6"]) return @"CRXP6";
	
	if ([tag isEqual: @"PAEFS4"]) return @"PQFFS4"; // již -> ktorú
	
	if ([tag isEqual: @"PS1SFS1"]) return @"PS1XSFS1";
	if ([tag isEqual: @"PS1PMS5"]) return @"PS1XPMS1";
	if ([tag isEqual: @"PS1PIS5"]) return @"PS1XPIS1";
	if ([tag isEqual: @"PS1PIS4"]) return @"PS1XPIS4";
	if ([tag isEqual: @"PS1PIS5"]) return @"PS1XPIS1";
	if ([tag isEqual: @"PS1SNP4"]) return @"PS1XSNP4";
	if ([tag isEqual: @"PS1PIS1"]) return @"PS1XPIS1";
	if ([tag isEqual: @"PS1SFS5"]) return @"PS1XSFS5";
	if ([tag isEqual: @"PS1SNP1"]) return @"PS1XSNP1";
	if ([tag isEqual: @"PS1PMS1"]) return @"PS1SNP5";
	
	if ([tag isEqual: @"PLZS6"]) return @"PLMS6";
	
	if ([tag isEqual: @"PP2P3"]) return @"PP2FXP3";
	if ([tag isEqual: @"PP3YS2"]) return @"PP3FMS2";
	if ([tag isEqual: @"PP3FS4"]) return @"PP3FFS4";
	if ([tag isEqual: @"PP3XP4"]) return @"PP3FMP4";
	if ([tag isEqual: @"PP3NS4"]) return @"PP3FNS4";
	
	if ([tag isEqual: @"PP3RXP2"]) return @"PP3RMP2";
	if ([tag isEqual: @"PP3RXP6"]) return @"PP3RMP6";
	if ([tag isEqual: @"PP3RFS7"]) return @"PP3FFS7";
	
	if ([tag isEqual: @"PRSIP5"]) return @"PRSIP1";
	if ([tag isEqual: @"PRSNS5"]) return @"PRSNS1";
	
	if ([tag isEqual: @"PIC5"]) return @"PIC1";
	
	if ([tag isEqual: @"NFP5@"]) return @"NFP1@";
	if ([tag isEqual: @"NNP5@"]) return @"NNP1@";
	
	//NSLog(@"cut %@", tag);
	return tag;
}

- (NSArray*)generateByExtendingAVMs:(NSArray*)avms {
	NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString: @"-"];
	NSMutableArray* results = [NSMutableArray arrayWithCapacity: [avms count]];
	NSEnumerator* enumerator = [avms objectEnumerator];
	NSMutableDictionary* dict;
	while ((dict = [enumerator nextObject])) {
		NSArray* set;
		NSString* lemma = [dict objectForKey: @"lemma"];
		if (lemma == nil) {
			NSMutableArray* mutableSet = [NSMutableArray arrayWithCapacity: 1];
			if ([dict objectForKey: @"form"] == nil) NSLog(@"%@", dict);
			[mutableSet addObject: [dict objectForKey: @"form"]];
			set = mutableSet;
		} else {
			NSString* tags = [dict objectForKey: @"tags"];
			NSArray* array = [tags splitBy: separators];
			tags = [array objectAtIndex: 0];
			tags = [self cutTag: tags forLemma: &lemma];
			//NSRange range = [tags rangeOfString: @"_"];
			NSString* tagPrefix = tags;
			//if (range.location == NSNotFound) tagPrefix = tags;
			//else tagPrefix = [tags substringToIndex: range.location];
			set = [self generate: lemma tagPrefix: tagPrefix];
			if (set == nil) {
				NSMutableArray* mutableSet = [NSMutableArray arrayWithCapacity: 1];
				[mutableSet addObject: [lemma stringByAppendingString: tags]];
				set = mutableSet;
			}
		}
		NSMutableArray* mutableSet = [NSMutableArray arrayWithCapacity: [set count]];
		NSEnumerator* enumerator2 = [set objectEnumerator];
		NSString* form;
		while (form = [enumerator2 nextObject]) {
			NSString* cap = [dict objectForKey: @"capitalized"];
			if (cap != nil && [cap isEqual: @"all"]) form = [form uppercaseString];
			if (cap != nil && [cap isEqual: @"first"]) form = [form capitalizedString];
			[mutableSet addObject: form];
		}
		[dict setObject: mutableSet forKey: @"target_form"];
		[results addObject: dict];
	}
	return results;
}

- (NSArray*)generateSentence:(NSArray*)sentence {
	NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString: @"-"];
	NSMutableArray* result = [NSMutableArray arrayWithCapacity: [sentence count]];
	NSEnumerator* enumerator = [sentence objectEnumerator];
	NSDictionary* dict;
	while (dict = [enumerator nextObject]) {
		NSArray* set;
		NSString* lemma = [dict objectForKey: @"lemma"];
		if (lemma == nil) {
			NSMutableArray* mutableSet = [NSMutableArray arrayWithCapacity: 1];
			[mutableSet addObject: [dict objectForKey: @"form"]];
			set = mutableSet;
		} else {
			NSString* tags = [dict objectForKey: @"tags"];
			NSArray* array = [tags splitBy: separators];
			tags = [array objectAtIndex: 0];
			tags = [self cutTag: tags forLemma: &lemma];
			//NSRange range = [tags rangeOfString: @"_"];
			NSString* tagPrefix = tags;
			//if (range.location == NSNotFound) tagPrefix = tags;
			//else tagPrefix = [tags substringToIndex: range.location];
			set = [self generate: lemma tagPrefix: tagPrefix];
			if (set == nil) {
				NSMutableArray* mutableSet = [NSMutableArray arrayWithCapacity: 1];
				[mutableSet addObject: [lemma stringByAppendingString: tags]];
				set = mutableSet;
			}
		}
		NSMutableArray* mutableSet = [NSMutableArray arrayWithCapacity: [set count]];
		NSEnumerator* enumerator2 = [set objectEnumerator];
		NSString* form;
		while (form = [enumerator2 nextObject]) {
			NSString* cap = [dict objectForKey: @"capitalized"];
			if (cap != nil && [cap isEqual: @"all"]) form = [form uppercaseString];
			if (cap != nil && [cap isEqual: @"first"]) form = [form capitalizedString];
			[mutableSet addObject: form];
		}
		[result addObject: mutableSet];
	}
	return result;
}

- (NSArray*)analyze:(NSString*)form {
	NSMutableArray* forms = [[NSMutableArray alloc] init];
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
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
				id tagset = [info objectAtIndex: 2];
				NSArray* infos2 = [paradigms objectForKey: paradigm];
				NSEnumerator* enumerator2 = [infos2 objectEnumerator];
				NSArray* info2;
				while (info2 = [enumerator2 nextObject]) {
					id ending = [info2 objectAtIndex: 0];
					if (i == [form length] && ending == [NSNull null] ||
					  i < [form length] && [ending isEqual: [form substringFromIndex: i]]) {
						NSString* tagset2 = [info2 objectAtIndex: 1];
						[forms addObject: [NSArray arrayWithObjects: lemma, tagset != [NSNull null] ? tagset : tagset2, nil]];
					}
				}
			}
		}
	}
	[pool release];
	return [forms autorelease];
}
@end
