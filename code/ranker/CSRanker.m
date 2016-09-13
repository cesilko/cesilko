//
//  CSRanker.m
//  CzSk
//
//  Created by Petr Homola on 8.01.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

//#include <math.h>
#import "CSRanker.h"
#import "QX_String.h"

#define MAX_DATA_LENGTH		INT_MAX
//#define MAX_DATA_LENGTH		10000000

@implementation CSRanker

- (id)initWithLang:(NSString*)_lang tagGranularity:(int)_tagGranularity tagCorpusFileName:(NSString*)_tagCorpusFileName {
	if (self = [super init]) {
		lang = [_lang retain];
		tagCorpusFileName = [_tagCorpusFileName retain];
		tagGranularity = _tagGranularity;
	}
	return self;
}

- (void)run {
	[self runWithFile: @"/Users/phomola/dev/data/raw_sk.txt"];
}

- (void)runWithFile:(NSString*)_fileName {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSMutableSet* symbols = [[NSMutableSet alloc] initWithCapacity: 1000000];
	NSMutableDictionary* mapping = [[NSMutableDictionary alloc] initWithCapacity: 1000000];
	
	//NSDate* pointZero = [[NSDate alloc] init];
	const char* fileName = [_fileName UTF8String];
	FILE* file = fopen(fileName, "r");
	char cline[1000]; int dataLength = 0;
	while (fgets(cline, 1000, file) != NULL) {
		cline[strlen(cline) - 1] = 0;
		NSString* token = [[NSString alloc] initWithUTF8String: cline];
		token = [self shortenToken: token];
		[symbols addObject: token];
		[token release];
		dataLength++;
		if (dataLength >= MAX_DATA_LENGTH) break;
	}
	//fclose(file);
	NSLog(@"data length: %d, symbol count: %d", dataLength, [symbols count]);

	[pool release];
	pool = [[NSAutoreleasePool alloc] init];
	NSEnumerator* enumerator = [symbols objectEnumerator];
	NSString* token; int i = 1;
	while (token = [enumerator nextObject]) {
		[mapping setObject: [NSNumber numberWithInt: i++] forKey: token];
	}
	[mapping setObject: [NSNumber numberWithInt: 0] forKey: @"/"];
	
	[pool release];
	pool = [[NSAutoreleasePool alloc] init];
	int* data = malloc(dataLength * sizeof(int));
	//file = fopen(fileName, "r");
	fseek(file, 0, SEEK_SET);
	i = 0;
	while (fgets(cline, 1000, file) != NULL) {
		//if (strlen(cline) == 0) NSLog(@"!!!");
		cline[strlen(cline) - 1] = 0;
		NSString* token = [[NSString alloc] initWithUTF8String: cline];
		//if (i >= dataLength) NSLog(@"!!!");
		token = [self shortenToken: token];
		NSNumber* value = [mapping objectForKey: token];
		//if (value == nil) NSLog(@"-%@-", token);
		data[i] = [value intValue];
		[token release];
		i++;
	}
	fclose(file);
	[pool release];
	int symbolCount = [symbols count];
	[symbols release];
	NSLog(@"data read");
	/*int heldoutDataLength = 10000;
	dataLength -= heldoutDataLength;
	int* heldoutData = data + dataLength;*/
	
	int* counts1 = malloc(symbolCount * sizeof(int));
	for (i = 0; i < symbolCount; i++) counts1[i] = 0;
	for (i = 0; i < dataLength; i++) counts1[data[i]]++;
	NSLog(@"counts1 done");
	
	HashtableForNGrams* bigrams = [[HashtableForNGrams alloc] initWithCapacity: 10000000 ngramSize: 2 data: data];
	{NGram ngram;
	for (i = 0; i < dataLength; i++)  {
		ngram.pos = i;
		if ([self isValidNGram: &ngram data: data size: 2]) {
			int count = [bigrams intForKey: &ngram];
			if (count == -1) count = 0;
			[bigrams setInt: ++count forKey: &ngram];
		}
	}}
	NSLog(@"counts2 done: %d", [bigrams count]);
	HashtableForNGrams* trigrams = [[HashtableForNGrams alloc] initWithCapacity: 20000000 ngramSize: 3 data: data];
	{NGram ngram;
	for (i = 0; i < dataLength; i++)  {
		ngram.pos = i;
		if ([self isValidNGram: &ngram data: data size: 3]) {
			int count = [trigrams intForKey: &ngram];
			if (count == -1) count = 0;
			[trigrams setInt: ++count forKey: &ngram];
		}
	}}
	NSLog(@"counts3 done: %d", [trigrams count]);
	/*HashtableForNGrams* tetragrams = [[HashtableForNGrams alloc] initWithCapacity: 30000000 ngramSize: 4 data: data];
	{NGram ngram;
	for (i = 0; i < dataLength; i++)  {
		ngram.pos = i;
		if ([self isValidNGram: &ngram data: data size: 4]) {
			int count = [tetragrams intForKey: &ngram];
			if (count == -1) count = 0;
			[tetragrams setInt: ++count forKey: &ngram];
		}
	}}
	NSLog(@"counts4 done: %d", [tetragrams count]);*/
	counts1[0] = 1;
	[self evaluate: mapping dataLength: dataLength symbolCount: symbolCount unigrams: counts1 bigrams: bigrams trigrams: trigrams];
	[mapping release];
	/*NSLog(@"time elapsed: %f", -[pointZero timeIntervalSinceNow]);
	[pointZero release];
	pointZero = [NSDate date];
	double lambdas[4];
	lambdas[3] = 0.25;
	lambdas[2] = 0.25;
	lambdas[1] = 0.25;
	lambdas[0] = 0.25;
	[self smooth: data :lambdas :heldoutData :dataLength :heldoutDataLength :symbolCount :counts1 :bigrams :trigrams];
	NSLog(@"%f %f %f %f", lambdas[3], lambdas[2], lambdas[1], lambdas[0]);
	NSLog(@"time elapsed: %f", -[pointZero timeIntervalSinceNow]);*/
	free(data);
	free(counts1);
	[bigrams release];
	[trigrams release];
	//[tetragrams release];
}

