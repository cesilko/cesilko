//
//  MorphologicalAnalyzer.h
//  CzSk
//
//  Created by Petr Homola on 21.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface CSMorphologicalAnalyzer : NSObject {
	NSMutableDictionary* prefixes;
	NSMutableDictionary* paradigms;
	NSDictionary* parameters;
	NSMutableDictionary* tagMap;
}
- (id)initWithParameters:(NSDictionary*)params;
- (void)load;
- (NSArray*)analyze:(NSString*)form;
- (NSArray*)analyzeArray:(NSArray*)sentence;
- (NSArray*)analyzeTaggedArray:(NSArray*)sentence;
- (void)enrich:(NSMutableDictionary*)dict;
@end
