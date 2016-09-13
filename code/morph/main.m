//
//  main.m
//  morph_cz
//
//  Created by Petr Homola on 4.03.08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSCzechMorphologicalAnalyzer.h"
#import "CSReader.h"

int main(int argc, char *argv[]) {
	//NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@autoreleasepool {
	NSString* morphFile = [NSString stringWithUTF8String: argv[2]];
	NSString* inputFile = [NSString stringWithUTF8String: argv[3]];
	
        Class morphClass = Nil;
	if (!strcmp(argv[1], "cz"))
        morphClass = [CSCzechMorphologicalAnalyzer class];
		//[CSCzechMorphologicalAnalyzer poseAsClass: [CSMorphologicalAnalyzer class]];
	
	CSMorphologicalAnalyzer* ma = [[morphClass alloc] initWithParameters: [NSDictionary dictionaryWithObjectsAndKeys: morphFile, @"file", nil]];
	CSReader* reader = [CSReader readerWithFile: inputFile];
	NSMutableArray* sentences = [NSMutableArray array];
	NSEnumerator* enumerator = [[reader sentences] objectEnumerator];
	NSArray* sentence;
	while (sentence = [enumerator nextObject]) {
		if ([[[sentence objectAtIndex: 0] substringToIndex: 1] isEqual: @"§"]) break;
		//NSLog(@"%@", [sentence objectAtIndex: 0]);
		NSArray* array = [ma analyzeArray: sentence];
		//NSLog(@"%@ %u", array, [array count]);
		[sentences addObject: [NSArray arrayWithObjects: sentence, array, nil]];
	}
	[ma release];
	//NSLog(@"%u", [sentences count]);
	
	NSMutableData* data = [NSMutableData data];
	NSArchiver* archiver = [[[NSArchiver alloc] initForWritingWithMutableData: data] autorelease];
	[archiver encodeObject: sentences];
	//NSLog(@"%u", [data length]);
	const char* bytes = [data bytes];
	unsigned length = [data length], i;
	for (i = 0; i < length; i++) {
		printf("%c", bytes[i]);
	}
	
	//pause();
	//[pool release];
	return 0;
	}
    //return NSApplicationMain(argc,  (const char **) argv);
}