- (void)evaluate:(NSDictionary*)mapping dataLength:(int)dataLength symbolCount:(int)symbolCount unigrams:(int*)counts1 bigrams:(HashtableForNGrams*)bigrams trigrams:(HashtableForNGrams*)trigrams {
	FILE* file    = stdin; /*/ fopen("/Users/phomola/dev/czsk/tmp.out", "r"); /**/ //fopen("/Users/phomola/Desktop/czsk_out.txt", "r");
	FILE* outFile = stdout; //fopen("/Users/phomola/Desktop/czsk_eval.txt", "w");
	FILE* logFile = fopen("ranker.log", "w");
	char cline[4096]; NSMutableArray* sentences = nil; NSString* sourceSentence;
	while (fgets(cline, 4096, file) != NULL) {

		NSString* line = [[NSString stringWithUTF8String: cline] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];

		if ([line length] > 0) {

			if ([line rangeOfString: @"!!!"].location == 0) continue;
			if ([line characterAtIndex: 0] == '@') {

				if (sentences != nil) {
					NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
					[self evaluateArray: sentences mapping: mapping dataLength: dataLength symbolCount: symbolCount unigrams: counts1 bigrams: bigrams trigrams: trigrams sourceSentence: sourceSentence file: outFile log: logFile];
					[pool release];
				}
				sourceSentence = line;
				sentences = [NSMutableArray array];
			} else [sentences addObject: line];
		}
	}
	if (sentences != nil) {
		[self evaluateArray: sentences mapping: mapping dataLength: dataLength symbolCount: symbolCount unigrams: counts1 bigrams: bigrams trigrams: trigrams sourceSentence: sourceSentence file: outFile log: logFile];
	}
	fprintf(outFile, "@@\n");
	fclose(logFile);
	//fclose(file);
	//fclose(outFile);
}

