//
//  CSCzechToXLexicalTransfer.m
//  transfer
//
//  Created by Petr Homola on 14.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CSCzechToXLexicalTransfer.h"
#import "QX_String.h"

static NSMutableDictionary* basicDict = nil;

@implementation CSCzechToXLexicalTransfer
- (id)initWithFile:(NSString*)fileName {
	if (self = [super init]) {
		if (basicDict == nil) {
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString: @"|"];
			basicDict = [[NSMutableDictionary alloc] initWithCapacity: 100000];
			FILE* file = fopen([fileName UTF8String], "r");
			char line[1000];
			while (fgets(line, 1000, file) != NULL) {
				if (line[0] == '#') continue;
				NSArray* tokens = [[NSString stringWithUTF8String: line] splitBy: separators];
				if ([tokens count] < 2) continue; //NSLog(@"oops %s", line);
				NSString* czechLemma = [[[tokens objectAtIndex: 0] trim] lowercaseString];
				NSString* polishLemma = [[[tokens objectAtIndex: 1] trim] lowercaseString];
				NSString* annot = [tokens count] <= 2 ? nil : [[tokens objectAtIndex: 2] trim];
				NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: polishLemma, @"lemma", nil];
				if (annot != nil && [annot rangeOfString: @"gender=masca;"].location != NSNotFound) [dict setObject: @"masca" forKey: @"gender"];
				if (annot != nil && [annot rangeOfString: @"gender=masci;"].location != NSNotFound) [dict setObject: @"masci" forKey: @"gender"];
				if (annot != nil && [annot rangeOfString: @"gender=fem;"].location != NSNotFound) [dict setObject: @"fem" forKey: @"gender"];
				if (annot != nil && [annot rangeOfString: @"gender=neut;"].location != NSNotFound) [dict setObject: @"neut" forKey: @"gender"];
				
				if (annot != nil && [annot rangeOfString: @"case=nom;"].location != NSNotFound) [dict setObject: @"nom" forKey: @"case"];
				if (annot != nil && [annot rangeOfString: @"case=gen;"].location != NSNotFound) [dict setObject: @"gen" forKey: @"case"];
				if (annot != nil && [annot rangeOfString: @"case=dat;"].location != NSNotFound) [dict setObject: @"dat" forKey: @"case"];
				if (annot != nil && [annot rangeOfString: @"case=acc;"].location != NSNotFound) [dict setObject: @"acc" forKey: @"case"];
				if (annot != nil && [annot rangeOfString: @"case=voc;"].location != NSNotFound) [dict setObject: @"voc" forKey: @"case"];
				if (annot != nil && [annot rangeOfString: @"case=loc;"].location != NSNotFound) [dict setObject: @"loc" forKey: @"case"];
				if (annot != nil && [annot rangeOfString: @"case=ins;"].location != NSNotFound) [dict setObject: @"ins" forKey: @"case"];
				
				if (annot != nil && [annot rangeOfString: @"rem=ppas;"].location != NSNotFound) [dict setObject: @"1" forKey: @"rem_ppas"];
				if (annot != nil && [annot rangeOfString: @"rem=imperf;"].location != NSNotFound) [dict setObject: @"1" forKey: @"rem_imperf"];
				if (annot != nil && [annot rangeOfString: @"rem=suffix_to;"].location != NSNotFound) [dict setObject: @"-то" forKey: @"add_suffix"];
				if (annot != nil && [annot rangeOfString: @"rem=suffix_sja;"].location != NSNotFound) [dict setObject: @"ся" forKey: @"add_suffix"];
				
				NSString* conds = [tokens count] <= 3 ? nil : [[tokens objectAtIndex: 3] trim];
				NSMutableDictionary* condsDict = [NSMutableDictionary dictionary];
				if (conds != nil && [conds rangeOfString: @"gender=masca;"].location != NSNotFound) [condsDict setObject: @"masca" forKey: @"gender"];
				if (conds != nil && [conds rangeOfString: @"gender=masci;"].location != NSNotFound) [condsDict setObject: @"masci" forKey: @"gender"];
				if (conds != nil && [conds rangeOfString: @"gender=fem;"].location != NSNotFound) [condsDict setObject: @"fem" forKey: @"gender"];
				if (conds != nil && [conds rangeOfString: @"gender=neut;"].location != NSNotFound) [condsDict setObject: @"neut" forKey: @"gender"];
				
				if (conds != nil && [conds rangeOfString: @"number=sg;"].location != NSNotFound) [condsDict setObject: @"sg" forKey: @"number"];
				if (conds != nil && [conds rangeOfString: @"number=pl;"].location != NSNotFound) [condsDict setObject: @"pl" forKey: @"number"];

				if (annot != nil && [annot rangeOfString: @"rem=isrefl;"].location != NSNotFound) [condsDict setObject: @"1" forKey: @"refl"];
				
				NSMutableArray* translations = [basicDict objectForKey: czechLemma];
				if (translations == nil) [basicDict setObject: (translations = [NSMutableArray array]) forKey: czechLemma];
				[translations addObject: [NSArray arrayWithObjects: dict, condsDict, nil]];
				//NSLog(@"%@", dict);
				//[basicDict setObject: dict forKey: czechLemma];
			}
			fclose(file);
			[pool release];
			//NSLog(@"%d", [basicDict count]);
		}
	}
	return self;
}

- (void)transfer:(NSDictionary*)source result:(NSMutableArray*)result {
		NSString* lemma = [source objectForKey: @"lemma"];
		if (lemma == nil) {
			NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary: source];
			[dict setObject: @"1" forKey: @"lextr"];
			[result addObject: dict];
			return;
		}
		NSArray* target = [basicDict objectForKey: lemma];
		if (target != nil) {
			//NSArray* array = [target isKindOfClass: [NSArray class]] ? target : [NSArray arrayWithObject: target];
			NSEnumerator* enumerator2 = [target objectEnumerator];
			NSArray* pair;
			while (pair = [enumerator2 nextObject]) {
				NSDictionary* conds = [pair objectAtIndex: 1];
				NSDictionary* target2 = [pair objectAtIndex: 0];
				NSEnumerator* enumerator = [[conds allKeys] objectEnumerator];
				id key; BOOL conforms = YES;
				while (key = [enumerator nextObject]) {
					id value = [conds objectForKey: key];
					id sourceValue = [source objectForKey: key];
					//NSLog(@"##### %@ %@ %@", key, value, sourceValue);
					if (![value isEqual: sourceValue]) { conforms = NO; break; }
				}
				if (!conforms) continue;
				NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary: source];
				enumerator = [[target2 allKeys] objectEnumerator];
				while (key = [enumerator nextObject]) {
					id value = [target2 objectForKey: key];
					//NSLog(@"##### %@ -- %@ -> %@", key, [dict objectForKey: key], value);
					[dict setObject: value forKey: key];
				}
				[dict setObject: @"1" forKey: @"lextr"];
				[dict setObject: @"1" forKey: @"lextr_dict"];
				[result addObject: dict];
			}
		} else {
			//NSLog(@"don't know how to translate %@", lemma);
			NSString* message = [NSString stringWithFormat: @"don't know how to translate %@ (%@/%@)", lemma, [source objectForKey: @"form"], [source objectForKey: @"tags"]];
			[[self class] log: message];
			[[self class] addUnknownLemma: lemma];
			//NSLog(@"%@", message);
			//exit(1);
			NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary: source];
			[dict setObject: @"1" forKey: @"lextr"];
			[result addObject: dict];
		}
}
@end
