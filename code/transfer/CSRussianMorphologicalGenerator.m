//
//  CSRussianMorphologicalGenerator.m
//  transfer
//
//  Created by Petr Homola on 12.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CSRussianMorphologicalGenerator.h"
#import "QX_String.h"

@implementation CSRussianMorphologicalGenerator

- (id)initWithFile:(NSString*)_fileName {
	if (self = [super init]) {
		fileName = _fileName;
		//NSLog(@"%@", fileName);
		[self load];
	}
	return self;
}


- (void)load {
	lemmas = [[NSMutableDictionary alloc] initWithCapacity: 500000];
	paradigms = [[NSMutableDictionary alloc] initWithCapacity: 500000];
	endings = [[NSMutableDictionary alloc] initWithCapacity: 500000];
	FILE* file1 = fopen([fileName stringByAppendingString: @"/stems.txt"].UTF8String, "r");
	FILE* file2 = fopen([fileName stringByAppendingString: @"/gram.txt"].UTF8String, "r");
	FILE* file3 = fopen([fileName stringByAppendingString: @"/tags.txt"].UTF8String, "r");
	char cline[10000]; int n = 0; NSString* paradigm = nil;
	//NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	while (fgets(cline, 10000, file2) != NULL) {
		NSString* line = [@(cline) trim];
		if ([line characterAtIndex: 0] == '#' && [line characterAtIndex: 1] != '#') {
			paradigm = [line substringWithRange: NSMakeRange(1, line.length - 2)];
			//NSLog(@"%@", paradigm);
		} else if (paradigm != nil) {
			NSArray* parts = [line componentsSeparatedByString: @"%"];
			//NSLog(@"%@", parts);
			NSMutableArray* endings2 = [NSMutableArray array];
			int i;
			for (i = 1; i < parts.count; i++) {
				NSArray* parts2 = [[parts[i] lowercaseString] componentsSeparatedByString: @"*"];
				[endings2 addObject: parts2];
			}
			paradigms[paradigm] = endings2;
			paradigm = nil;
		}
	}
	while (fgets(cline, 10000, file3) != NULL) {
		NSString* line = [@(cline) trim];
		if (line.length > 2 && ![[line substringToIndex: 2] isEqual: @"//"]) {
			NSArray* parts = [line split];
			if (parts.count == 3) {
				endings[parts[0]] = [NSString stringWithFormat: @",%@,", parts[2]];
			} else if (parts.count == 4) {
				endings[parts[0]] = [NSString stringWithFormat: @",%@,%@,", parts[2], parts[3]];
			} else NSLog(@"!!! %@", line);
		}
	}
	while (fgets(cline, 10000, file1) != NULL) {
		n++;
		if (n % 10000 == 0) {
			//NSLog(@"-- %d", n);
			//[pool release];
			//pool = [[NSAutoreleasePool alloc] init];
		}
		NSArray* parts = [[@(cline) trim] split];
		NSString* stem = [parts[0] lowercaseString];
		if ([stem isEqual: @"#"]) stem = @"";
		NSString* paradigmId = parts[1];
		NSArray* paradigm = paradigms[paradigmId];
		if (paradigm == nil) { NSLog(@"unknown paradigm"); exit(1); }
		//@try {
			NSString* lemma = [stem stringByAppendingString: paradigm[0][0]];
			//NSLog(@"## unknown ## %@", lemma);
			NSMutableArray* infos = lemmas[lemma];
			if (infos == nil) {
				infos = [NSMutableArray array];
				lemmas[lemma] = infos;
			}
			[infos addObject: @[stem, paradigm]];
		//} @catch (NSException* exception) {
		//	NSLog(@"!!! %@ %@", stem, paradigmId);
		//}
	}
	//[pool release];
	fclose(file1);
	fclose(file2);
	fclose(file3);
	//NSLog(@"%@", endings);
	NSLog(@"loaded - %u lemmas", lemmas.count);
	//pause();
}

