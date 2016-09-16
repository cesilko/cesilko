//
//  MorphologicalAnalyzer.m
//  CzSk
//
//  Created by Petr Homola on 21.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CSMorphologicalAnalyzer.h"

@implementation CSMorphologicalAnalyzer
- (id)initWithParameters:(NSDictionary*)params {
	NSLog(@"abstract instance method invoked in %@", self.className);
	return nil;
}

- (void)load {
	NSLog(@"abstract instance method invoked in %@", self.className);
}

- (NSArray*)analyze:(NSString*)form {
	NSLog(@"abstract instance method invoked in %@", self.className);
	return nil;
}

- (void)enrich:(NSMutableDictionary*)dict {
	NSLog(@"abstract instance method invoked in %@", self.className);
}

- (NSArray*)analyzeTaggedArray:(NSArray*)sentence {
	NSLog(@"abstract instance method invoked in %@", self.className);
	return nil;
}

- (NSArray*)analyzeArray:(NSArray*)sentence {
	NSLog(@"abstract instance method invoked in %@", self.className);
	return nil;
}

@end