- (BOOL)evaluateArray:(NSArray*)sentences mapping:(NSDictionary*)mapping dataLength:(int)dataLength symbolCount:(int)symbolCount unigrams:(int*)counts1 bigrams:(HashtableForNGrams*)bigrams trigrams:(HashtableForNGrams*)trigrams sourceSentence:(NSString*)sourceSentence file:(FILE*)file log:(FILE*)logFile {
	NSEnumerator* enumerator = [sentences objectEnumerator];
	NSString *sentence, *bestSentence = nil; double bestScore = INT_MAX;
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	int i = 0;
	while ((sentence = [enumerator nextObject])) {
		if (++i % 1000 == 0) {
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
		}
		double score = [self evaluateSentence: sentence mapping: mapping dataLength: dataLength symbolCount: symbolCount unigrams: counts1 bigrams: bigrams trigrams: trigrams];

		if (score < bestScore) {
			bestScore = score;
			bestSentence = lang == nil ? sentence : [self removeTagsFromSentence: sentence];
		}
	}

	[pool release];
	if (bestSentence != nil) {
		fprintf(file, "%s\n", [sourceSentence UTF8String]);
		fprintf(logFile, "%%%s\n", [sourceSentence UTF8String]);
		fprintf(logFile, "%s\n", [bestSentence UTF8String]);
		enumerator = [sentences objectEnumerator];
		while ((sentence = [enumerator nextObject])) {
			sentence = lang == nil ? sentence : [self removeTagsFromSentence: sentence];
			fprintf(file, "%s%s\n", [sentence isEqual: bestSentence] ? "**" : "  ", [sentence UTF8String]);
		}
		NSLog(@"## %@", bestSentence);
	}

	return bestSentence != nil;
}

- (NSString*)removeTagsFromSentence:(NSString*)sentence {
	NSArray* tokens = [sentence tokenize];
	//NSLog(@"################### %@", tokens);
	NSMutableArray* words = [NSMutableArray array];
	NSEnumerator* enumerator = [tokens objectEnumerator];
	NSString* token;
	while (token = [enumerator nextObject]) {
		NSRange range = [token rangeOfString: @"_"];
		if (range.location != 0) {
			if (range.location == NSNotFound) [words addObject: [NSSet setWithObject: token]];
			else {
				NSString* word = [token substringToIndex: range.location];
				if (![word isEqual: @"xxx"]) [words addObject: [NSSet setWithObject: word]];
			}
		}
	}
	NSString* result = [NSString completize: words];
	//NSLog(@"################### %@", result);
	return [result retain];
}

- (double)evaluateSentence:(NSString*)sentence mapping:(NSDictionary*)mapping dataLength:(int)dataLength symbolCount:(int)symbolCount unigrams:(int*)counts1 bigrams:(HashtableForNGrams*)bigrams trigrams:(HashtableForNGrams*)trigrams {
	NSArray* tokens = [sentence tokenize];
if(tokens==NULL){
}
else{

}
	
	int* data = malloc([tokens count] * sizeof(int));
	int i; double score = 0;
	for (i = 0; i < [tokens count]; i++) {
		NSString* token = [[tokens objectAtIndex: i] lowercaseString];
		//NSLog(@"#################### %@", token);
		token = [self shortenToken: token];
		if (lang != nil) {
			NSString* tag = @"xxx";
			NSRange range = [token rangeOfString: @"_"];
			if (range.location != 0 && range.location != NSNotFound) {
				tag = [token substringFromIndex: range.location + 1];
				range = [tag rangeOfString: @"_"];
				if (range.location != NSNotFound) tag = [tag substringToIndex: range.location];
				if (tagGranularity == 2) {
					if ([tag isEqual: @"verb"]) {
						if ([token rangeOfString: @"_fin"].location != NSNotFound) tag = @"verb_fin";
						if ([token rangeOfString: @"_inf"].location != NSNotFound) tag = @"verb_inf";
					}
					if ([tag isEqual: @"n"] || [tag isEqual: @"a"] || [tag isEqual: @"art"] || [tag isEqual: @"pron"]) {
						if ([token rangeOfString: @"_nom"].location != NSNotFound) tag = [tag stringByAppendingString: @"_nom"];
						if ([token rangeOfString: @"_gen"].location != NSNotFound) tag = [tag stringByAppendingString: @"_gen"];
						if ([token rangeOfString: @"_dat"].location != NSNotFound) tag = [tag stringByAppendingString: @"_dat"];
						if ([token rangeOfString: @"_acc"].location != NSNotFound) tag = [tag stringByAppendingString: @"_acc"];
					}
				}
				NSLog(@"################# %@", tag);
			}
		}
		NSNumber* num = [mapping objectForKey: token];
		if (num != nil) data[i] = [num intValue]; else data[i] = 0;
		NGram ngram, history;
		double sc;
		ngram.pos = i; history.pos = i - 1;
		if (i >= 2) {
			int count1 = [trigrams intForKey: &ngram withData: data];
			if (count1 > 0) {
				int count2 = [bigrams intForKey: &history withData: data];
				if (count2 <= 0) { NSLog(@"!!! trigram"); exit(1); }
				score -= log(((double) count1 / (double) count2));
				continue;
			}
		}
		if (i >= 1) {
			int count1 = [bigrams intForKey: &ngram withData: data];
			if (count1 > 0) {
				int count2 = counts1[data[i - 1]];
				if (count2 <= 0) { NSLog(@"!!! bigram"); exit(1); }
				score -= log(count1 / (double) count2);
				continue;
			}
		}
		if (counts1[data[i]] <= 0) { NSLog(@"!!! unigram"); exit(1); }
		score -= log(counts1[data[i]] / (double) dataLength);
		//score = -log(1.0 / symbolCount);
	}
	free(data);
	return score;
}

