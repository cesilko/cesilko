//
//  CSPolishMorphologicalGenerator.m
//  transfer
//
//  Created by Petr Homola on 12.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CSPolishMorphologicalGenerator.h"
#import "QX_String.h"

@implementation CSPolishMorphologicalGenerator
- (id)initWithFile:(NSString*)_fileName {
	if (self = [super init]) {
		fileName = _fileName;
		[self load];
	}
	return self;
}

- (void)load {
	lemmas = [[NSMutableDictionary alloc] initWithCapacity: 500000];
	FILE* file = fopen(fileName.UTF8String, "r");
	char cline[10000]; int n = 0;
	//NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	while (fgets(cline, 10000, file) != NULL) {
		n++;
		if (n % 100000 == 0) {
			NSLog(@"-- %d", n);
			//[pool release];
			//pool = [[NSAutoreleasePool alloc] init];
		}
		NSArray* parts = [[@(cline) trim] split];
		unsigned count = parts.count;
		if (count == 3) {
			NSString* lemma = [parts[1] lowercaseString];
			NSString* form = [parts[0] lowercaseString];
			NSMutableArray* info = lemmas[lemma];
			if (info == nil) {
				info = [NSMutableArray array];
				lemmas[lemma] = info;
			}
			NSArray* tags = [parts[2] componentsSeparatedByString: @"+"];
			NSEnumerator* enumerator = [tags objectEnumerator];
			NSString* tag;
			while (tag = [enumerator nextObject]) {
				//NSLog(@"%@ %@ %@", lemma, form, tag);
				[info addObject: @[form, tag]];
			}
		}
	}
	//[pool release];
	fclose(file);
	NSLog(@"loaded - %u lemmas", lemmas.count);
	//pause();
}

- (NSSet*)generate:(NSString*)lemma attributes:(NSDictionary*)dict {
	NSString* pos = dict[@"pos"];
	NSMutableSet* tags = [NSMutableSet set];
	if ([pos isEqual: @"verb"]) {
		[tags addObject: @"verb"];
		if ([dict[@"vform"] isEqual: @"inf"]) {
			[tags addObject: @"inf"];
		}
		if ([dict[@"vform"] isEqual: @"fin"]) {
			[tags addObject: @"praet"];
			NSString* number = dict[@"number"];
			NSString* person = dict[@"person"];
			if ([number isEqual: @"sg"]) [tags addObject: @"sg"];
			if ([number isEqual: @"pl"]) [tags addObject: @"pl"];
			if ([person isEqual: @"1"]) [tags addObject: @"pri"];
			if ([person isEqual: @"2"]) [tags addObject: @"sec"];
			if ([person isEqual: @"3"]) [tags addObject: @"ter"];
		}
		if ([dict[@"vform"] isEqual: @"lpart"]) {
			[tags addObject: @"praet"];
			NSString* gender = dict[@"gender"];
			NSString* number = dict[@"number"];
			if ([gender isEqual: @"masca"]) [tags addObject: @[@"m1", @"m"]];
			if ([gender isEqual: @"masca"]) [tags addObject: @[@"m2", @"m"]];
			if ([gender isEqual: @"masci"]) [tags addObject: @[@"m3", @"m"]];
			if ([gender isEqual: @"fem"]) [tags addObject: @"f"];
			if ([gender isEqual: @"neut"]) [tags addObject: @"n"];
			if ([number isEqual: @"sg"]) [tags addObject: @"sg"];
			if ([number isEqual: @"pl"]) [tags addObject: @"pl"];
		}
	}
	if ([pos isEqual: @"n"]) {
		[tags addObject: @"subst"];
		NSString* gender = dict[@"gender"];
		NSString* cas = dict[@"case"];
		NSString* number = dict[@"number"];
		if ([gender isEqual: @"masca"]) [tags addObject: @[@"m1", @"m"]];
		if ([gender isEqual: @"masca"]) [tags addObject: @[@"m2", @"m"]];
		if ([gender isEqual: @"masci"]) [tags addObject: @[@"m3", @"m"]];
		if ([gender isEqual: @"fem"]) [tags addObject: @"f"];
		if ([gender isEqual: @"neut"]) [tags addObject: @"n"];
		if ([number isEqual: @"sg"]) [tags addObject: @"sg"];
		if ([number isEqual: @"pl"]) [tags addObject: @"pl"];
		if ([cas isEqual: @"nom"]) [tags addObject: @"nom"];
		if ([cas isEqual: @"gen"]) [tags addObject: @"gen"];
		if ([cas isEqual: @"dat"]) [tags addObject: @"dat"];
		if ([cas isEqual: @"acc"]) [tags addObject: @"acc"];
		if ([cas isEqual: @"voc"]) [tags addObject: @"voc"];
		if ([cas isEqual: @"loc"]) [tags addObject: @"loc"];
		if ([cas isEqual: @"ins"]) [tags addObject: @"inst"];
	}
	if ([pos isEqual: @"adv"]) {
		[tags addObject: @"adv"];
		NSString* degree = dict[@"degree"];
		if ([degree isEqual: @"1"]) [tags addObject: @"pos"];
		if ([degree isEqual: @"2"]) [tags addObject: @"comp"];
		if ([degree isEqual: @"3"]) [tags addObject: @"sup"];
	}
	if ([pos isEqual: @"a"]) {
		BOOL ppas = dict[@"rem_ppas"] != nil;
		if (ppas) [tags addObject: @"ppas"];
		else [tags addObject: @"adj"];
		NSString* gender = dict[@"gender"];
		NSString* cas = dict[@"case"];
		NSString* number = dict[@"number"];
		if ([gender isEqual: @"masca"]) [tags addObject: @[@"m1", @"m"]];
		if ([gender isEqual: @"masca"]) [tags addObject: @[@"m2", @"m"]];
		if ([gender isEqual: @"masci"]) [tags addObject: @[@"m3", @"m"]];
		if ([gender isEqual: @"fem"]) [tags addObject: @"f"];
		if ([gender isEqual: @"neut"]) [tags addObject: @"n"];
		if ([number isEqual: @"sg"]) [tags addObject: @"sg"];
		if ([number isEqual: @"pl"]) [tags addObject: @"pl"];
		if ([cas isEqual: @"nom"]) [tags addObject: @"nom"];
		if ([cas isEqual: @"gen"]) [tags addObject: @"gen"];
		if ([cas isEqual: @"dat"]) [tags addObject: @"dat"];
		if ([cas isEqual: @"acc"]) [tags addObject: @"acc"];
		if ([cas isEqual: @"voc"]) [tags addObject: @"voc"];
		if ([cas isEqual: @"loc"]) [tags addObject: @"loc"];
		if ([cas isEqual: @"ins"]) [tags addObject: @"inst"];
		if (!ppas) {
			NSString* degree = dict[@"degree"];
			if ([degree isEqual: @"1"]) [tags addObject: @"pos"];
			if ([degree isEqual: @"2"]) [tags addObject: @"comp"];
			if ([degree isEqual: @"3"]) [tags addObject: @"sup"];
		}
	}
	//NSLog(@"%@ %@", dict, tags);
	NSMutableSet* forms = dict[@"lextr_dict"] != nil ? [self generate: lemma tags: tags] : [NSMutableSet set];
	if (forms.count == 0) [forms addObject: lemma];
	return forms;
}

