//
//  CSSlovakMorphologicalGenerator.h
//  CzSk
//
//  Created by Petr Homola on 21.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSMorphologicalGenerator.h"

@interface CSSlovakMorphologicalGenerator : CSMorphologicalGenerator {
}
- (id)initWithFile:(NSString*)_fileName;
- (NSArray*)generateSentence:(NSArray*)sentence;
- (NSString*)cutTag:(NSString*)tag forLemma:(NSString**)lemma;
- (void)load;
- (NSArray*)generateCore:(NSString*)lemma tagPrefix:(NSString*)tagPrefix superlative:(BOOL)superlative negation:(BOOL)negation;
@end
