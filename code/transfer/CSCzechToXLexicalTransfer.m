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
			@autoreleasepool {
				NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString: @"|"];
				basicDict = [[NSMutableDictionary alloc] initWithCapacity: 100000];
				FILE* file = fopen(fileName.UTF8String, "r");
				char line[1000];
				while (fgets(line, 1000, file) != NULL) {
					if (line[0] == '#') continue;
					NSArray* tokens = [@(line) splitBy: separators];
					if (tokens.count < 2) continue; //NSLog(@"oops %s", line);
					NSString* czechLemma = [tokens[0] trim].lowercaseString;
					NSString* polishLemma = [tokens[1] trim].lowercaseString;
					NSString* annot = tokens.count <= 2 ? nil : [tokens[2] trim];
					NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: polishLemma, @"lemma", nil];
					if (annot != nil && [annot rangeOfString: @"gender=masca;"].location != NSNotFound) dict[@"gender"] = @"masca";
					if (annot != nil && [annot rangeOfString: @"gender=masci;"].location != NSNotFound) dict[@"gender"] = @"masci";
					if (annot != nil && [annot rangeOfString: @"gender=fem;"].location != NSNotFound) dict[@"gender"] = @"fem";
					if (annot != nil && [annot rangeOfString: @"gender=neut;"].location != NSNotFound) dict[@"gender"] = @"neut";
					
					if (annot != nil && [annot rangeOfString: @"case=nom;"].location != NSNotFound) dict[@"case"] = @"nom";
					if (annot != nil && [annot rangeOfString: @"case=gen;"].location != NSNotFound) dict[@"case"] = @"gen";
					if (annot != nil && [annot rangeOfString: @"case=dat;"].location != NSNotFound) dict[@"case"] = @"dat";
					if (annot != nil && [annot rangeOfString: @"case=acc;"].location != NSNotFound) dict[@"case"] = @"acc";
					if (annot != nil && [annot rangeOfString: @"case=voc;"].location != NSNotFound) dict[@"case"] = @"voc";
					if (annot != nil && [annot rangeOfString: @"case=loc;"].location != NSNotFound) dict[@"case"] = @"loc";
					if (annot != nil && [annot rangeOfString: @"case=ins;"].location != NSNotFound) dict[@"case"] = @"ins";
					
					if (annot != nil && [annot rangeOfString: @"rem=ppas;"].location != NSNotFound) dict[@"rem_ppas"] = @"1";
					if (annot != nil && [annot rangeOfString: @"rem=imperf;"].location != NSNotFound) dict[@"rem_imperf"] = @"1";
					if (annot != nil && [annot rangeOfString: @"rem=suffix_to;"].location != NSNotFound) dict[@"add_suffix"] = @"-то";
					if (annot != nil && [annot rangeOfString: @"rem=suffix_sja;"].location != NSNotFound) dict[@"add_suffix"] = @"ся";
					
					NSString* conds = tokens.count <= 3 ? nil : [tokens[3] trim];
					NSMutableDictionary* condsDict = [NSMutableDictionary dictionary];
					if (conds != nil && [conds rangeOfString: @"gender=masca;"].location != NSNotFound) condsDict[@"gender"] = @"masca";
					if (conds != nil && [conds rangeOfString: @"gender=masci;"].location != NSNotFound) condsDict[@"gender"] = @"masci";
					if (conds != nil && [conds rangeOfString: @"gender=fem;"].location != NSNotFound) condsDict[@"gender"] = @"fem";
					if (conds != nil && [conds rangeOfString: @"gender=neut;"].location != NSNotFound) condsDict[@"gender"] = @"neut";
					
					if (conds != nil && [conds rangeOfString: @"number=sg;"].location != NSNotFound) condsDict[@"number"] = @"sg";
					if (conds != nil && [conds rangeOfString: @"number=pl;"].location != NSNotFound) condsDict[@"number"] = @"pl";

					if (annot != nil && [annot rangeOfString: @"rem=isrefl;"].location != NSNotFound) condsDict[@"refl"] = @"1";
					
					NSMutableArray* translations = basicDict[czechLemma];
					if (translations == nil) basicDict[czechLemma] = (translations = [NSMutableArray array]);
					[translations addObject: @[dict, condsDict]];
					//NSLog(@"%@", dict);
					//[basicDict setObject: dict forKey: czechLemma];
				}
				fclose(file);
			}
			//NSLog(@"%d", [basicDict count]);
		}
	}
	return self;
}

- (void)transfer:(NSDictionary*)source result:(NSMutableArray*)result {
		NSString* lemma = source[@"lemma"];
		if (lemma == nil) {
			NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary: source];
			dict[@"lextr"] = @"1";
			[result addObject: dict];
			return;
		}
		NSArray* target = basicDict[lemma];
		if (target != nil) {
			//NSArray* array = [target isKindOfClass: [NSArray class]] ? target : [NSArray arrayWithObject: target];
			NSEnumerator* enumerator2 = [target objectEnumerator];
			NSArray* pair;
			while (pair = [enumerator2 nextObject]) {
				NSDictionary* conds = pair[1];
				NSDictionary* target2 = pair[0];
				NSEnumerator* enumerator = [conds.allKeys objectEnumerator];
				id key; BOOL conforms = YES;
				while (key = [enumerator nextObject]) {
					id value = conds[key];
					id sourceValue = source[key];
					//NSLog(@"##### %@ %@ %@", key, value, sourceValue);
					if (![value isEqual: sourceValue]) { conforms = NO; break; }
				}
				if (!conforms) continue;
				NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary: source];
				enumerator = [target2.allKeys objectEnumerator];
				while (key = [enumerator nextObject]) {
					id value = target2[key];
					//NSLog(@"##### %@ -- %@ -> %@", key, [dict objectForKey: key], value);
					dict[key] = value;
				}
				dict[@"lextr"] = @"1";
				dict[@"lextr_dict"] = @"1";
				[result addObject: dict];
			}
		} else {
			//NSLog(@"don't know how to translate %@", lemma);
			NSString* message = [NSString stringWithFormat: @"don't know how to translate %@ (%@/%@)", lemma, source[@"form"], source[@"tags"]];
			[[self class] log: message];
			[[self class] addUnknownLemma: lemma];
			//NSLog(@"%@", message);
			//exit(1);
			NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary: source];
			dict[@"lextr"] = @"1";
			[result addObject: dict];
		}
}
@end
