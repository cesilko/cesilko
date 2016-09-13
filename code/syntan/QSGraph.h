//
//  QSGraph.h
//  Systems-Q
//
//  Created by Petr Homola on 14.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "QSVertex.h"

// retezcovy graf

@interface QSGraph : NSObject {
	QSVertex* firstNode; // pocatecni vrchol
	QSVertex* lastNode; // koncovy vrchol
	NSMutableArray* vertices;
	unsigned numberOfAddedEdges;
}

- (id)initWithArray:(NSArray*)input;
+ (id)graphWithArray:(NSArray*)input;
- (id)initWithArrayAsSequence:(NSArray*)input;
+ (id)graphWithArrayAsSequence:(NSArray*)input;
- (QSVertex*)firstNode;
- (QSVertex*)lastNode;
- (void)setFirstNode:(QSVertex*)node;
- (NSArray*)chainsWithLength:(unsigned)length level:(unsigned)level type:(NSString*)type unusedOnly:(BOOL)unusedOnly; // vrati podretezce dane delky a urovne vypoctu
- (NSArray*)chainsWithLength:(unsigned)length level:(unsigned)level type:(NSString*)type unusedOnly:(BOOL)unusedOnly fromNode:(QSVertex*)initialNode restrictToNode:(BOOL)restr processedNodes:(NSMutableSet*)processedNodes tails: (NSMutableDictionary*)tails; // dtto od zadaneho vrcholu, pokud restrict == YES, jen podretezce s danym pocatecnim vrcholem
- (NSArray*)allEdges;
- (NSArray*)allEdges:(QSVertex*)initialNode processedNodes:(NSMutableSet*)processedNodes;
- (NSSet*)traverse; // vrati vsechny uplne cesty grafem; eliminuje duplicitni vysledky
- (NSSet*)traverseFrom:(QSVertex*)node;
- (NSArray*)dictionaries;
- (void)addVertex:(QSVertex*)vertex;
- (unsigned)numberOfAddedEdges;
- (void)increaseNumberOfAddedEdgesBy:(unsigned)n;

@end