- (double*)smooth:(int*)data :(double*)lambdas :(int*)heldoutData :(int)dataLength :(int)heldoutDataLength :(int)symbolCount :(int*)counts1 :(HashtableForNGrams*)bigrams :(HashtableForNGrams*)trigrams {
	double counts[4];
	int i;
	for (i = 0; i < 10; i++) {
		NSLog(@"smoothing -- %f %f %f %f", lambdas[3], lambdas[2], lambdas[1], lambdas[0]);
		counts[0] = counts[1] = counts[2] = counts[3] = 0.01;
		int j, prev1 = 0, prev2 = 0;
		for (j = 0; j < heldoutDataLength; j++) {
			NGram ngram;
			int symbol = heldoutData[j];
			if (symbol == 0 || prev1 == 0 || prev2 == 0) {
				prev2 = prev1;
				prev1 = symbol;
				continue;
			}
			int unigramCount = counts1[symbol];
			double p1 = unigramCount / (double) symbolCount, p2 = 0.0, p3 = 0.0;
			ngram.pos = dataLength + j;
			if (j > 0) {
				int bigramCount = [bigrams intForKey: &ngram];
				if (bigramCount != -1) p2 = bigramCount / (double) counts1[heldoutData[j - 1]];
				if (j > 1) {
					int trigramCount = [trigrams intForKey: &ngram];
					if (trigramCount != -1) {
						NGram history;
						history.pos = dataLength + j - 1;
						p3 = trigramCount / (double) [bigrams intForKey: &history];
					}
				}
			}
			double p = lambdas[3] * p3 + lambdas[2] * p2 + lambdas[1] * p1 + lambdas[0] / symbolCount;
			counts[3] += lambdas[3] * p3 / p;
			counts[2] += lambdas[2] * p2 / p;
			counts[1] += lambdas[1] * p1 / p;
			counts[0] += lambdas[0] * (1 / symbolCount) / p;
			prev2 = prev1;
			prev1 = symbol;
		}
		//NSLog(@"lambda counts: %f %f %f %f", counts[3], counts[2], counts[1], counts[0]);
		double sum = counts[0] + counts[1] + counts[2] + counts[3];
		lambdas[3] = counts[3] / sum;
		lambdas[2] = counts[2] / sum;
		lambdas[1] = counts[1] / sum;
		lambdas[0] = counts[0] / sum;
	}
	return lambdas;
}

- (NSString*)shortenToken:(NSString*)token {
	return token; //[token length] <= 50 ? token : [[token substringToIndex: 50] retain];
}

- (BOOL)isValidNGram:(NGram*)ngram data:(int*)data size:(int)size {
	int pos = ngram->pos;
	while (size > 0 && pos >= 0) {
		if (data[pos] == 0) return NO;
		pos--;
		size--;
	}
	return YES;
}

- (void)dealloc {
	[lang release];
	[tagCorpusFileName release];
	[super dealloc];
}

@end