- (NSMutableSet*)generate:(NSString*)lemma tags:(NSSet*)tags {
	NSMutableSet* forms = [NSMutableSet set];
	NSArray* infos = lemmas[lemma];
	if (infos != nil) {
		NSEnumerator* enumerator = [infos objectEnumerator];
		NSArray* info;
		while (info = [enumerator nextObject]) {
			NSString* tags2 = info[1];
			if ([self containsTags: tags2 :tags]) {
				NSString* form = info[0];
				[forms addObject: form];
			}
		}
		if (forms.count == 0) [CSMorphologicalGenerator log: [NSString stringWithFormat: @"don't know how to generate '%@' - %@", lemma, tags]];
	} else [CSMorphologicalGenerator log: [NSString stringWithFormat: @"don't know how to generate '%@' - unknown", lemma]];
	return forms;
}

- (BOOL)containsTags:(NSString*)tags :(NSSet*)set {
	NSEnumerator* enumerator = [set objectEnumerator];
	id tag2;
	while (tag2 = [enumerator nextObject]) {
		if ([tag2 isKindOfClass: [NSString class]]) tag2 = @[tag2];
		NSEnumerator* enumerator2 = [tag2 objectEnumerator];
		NSString* tag; BOOL found = NO;
		while (tag = [enumerator2 nextObject]) {
			NSRange range = [tags rangeOfString: tag];
			if (range.location != NSNotFound &&
			  (range.location == 0 || [tags characterAtIndex: range.location - 1] == ':' || [tags characterAtIndex: range.location - 1] == '.')
				) { found = YES; break; }
		}
		if (!found) return NO;
	}
	return YES;
}

- (NSArray*)generateByExtendingAVMs:(NSArray*)avms {
	NSMutableArray* results = [NSMutableArray arrayWithCapacity: avms.count];
	NSEnumerator* enumerator = [avms objectEnumerator];
	NSMutableDictionary* dict;
	while ((dict = [enumerator nextObject])) {
		NSString* lemma = dict[@"lemma"];
		NSSet* set;
		if (lemma == nil) set = [NSSet setWithObjects: dict[@"form"], nil];
		else set = [self generate: lemma attributes: dict];
		
		NSMutableArray* mutableSet = [NSMutableArray arrayWithCapacity: set.count];
		NSEnumerator* enumerator2 = [set objectEnumerator];
		NSString* form;
		while (form = [enumerator2 nextObject]) {
			NSString* cap = dict[@"capitalized"];
			if (cap != nil && [cap isEqual: @"all"]) form = form.uppercaseString;
			if (cap != nil && [cap isEqual: @"first"]) form = form.capitalizedString;
			[mutableSet addObject: form];
		}
		dict[@"target_form"] = mutableSet;
		[results addObject: dict];
	}
	return results;
}
@end
