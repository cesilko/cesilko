//
//  CSCzechToPolishLexicalTransfer.m
//  transfer
//
//  Created by Petr Homola on 12.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CSCzechToPolishLexicalTransfer.h"
#import "QX_String.h"

//static NSMutableDictionary* basicDict = nil;

@implementation CSCzechToPolishLexicalTransfer
/*- (id)initWithFile:(NSString*)fileName {
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
				//if ([tokens count] != 2) continue; //NSLog(@"oops %s", line);
				NSString* czechLemma = [[[tokens objectAtIndex: 0] trim] lowercaseString];
				NSString* polishLemma = [[[tokens objectAtIndex: 1] trim] lowercaseString];
				NSString* annot = [tokens count] == 2 ? nil : [[tokens objectAtIndex: 2] trim];
				//id value = [basicDict objectForKey: czechLemma];
				//if (value != nil) NSLog(@"duplicate entry for %@: %@/%@", czechLemma, value, slovakLemma);
				NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: polishLemma, @"lemma", nil];
				if (annot != nil && [annot rangeOfString: @"gender=fem;"].location != NSNotFound) [dict setObject: @"fem" forKey: @"gender"];
				if (annot != nil && [annot rangeOfString: @"rem=ppas;"].location != NSNotFound) [dict setObject: @"1" forKey: @"rem_ppas"];
				if (annot != nil && [annot rangeOfString: @"rem=imperf;"].location != NSNotFound) [dict setObject: @"1" forKey: @"rem_imperf"];
				[basicDict setObject: dict forKey: czechLemma];
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
		id target = [basicDict objectForKey: lemma];
		if (target != nil) {
			NSArray* array = [target isKindOfClass: [NSArray class]] ? target : [NSArray arrayWithObject: target];
			NSEnumerator* enumerator2 = [array objectEnumerator];
			NSDictionary* target2;
			while (target2 = [enumerator2 nextObject]) {
				NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary: source];
				NSEnumerator* enumerator = [[target2 allKeys] objectEnumerator];
				id key;
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
			//NSLog(@"%@", message);
			//exit(1);
			NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary: source];
			[dict setObject: @"1" forKey: @"lextr"];
			[result addObject: dict];
		}
}*/
@end
