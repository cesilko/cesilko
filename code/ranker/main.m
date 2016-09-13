//
//  main.m
//  ranker
//
//  Created by Petr Homola on 6.03.08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSRanker.h"

int main(int argc, char *argv[]) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSString *lang = nil, *tagCorpusFileName = nil;
	int tagGranularity = 0;
	if (argc > 3) {
		NSString* tmp = [NSString stringWithUTF8String: argv[2]];
		lang = [tmp substringToIndex: 2];
		tagGranularity = [[tmp substringFromIndex: 2] intValue];
		tagCorpusFileName = [NSString stringWithUTF8String: argv[3]];
	}
	CSRanker* ranker = [[CSRanker alloc] initWithLang: lang tagGranularity: tagGranularity tagCorpusFileName: tagCorpusFileName];
	[ranker runWithFile: [NSString stringWithUTF8String: lang == nil ? argv[1] : [tagCorpusFileName UTF8String]]];
	[ranker release];
	
	//pause();
	[pool release];
	return 0;
	
    //return NSApplicationMain(argc,  (const char **) argv);
}
