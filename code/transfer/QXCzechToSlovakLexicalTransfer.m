//
//  QXCzechToSlovakLexicalTransfer.m
//  CzSk
//
//  Created by Petr Homola on 21.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QXCzechToSlovakLexicalTransfer.h"
#import "QX_String.h"

static NSMutableDictionary* basicDict = nil;

@implementation QXCzechToSlovakLexicalTransfer
- (id)init {
	return self = [self initWithFile: @"/Users/phomola/dev/data/czskdict.txt"];
}

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
					if (tokens.count != 2) continue; //NSLog(@"oops %s", line);
					NSString* czechLemma = [tokens[0] trim].lowercaseString;
					NSString* slovakLemma = [tokens[1] trim].lowercaseString;
					NSString* annot = tokens.count == 2 ? nil : [tokens[2] trim];
					//id value = [basicDict objectForKey: czechLemma];
					//if (value != nil) NSLog(@"duplicate entry for %@: %@/%@", czechLemma, value, slovakLemma);
					NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: slovakLemma, @"lemma", nil];
					if (annot != nil && [annot rangeOfString: @"gender=fem;"].location != NSNotFound) dict[@"gender"] = @"fem";
					if (annot != nil && [annot rangeOfString: @"rem=ppas;"].location != NSNotFound) dict[@"rem_ppas"] = @"1";
					if (annot != nil && [annot rangeOfString: @"rem=imperf;"].location != NSNotFound) dict[@"rem_imperf"] = @"1";
					basicDict[czechLemma] = @{@"lemma": slovakLemma};
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
		id target = basicDict[lemma];
		if (target != nil) {
			NSArray* array = [target isKindOfClass: [NSArray class]] ? target : @[target];
			NSEnumerator* enumerator2 = [array objectEnumerator];
			NSDictionary* target2;
			while (target2 = [enumerator2 nextObject]) {
				NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary: source];
				NSEnumerator* enumerator = [target2.allKeys objectEnumerator];
				id key;
				while (key = [enumerator nextObject]) {
					id value = target2[key];
					dict[key] = value;
				}
				dict[@"lextr"] = @"1";
				[result addObject: dict];
			}
		} else {
			//NSLog(@"don't know how to translate %@", lemma);
			NSString* message = [NSString stringWithFormat: @"don't know how to translate %@ (%@/%@)", lemma, source[@"form"], source[@"tags"]];
			[[self class] log: message];
			//NSLog(@"%@", message);
			//exit(1);
			NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary: source];
			dict[@"lextr"] = @"1";
			[result addObject: dict];
		}
}
@end
