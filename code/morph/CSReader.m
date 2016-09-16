//
//  CSReader.m
//  CzSk
//
//  Created by Petr Homola on 21.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CSReader.h"
#import "QX_String.h"

@implementation CSReader
- (id)initWithFile:(NSString*)_fileName {
	if (self = [super init]) {
		fileName = _fileName;
	}
	return self;
}

- (id)initWithTaggedFile:(NSString*)_fileName {
	if (self = [super init]) {
		fileName = _fileName;
	}
	return self;
}

+ (id)readerWithFile:(NSString*)_fileName {
	return [[CSReader alloc] initWithFile: _fileName];
}

+ (id)readerWithTaggedFile:(NSString*)_fileName {
	return [[CSReader alloc] initWithTaggedFile: _fileName];
}

- (NSArray*)taggedSentences {
	NSMutableArray* sentences = [NSMutableArray arrayWithCapacity: 10];
	FILE* file = fopen(fileName.UTF8String, "r");
	char cline[1000]; NSMutableArray* sentence = nil;
	while (fgets(cline, 1000, file) != NULL) {
		NSString* line = @(cline);
		NSRange range = [line rangeOfString: @"<s id"];
		if (range.location == 0) {
			if (sentence != nil) [sentences addObject: sentence];
			sentence = [NSMutableArray array];
		}
		range = [line rangeOfString: @"<d"];
		if (range.location == 0) {
			NSString* form = [line substringFromIndex: 3];
			range = [form rangeOfString: @"<"];
			if (range.location != NSNotFound) form = [form substringToIndex: range.location];
			[sentence addObject: @[form, form, [NSNull null]]];
		}
		range = [line rangeOfString: @"<f"];
		if (range.location == 0) {
			range = [line rangeOfString: @">"];
			unsigned i = range.location + 1;
			NSString* tmp = [line substringFromIndex: i];
			range = [tmp rangeOfString: @"<"];
			NSString* form = [tmp substringToIndex: range.location];
			
			range = [line rangeOfString: @"<MDl src=\"a\">"];
			tmp = [line substringFromIndex: range.location + 13];
			range = [tmp rangeOfString: @"<"];
			NSString* lemma = [tmp substringToIndex: range.location];
			range = [lemma rangeOfString: @"_"];
			if (range.location != NSNotFound) lemma = [lemma substringToIndex: range.location];
			
			range = [line rangeOfString: @"<MDt src=\"a\">"];
			tmp = [line substringFromIndex: range.location + 13];
			range = [tmp rangeOfString: @"<"];
			NSString* tag = [tmp substringToIndex: range.location];
			
			[sentence addObject: @[form, lemma, tag]];
			//NSLog(@"%@ %@ %@", form, lemma, tag);
		}
	}
	if (sentence != nil) [sentences addObject: sentence];
	fclose(file);
	return sentences;
}

- (NSArray*)sentences {
	//NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString: @","];
	NSMutableArray* sentences = [NSMutableArray arrayWithCapacity: 10];
	FILE* file = fopen(fileName.UTF8String, "r");
	char cline[1000];
	while (fgets(cline, 1000, file) != NULL) {
		if (cline[0] == '#') continue; //{ NSLog(@"skipping"); exit(1); }
		NSString* line = @(cline);
		NSArray* tokens = [line tokenize];
		if (tokens.count > 0) [sentences addObject: tokens]; //else NSLog(@"##### reader error");
		/*NSArray* segments = [line splitBy: separators];
		NSEnumerator* enumerator = [segments objectEnumerator];
		NSString* segment;
		while ((segment = [enumerator nextObject])) {
			//NSLog(@"'%@'", segment);
			if ([segment length] > 0) {
				NSArray* tokens = [segment tokenize];
				if ([tokens count] > 0) [sentences addObject: tokens];
			}
		}*/
	}
	fclose(file);
	return sentences;
}

@end
