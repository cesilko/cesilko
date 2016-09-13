//
//  CSGermanMorphologicalGenerator.h
//  transfer
//
//  Created by Petr Homola on 23.06.08.
//  Copyright 2008 Univerzita Karlova. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSMorphologicalGenerator.h"

@interface CSGermanMorphologicalGenerator : CSMorphologicalGenerator {

}

- (NSSet*)generate:(NSString*)lemma attributes:(NSDictionary*)dict;
- (NSMutableSet*)generate:(NSString*)lemma tags:(NSSet*)tags;
- (int)containsTags:(NSArray*)paradigm :(NSSet*)set;

@end