- (NSArray*)generateByExtendingAVMs:(NSArray*)avms {
	NSMutableArray* results = [NSMutableArray arrayWithCapacity: avms.count];
	NSEnumerator* enumerator = [avms objectEnumerator];
	NSMutableDictionary* dict;
	while ((dict = [enumerator nextObject])) {
		NSString* lemma = dict[@"lemma"];
		NSString* pos = dict[@"pos"];
		NSSet* set;
		if (lemma == nil) set = [NSSet setWithObjects: dict[@"form"], nil];
		else set = [self generate: lemma attributes: dict];
		
		NSMutableArray* mutableSet = [NSMutableArray arrayWithCapacity: set.count];
		NSEnumerator* enumerator2 = [set objectEnumerator];
		NSString* form;
		while (form = [enumerator2 nextObject]) {
			NSString* neg = dict[@"negation"];
			//if (neg && [neg isEqual: @"1"]) { NSLog(@"##### NEG %@ %@", lemma, pos); }
			if ([pos isEqual: @"verb"]) { //NSLog(@"%@", dict);
				if (neg && [neg isEqual: @"1"]) form = [@"не " stringByAppendingString: form];
			}
			if ([pos isEqual: @"a"] || [pos isEqual: @"adv"]) { //NSLog(@"%@", dict);
				if (neg && [neg isEqual: @"1"]) form = [@"не" stringByAppendingString: form];
			}
			NSString* addSuffix = dict[@"add_suffix"];
			if (addSuffix != nil) {
				form = [form stringByAppendingString: addSuffix];
			}
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

- (NSSet*)generate:(NSString*)lemma attributes:(NSDictionary*)dict {
	NSString* pos = dict[@"pos"];
	NSMutableSet* tags = [NSMutableSet set];
	if ([pos isEqual: @"verb"]) {
		if ([dict[@"vform"] isEqual: @"inf"]) {
			[tags addObject: @"инф"];
		} else if ([dict[@"vform"] isEqual: @"fin"]) { //NSLog(@"%@", dict);
			[tags addObject: @"Г"];
			[tags addObject: @"дст"];
			//[tags addObject: @"!прш"];
			NSString* number = dict[@"number"];
			NSString* person = dict[@"person"];
			NSString* tense = dict[@"tense"];
			if ([number isEqual: @"sg"]) [tags addObject: @"ед"];
			if ([number isEqual: @"pl"]) [tags addObject: @"мн"];
			if ([person isEqual: @"1"]) [tags addObject: @"1л"];
			if ([person isEqual: @"2"]) [tags addObject: @"2л"];
			if ([person isEqual: @"3"]) [tags addObject: @"3л"];
			if ([tense isEqual: @"pres"]) [tags addObject: @"нст"];
			if ([tense isEqual: @"fut"]) [tags addObject: @"буд"];
		} else if ([dict[@"vform"] isEqual: @"lpart"]) {
			[tags addObject: @"дст"];
			[tags addObject: @"прш"];
			NSString* number = dict[@"number"];
			if ([number isEqual: @"sg"]) [tags addObject: @"ед"];
			if ([number isEqual: @"pl"]) [tags addObject: @"мн"];
			if ([number isEqual: @"sg"]) {
				NSString* gender = dict[@"gender"];
				if ([gender isEqual: @"masca"]) [tags addObject: @"мр"];
				if ([gender isEqual: @"masci"]) [tags addObject: @"мр"];
				if ([gender isEqual: @"fem"]) [tags addObject: @"жр"];
				if ([gender isEqual: @"neut"]) [tags addObject: @"ср"];
			}
		} else if ([dict[@"vform"] isEqual: @"part_short"]) {
			[tags addObject: @"Г"];
			[tags addObject: @"прч"];
			/*if ([dict objectForKey: @"rem_imperf"]) [tags addObject: @"нст"]; else*/ [tags addObject: @"прш"];
			[tags addObject: @"стр"];
			[tags addObject: @"кр"];
			NSString* number = dict[@"number"];
			if ([number isEqual: @"sg"]) [tags addObject: @"ед"];
			if ([number isEqual: @"pl"]) [tags addObject: @"мн"];
			if ([number isEqual: @"sg"]) {
				NSString* gender = dict[@"gender"];
				if ([gender isEqual: @"masca"]) [tags addObject: @"мр"];
				if ([gender isEqual: @"masci"]) [tags addObject: @"мр"];
				if ([gender isEqual: @"fem"]) [tags addObject: @"жр"];
				if ([gender isEqual: @"neut"]) [tags addObject: @"ср"];
			}
		} else if ([dict[@"vform"] isEqual: @"transgr"]) {
			[tags addObject: @"Г"];
			[tags addObject: @"дст"];
			[tags addObject: @"дпр"];
			if ([dict[@"tense"] isEqual: @"pres"]) [tags addObject: @"нст"]; else [tags addObject: @"прш"];
		} else NSLog(@"%@ %@", dict[@"vform"], dict);
	}
	if ([pos isEqual: @"n"]) {
		[tags addObject: @"С"];
		NSString* gender = dict[@"gender"];
		NSString* cas = dict[@"case"];
		NSString* number = dict[@"number"];
		if ([gender isEqual: @"masca"]) { [tags addObject: @"мр"]; } //if ([cas isEqual: @"acc"]) [tags addObject: @"од"]; }
		if ([gender isEqual: @"masci"]) { [tags addObject: @"мр"]; } //if ([cas isEqual: @"acc"]) [tags addObject: @"но"]; }
		if ([gender isEqual: @"fem"]) [tags addObject: @"жр"];
		if ([gender isEqual: @"neut"]) [tags addObject: @"ср"];
		if ([number isEqual: @"sg"]) [tags addObject: @"ед"];
		if ([number isEqual: @"pl"]) [tags addObject: @"мн"];
		if ([cas isEqual: @"nom"]) [tags addObject: @"им"];
		if ([cas isEqual: @"gen"]) [tags addObject: @"рд"];
		if ([cas isEqual: @"dat"]) [tags addObject: @"дт"];
		if ([cas isEqual: @"acc"]) [tags addObject: @"вн"];
		if ([cas isEqual: @"voc"]) [tags addObject: @"им"];
		if ([cas isEqual: @"loc"]) [tags addObject: @"пр"];
		if ([cas isEqual: @"ins"]) [tags addObject: @"тв"];
	}
	if ([pos isEqual: @"pron"]) {
		NSString* gender = dict[@"gender"];
		NSString* cas = dict[@"case"];
		NSString* number = dict[@"number"];
		NSString* prontype = dict[@"prontype"];
		if ([prontype isEqual: @"interr"] || [prontype isEqual: @"rel"] || [prontype isEqual: @"dem"] || [prontype isEqual: @"poss"] || [prontype isEqual: @"pers"]) {
			[tags addObject: @[@"МС-П", @"МС"]];
			if ([number isEqual: @"sg"]) {
				if ([gender isEqual: @"masca"]) { [tags addObject: @"мр"]; if ([cas isEqual: @"acc"]) [tags addObject: @"од"]; }
				if ([gender isEqual: @"masci"]) { [tags addObject: @"мр"]; if ([cas isEqual: @"acc"]) [tags addObject: @"но"]; }
				if ([gender isEqual: @"fem"]) [tags addObject: @"жр"];
				if ([gender isEqual: @"neut"]) [tags addObject: @"ср"];
			}
			if ([number isEqual: @"sg"]) [tags addObject: @"ед"];
			if ([number isEqual: @"pl"]) [tags addObject: @"мн"];
			if ([cas isEqual: @"nom"]) [tags addObject: @"им"];
			if ([cas isEqual: @"gen"]) [tags addObject: @"рд"];
			if ([cas isEqual: @"dat"]) [tags addObject: @"дт"];
			if ([cas isEqual: @"acc"]) [tags addObject: @"вн"];
			if ([cas isEqual: @"voc"]) [tags addObject: @"им"];
			if ([cas isEqual: @"loc"]) [tags addObject: @"пр"];
			if ([cas isEqual: @"ins"]) [tags addObject: @"тв"];
			//NSLog(@"%@ %u", dict, [tags count]);
		} else if ([prontype isEqual: @"refl"] || [prontype isEqual: @"long_refl"]) {
			[tags addObject: @"МС"];
			if ([cas isEqual: @"nom"]) [tags addObject: @"им"];
			if ([cas isEqual: @"gen"]) [tags addObject: @"рд"];
			if ([cas isEqual: @"dat"]) [tags addObject: @"дт"];
			if ([cas isEqual: @"acc"]) [tags addObject: @"вн"];
			if ([cas isEqual: @"voc"]) [tags addObject: @"им"];
			if ([cas isEqual: @"loc"]) [tags addObject: @"пр"];
			if ([cas isEqual: @"ins"]) [tags addObject: @"тв"];
		} else NSLog(@"%@", dict);
	}
	if ([pos isEqual: @"adv"]) {
		//[tags addObject: @"adv"];
		NSString* degree = dict[@"degree"];
		//if ([degree isEqual: @"1"]) [tags addObject: @"pos"];
		if ([degree isEqual: @"2"]) [tags addObject: @"сравн"];
		//if ([degree isEqual: @"3"]) [tags addObject: @"sup"];
	}
	if ([pos isEqual: @"a"]) { //NSLog(@"%@ %@", dict, lemma);
		BOOL ppas = dict[@"rem_ppas"] != nil;
		if (ppas) {
			[tags addObject: @"Г"];
			[tags addObject: @"прч"];
			if (dict[@"rem_imperf"]) [tags addObject: @"нст"]; else [tags addObject: @"прш"];
			[tags addObject: @"стр"];
			//NSLog(@"%@", dict);
		} else [tags addObject: @"П"];
		NSString* cas = dict[@"case"];
		NSString* number = dict[@"number"];
		if ([number isEqual: @"sg"]) [tags addObject: @"ед"];
		if ([number isEqual: @"pl"]) [tags addObject: @"мн"];
		if ([number isEqual: @"sg"]) {
			NSString* gender = dict[@"gender"];
			if ([gender isEqual: @"masca"]) { [tags addObject: @"мр"]; if ([cas isEqual: @"acc"]) [tags addObject: @"од"]; }
			if ([gender isEqual: @"masci"]) { [tags addObject: @"мр"]; if ([cas isEqual: @"acc"]) [tags addObject: @"но"]; }
			if ([gender isEqual: @"fem"]) [tags addObject: @"жр"];
			if ([gender isEqual: @"neut"]) [tags addObject: @"ср"];
		}
		if ([cas isEqual: @"nom"]) [tags addObject: @"им"];
		if ([cas isEqual: @"gen"]) [tags addObject: @"рд"];
		if ([cas isEqual: @"dat"]) [tags addObject: @"дт"];
		if ([cas isEqual: @"acc"]) [tags addObject: @"вн"];
		if ([cas isEqual: @"voc"]) [tags addObject: @"им"];
		if ([cas isEqual: @"loc"]) [tags addObject: @"пр"];
		if ([cas isEqual: @"ins"]) [tags addObject: @"тв"];
		if (ppas) {
			//NSLog(@"***** %@ %@", lemma, dict);
		}
	}
	//NSLog(@"%@ %@", dict, tags);
	NSMutableSet* forms = dict[@"lextr_dict"] != nil ? [self generate: lemma tags: tags] : [NSMutableSet set];
	if (forms.count == 0) [forms addObject: lemma];
	return forms;
}

- (int)containsTags:(NSArray*)paradigm :(NSSet*)set {
	NSEnumerator* enumerator = [paradigm objectEnumerator];
	NSArray* triple; int index = 0;
	while (triple = [enumerator nextObject]) {
		NSString* pointer = triple[1];
		NSString* tags = endings[pointer];
		if (tags == nil) ; //{ NSLog(@"!!! unknown tag %@ in %@", pointer, triple); exit(1); }
		else {
			NSEnumerator* enumerator2 = [set objectEnumerator];
			id tag2; unsigned matches = 0;
			while (tag2 = [enumerator2 nextObject]) {
				if ([tag2 isKindOfClass: [NSString class]]) tag2 = @[tag2];
				NSEnumerator* enumerator3 = [tag2 objectEnumerator];
				NSString* tag; BOOL found = NO, neg;
				while (tag = [enumerator3 nextObject]) {
					neg = [tag characterAtIndex: 0] == '!';
					if (neg) tag = [tag substringFromIndex: 1];
					if ([tags rangeOfString: [NSString stringWithFormat: @",%@,", tag]].location != NSNotFound) {
						found = YES;
						break;
					}
				}
				if (!neg && found || neg && !found) matches++;
			}
			if (matches == set.count) return index;
		}
		index++;
	}
	return -1;
}

- (NSMutableSet*)generate:(NSString*)lemma tags:(NSSet*)tags {
	NSMutableSet* forms = [NSMutableSet set];
	NSArray* infos = lemmas[lemma];
	if (infos != nil) {
		NSEnumerator* enumerator = [infos objectEnumerator];
		NSArray* info;
		while (info = [enumerator nextObject]) {
			NSArray* paradigm = info[1];
			int index = [self containsTags: paradigm :tags];
			if (index != -1) {
				NSString* stem = info[0];
				NSArray* triple = paradigm[index];
				NSString* form = triple.count == 2 ?
					[NSString stringWithFormat: @"%@%@", stem, triple[0]] :
					[NSString stringWithFormat: @"%@%@%@", triple[2], stem, triple[0]];
				[forms addObject: form];
			}
		}
		if (forms.count == 0) {
			[CSMorphologicalGenerator log: [[NSString stringWithFormat: @"don't know how to generate '%@' - %@", lemma, tags] plainAsciiString]];
			NSLog(@"## weird ## %@", lemma);
			NSEnumerator* enumerator2 = [tags objectEnumerator];
			NSString* tag;
			while (tag = [enumerator2 nextObject]) {
				NSLog(@"## %@", tag);
			}
		}
	} else {
		[CSMorphologicalGenerator log: [[NSString stringWithFormat: @"don't know how to generate '%@' - unknown", lemma] plainAsciiString]];
		NSLog(@"##### %@", lemma);
	}
	return forms;
}

@end
