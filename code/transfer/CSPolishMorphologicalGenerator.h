//
//  CSPolishMorphologicalGenerator.h
//  transfer
//
//  Created by Petr Homola on 12.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSMorphologicalGenerator.h"

@interface CSPolishMorphologicalGenerator : CSMorphologicalGenerator {

}
- (NSSet*)generate:(NSString*)lemma attributes:(NSDictionary*)dict;
- (NSMutableSet*)generate:(NSString*)lemma tags:(NSSet*)tags;
- (BOOL)containsTags:(NSString*)tags :(NSSet*)set;
@end
