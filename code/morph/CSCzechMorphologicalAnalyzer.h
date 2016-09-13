//
//  CzechMorphologicalAnalyzer.h
//  CzSk
//
//  Created by Petr Homola on 21.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "CSMorphologicalAnalyzer.h"

@interface CSCzechMorphologicalAnalyzer : CSMorphologicalAnalyzer {
	
}

- (id)initWithParameters:(NSDictionary*)params;
- (NSMutableArray*)analyzeCore:(NSString*)form withPrefix:(int)cutPrefix acceptUnknown:(BOOL)acceptUnknown;
- (NSArray*)analyzeTaggedArray:(NSArray*)sentence;
- (void)addGender:(unichar)value toDictionary:(NSMutableDictionary*)dict;
- (void)addPronGender:(unichar)value toDictionary:(NSMutableDictionary*)dict;
- (void)addNumber:(unichar)value toDictionary:(NSMutableDictionary*)dict;
- (void)addPronNumber:(unichar)value toDictionary:(NSMutableDictionary*)dict;
- (void)addCase:(unichar)value toDictionary:(NSMutableDictionary*)dict;
- (void)addDegree:(unichar)value toDictionary:(NSMutableDictionary*)dict;
- (void)addPerson:(unichar)value toDictionary:(NSMutableDictionary*)dict;
- (void)addNegation:(unichar)value toDictionary:(NSMutableDictionary*)dict;

@end
