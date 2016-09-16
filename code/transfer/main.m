//
//  main.m
//  transfer
//
//  Created by Petr Homola on 5.03.08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QX_String.h"
#import "QX_Transfer.h"
#import "CSCzechToXLexicalTransfer.h"
#import "CSCzechToXStructuralTransfer.h"
#import "CSSlovakMorphologicalGenerator.h"
#import "CSPolishMorphologicalGenerator.h"
#import "CSRussianMorphologicalGenerator.h"
#import "CSGermanMorphologicalGenerator.h"

int main(int argc, char *argv[]) {
	@autoreleasepool {
		id lextr = Nil;
		id strtr = Nil;
		BOOL tagsAsOutput = argc > 4 && !strcmp(argv[4], "tags");
		if (!strcmp(argv[1], "czsk")) {
			lextr = [[CSCzechToXLexicalTransfer alloc] initWithFile: @(argv[2])];
			strtr = [[CSCzechToXStructuralTransfer alloc] init];
			//[CSCzechToXLexicalTransfer poseAsClass: [QXLexicalTransfer class]];
			//[CSCzechToXStructuralTransfer poseAsClass: [QXStructuralTransfer class]];
			[CSCzechToXStructuralTransfer setTargetLanguage: @"sk"];
		}
		if (!strcmp(argv[1], "czpl")) {
			lextr = [[CSCzechToXLexicalTransfer alloc] initWithFile: @(argv[2])];
			strtr = [[CSCzechToXStructuralTransfer alloc] init];
			//[CSCzechToXLexicalTransfer poseAsClass: [QXLexicalTransfer class]];
			//[CSCzechToXStructuralTransfer poseAsClass: [QXStructuralTransfer class]];
			[QXStructuralTransfer setTargetLanguage: @"pl"];
		}
		if (!strcmp(argv[1], "czru")) {
			lextr = [[CSCzechToXLexicalTransfer alloc] initWithFile: @(argv[2])];
			strtr = [[CSCzechToXStructuralTransfer alloc] init];
			//[CSCzechToXLexicalTransfer poseAsClass: [QXLexicalTransfer class]];
			//[CSCzechToXStructuralTransfer poseAsClass: [QXStructuralTransfer class]];
			[CSCzechToXStructuralTransfer setTargetLanguage: @"ru"];
		}
		if (!strcmp(argv[1], "czde")) {
			lextr = [[CSCzechToXLexicalTransfer alloc] initWithFile: @(argv[2])];
			strtr = [[CSCzechToXStructuralTransfer alloc] init];
			//[CSCzechToXLexicalTransfer poseAsClass: [QXLexicalTransfer class]];
			//[CSCzechToXStructuralTransfer poseAsClass: [QXStructuralTransfer class]];
			[CSCzechToXStructuralTransfer setTargetLanguage: @"de"];
		}
		//QXLexicalTransfer* lextr = [[[QXLexicalTransfer alloc] initWithFile: [NSString stringWithUTF8String: argv[2]]] autorelease];
		[NSDictionary setLexicalTransfer: lextr];
		//QXStructuralTransfer* strtr = [[[QXStructuralTransfer alloc] init] autorelease];
		[NSDictionary setStructuralTransfer: strtr];
		id mg;
		if (!strcmp(argv[1] + 2, "sk")){
			mg = [[CSSlovakMorphologicalGenerator alloc] initWithFile: @(argv[3])];
		}
		if (!strcmp(argv[1] + 2, "pl")){
			mg = [[CSPolishMorphologicalGenerator alloc] initWithFile: @(argv[3])];
		}
		if (!strcmp(argv[1] + 2, "ru")){
			mg = [[CSRussianMorphologicalGenerator alloc] initWithFile: @(argv[3])];
		}
		if (!strcmp(argv[1] + 2, "de")){
			mg = [[CSGermanMorphologicalGenerator alloc] initWithFile: @(argv[3])];
		}
		[NSDictionary setTargetMorphology: mg];
		/* testing morphological synthesis
		NSLog(@"%@", [mg generate: @"lehnen" tags: [NSSet setWithObjects: @"PA2", nil]]);
		exit(0); /**/
		NSMutableData* data = [NSMutableData data];
		FILE* file = stdin;
		while (!feof(file)) {
			char c;
			fscanf(file, "%c", &c);
			[data appendBytes: &c length: 1];
		}
		//NSLog(@"%u", [data length]);
		NSUnarchiver* unarchiver = [[NSUnarchiver alloc] initForReadingWithData: data];
		NSArray* input = [unarchiver decodeObject];
		NSEnumerator* enumerator = [input objectEnumerator];
		NSArray* bundle;
		while (bundle = [enumerator nextObject]) {
			BOOL translated = NO;
			unsigned n = [bundle[0] unsignedIntValue];
			NSLog(@"sentence %u", n);
			NSArray* source = bundle[1];
			printf("@%u %s\n", n, [NSString stringWithArray: source].UTF8String);
			NSArray* dicts = bundle[2];
			//NSLog(@"%@", dicts);
			NSLog(@"translating...");
			NSArray* translation = [dicts translateTagsAsOutput: tagsAsOutput];
			NSLog(@"...done");
			if (translation != nil) {
				NSArray* results = [translation completize];
				NSEnumerator* enumerator = [results objectEnumerator];
				NSString* result;
				while ((result = [enumerator nextObject])) {
					printf("  %s\n", result.UTF8String);
				}
				translated = YES;
			} else NSLog(@"##### finalizer -- translation is null");
		}
		//NSLog(@"%@", [QXLexicalTransfer messages]);
		//NSLog(@"%@", [CSMorphologicalGenerator messages]);
		FILE* logFile = fopen("transfer.log", "w");
		enumerator = [[QXLexicalTransfer unknownLemmas] objectEnumerator];
		NSString* lemma;
		while (lemma = [enumerator nextObject]) {
			fprintf(logFile, "%s|\n", lemma.UTF8String);
		}
		fclose(logFile);
	}
	return 0;
	
    //return NSApplicationMain(argc,  (const char **) argv);
}
