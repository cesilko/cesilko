//
//  QX_Transfer.h
//  Systems-Q
//
//  Created by Petr Homola on 17.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>


@class QXLexicalTransfer;
@class QXStructuralTransfer;
@class CSMorphologicalGenerator;

@interface NSDictionary (QXTransfer)

- (NSArray*)transfer:(BOOL)recursive done:(BOOL*)done;
+ (NSMutableArray*)transferArray:(NSMutableArray*)array;
- (id)leftMostChild;
- (id)leftClosestChild;
- (id)rightMostChild;
- (id)rightClosestChild;
+ (NSArray*)linearize:(NSEnumerator*)enumerator;
+ (NSArray*)paths:(NSString*)start end:(NSString*)end edges:(NSDictionary*)edges cache:(NSMutableDictionary*)cache;
+ (QXLexicalTransfer*)lexicalTransfer;
+ (void)setLexicalTransfer:(QXLexicalTransfer*)_lexicalTransfer;
+ (QXStructuralTransfer*)structuralTransfer;
+ (void)setStructuralTransfer:(QXStructuralTransfer*)_structuralTransfer;
+ (CSMorphologicalGenerator*)targetMorphology;
+ (void)setTargetMorphology:(CSMorphologicalGenerator*)_targetMorphology;
@end

@interface NSArray (QXTransfer)
- (NSString*)textualDescription;
- (NSArray*)translate;
- (NSArray*)translateTagsAsOutput:(BOOL)tagsAsOutput;
- (NSArray*)completize;
- (void)prune;
- (NSSet*)extractTargetFormsTagsAsOutput:(BOOL)tagsAsOutput;
- (BOOL)tryToPrune:(NSDictionary*)dict1 :(NSDictionary*)dict2 rightNode:(id)node1 :(id)node2 pruned:(NSMutableSet*)pruned pruneIndex:(int)index;
- (void)writeToFileAtPath:(NSString*)path;

@end
