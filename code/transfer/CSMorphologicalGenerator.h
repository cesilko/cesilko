//
//  CSMorphologicalGenerator.h
//  CzSk
//
//  Created by Petr Homola on 21.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSMorphologicalGenerator : NSObject {
	NSMutableDictionary* prefixes;
	NSMutableDictionary* paradigms;
	NSMutableDictionary* lemmas;
	NSMutableDictionary* endings;
	NSString* fileName;
}
- (id)initWithFile:(NSString*)_fileName;
- (void)load;
- (NSArray*)generate:(NSString*)lemma tagPrefix:(id)tagPrefix;
- (NSArray*)generateArray:(NSArray*)sentence;
- (NSArray*)generateByExtendingAVMs:(NSArray*)avms;
//- (NSArray*)analyze:(NSString*)form;
+ (void)log:(NSString*)message;
+ (NSArray*)messages;
@end
