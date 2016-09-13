//
//  main.m
//  syntan
//
//  Created by Petr Homola on 4.03.08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "QSGraph.h"
#import "QSGrammar.h"
#import "LXListParser.h"
#import "Linux.h"

int main(int argc, char *argv[]) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSError* error;
	LXListParser* lp = [LXListParser listParserWithString: [NSString stringWithContentsOfFile: [NSString stringWithUTF8String: argv[1]] encoding: NSUTF8StringEncoding error: &error]];
	NSArray* list = [lp parse];
	QSGrammar* grammar1 = [QSGrammar grammarWithArray: list maxSpan: 0]; // hlavni gramatika

	lp = [LXListParser listParserWithString: [NSString stringWithContentsOfFile: [NSString stringWithUTF8String: argv[2]]]];
	list = [lp parse];
	QSGrammar* grammar2 = [QSGrammar grammarWithArray: list maxSpan: 0]; // gramatika pro postprocessing
	
	NSMutableData* data = [NSMutableData data];
	while (!feof(stdin)) {
		char c;
		scanf("%c", &c);
		[data appendBytes: &c length: 1];
	}
	//NSLog(@"%u", [data length]);
	NSUnarchiver* unarchiver = [[[NSUnarchiver alloc] initForReadingWithData: data] autorelease];
	NSArray* sentences = [unarchiver decodeObject];
	
	//NSLog(@"%u", [sentences count]);
	NSMutableArray* results = [NSMutableArray array];
	NSEnumerator* enumerator = [sentences objectEnumerator];
	NSArray* pair;
	unsigned n = 0, empty = 0;
	while (pair = [enumerator nextObject]) {
		n++;
		NSLog(@"***** sentence %u *****", n);
		NSArray* sentence1 = [pair objectAtIndex: 0];
		NSArray* sentence2 = [pair objectAtIndex: 1];
		//NSLog(@"%u %u", [sentence1 count], [sentence2 count]);
		//NSLog(@"%@", sentence2);
		QSGraph* graph = [QSGraph graphWithArray: sentence2];
		//NSLog(@"%@", [graph description]); break;
		[grammar1 applyTo: graph];
		graph = [[graph copy] autorelease];
		[grammar2 applyTo: graph];
		//NSLog(@"%@", [graph description]);
		if ([graph firstNode] == [graph lastNode]) {
			empty++;
			NSLog(@"the resulting graph is empty (%u)", n);
		} else {
			NSArray* result = [NSArray arrayWithObjects: [NSNumber numberWithUnsignedInt: n], sentence1, [graph dictionaries], nil];
			[results addObject: result];
			NSLog(@"sentence analyzed (%u), length: %u", n, [sentence1 count]);
			//NSLog(@"%@", result);
		}
	}
	NSLog(@"##### empty graphs: %f", [grammar1 percentOfEmptyGraphs]);

	NSMutableData* data2 = [NSMutableData data];
	NSArchiver* archiver = [[[NSArchiver alloc] initForWritingWithMutableData: data2] autorelease];
	[archiver encodeObject: results];
	//NSLog(@"%u", [data length]);
	const char* bytes = [data2 bytes];
	unsigned length = [data2 length], i;
	for (i = 0; i < length; i++) {
		printf("%c", bytes[i]);
	}
	
	//pause();
	[pool release];
	return 0;
	
    //return NSApplicationMain(argc,  (const char **) argv);
}
