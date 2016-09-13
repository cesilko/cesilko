//
//  CSRanker.h
//  CzSk
//
//  Created by Petr Homola on 8.01.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HashtableForNGrams.h"

@interface CSRanker : NSObject {
	NSString* lang;
	NSString* tagCorpusFileName;
	int tagGranularity;
}

- (id)initWithLang:(NSString*)_lang tagGranularity:(int)_tagGranularity tagCorpusFileName:(NSString*)_tagCorpusFileName;
- (void)run;
- (void)runWithFile:(NSString*)_fileName;
- (double*)smooth:(int*)data :(double*)lambdas :(int*)heldoutData :(int)dataLength :(int)heldoutDataLength :(int)symbolCount :(int*)counts1 :(HashtableForNGrams*)bigrams :(HashtableForNGrams*)trigrams;
- (BOOL)isValidNGram:(NGram*)ngram data:(int*)data size:(int)size;
- (void)evaluate:(NSDictionary*)mapping dataLength:(int)dataLength symbolCount:(int)symbolCount unigrams:(int*)counts1 bigrams:(HashtableForNGrams*)bigrams trigrams:(HashtableForNGrams*)trigrams;
- (BOOL)evaluateArray:(NSArray*)sentences mapping:(NSDictionary*)mapping dataLength:(int)dataLength symbolCount:(int)symbolCount unigrams:(int*)counts1 bigrams:(HashtableForNGrams*)bigrams trigrams:(HashtableForNGrams*)trigrams sourceSentence:(NSString*)sourceSentence file:(FILE*)file log:(FILE*)logFile;
- (double)evaluateSentence:(NSString*)sentence mapping:(NSDictionary*)mapping dataLength:(int)dataLength symbolCount:(int)symbolCount unigrams:(int*)counts1 bigrams:(HashtableForNGrams*)bigrams trigrams:(HashtableForNGrams*)trigrams;
- (NSString*)shortenToken:(NSString*)token;
- (NSString*)removeTagsFromSentence:(NSString*)sentence;

@end
