//
//  QSGrammar.h
//  Systems-Q
//
//  Created by Petr Homola on 30.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "QSRule.h"
#import "QSGraph.h"
#import "QXStopWatch.h"

// gramatika (mnozina prepisovacich pravidel)

@interface QSGrammar : NSObject {
	NSMutableSet* allRules;
	NSMutableDictionary* mapOfRules;
	NSMutableDictionary* mapOfRulesByFixedSignature;
	NSMutableDictionary* volatileAttributes;
	NSMutableDictionary* fixedAttributes;
	NSMutableDictionary* allAttributes;
	NSMutableDictionary* rulesForWordByValue;
	NSMutableDictionary* rulesForWordByLemma;
	//NSMutableSet* oddRules;
	//NSMutableSet* evenRules;
	NSMutableDictionary* rulesByFirstType;
	BOOL deterministic;
	unsigned maxSpan;
	unsigned rulesTriedToApply;
	unsigned countTriedToApply;
	QXStopWatch* stopWatch;
	unsigned noOfGraphs;
	unsigned noOfEmptyGraphs;
}

+ (id)grammar; // vytvori prazdnou gramatiku
- (id)initWithArray:(NSArray*)input maxSpan:(unsigned)_maxSpan; // vytvori gramatiku ze seznamu
+ (id)grammarWithArray:(NSArray*)input maxSpan:(unsigned)_maxSpan; // vytvori gramatiku ze seznamu
- (void)addRule:(QSRule*)rule; // prida pravidlo ke gramatice
- (QSGraph*)applyTo:(QSGraph*)graph; // aplikuje gramatiku na graf
- (void)applyTo:(QSGraph*)graph level:(unsigned)level nodeIndex:(int*)nodeIndex; // aplikuje gramatiku na hrany v grafu s urovni level od uzlu nodeIndex
- (void)applyTo:(QSGraph*)graph level:(unsigned)level nodeIndex:(int*)nodeIndex rules:(NSSet*)rules succeeded:(BOOL*)success; // aplikuje mnozinu pravidel na hrany v grafu s urovni level od uzlu nodeIndex
- (void)applyWith:(NSDictionary*)params;
- (BOOL*)applyInThreadTo:(QSGraph*)graph level:(unsigned)level nodeIndex:(int*)nodeIndex rules:(NSSet*)rules succeeded:(BOOL*)success; // aplikuje v novem vlakne mnozinu pravidel na hrany v grafu s urovni level od uzlu nodeIndex; vrati ukazatel s YES, kdyz vlakno skoncilo
- (void)setDeterministic:(BOOL)d;
- (NSDictionary*)mapOfRules;
- (BOOL)signature:(NSArray*)signature conformsToRuleSignature:(NSArray*)ruleSignature;
- (void)increaseRulesTriedToApply:(unsigned)count;
- (void)updateVolatileAttributes:(QSHandSide*)handSide;
- (NSString*)fixedSignatureOfAVM:(NSDictionary*)avm;
- (NSString*)fixedSignatureOfChain:(NSArray*)chain;
- (void)setStopWatch:(QXStopWatch*)_stopWatch;
- (NSSet*)rules;
- (NSArray*)rulesForType:(NSString*)type;
- (NSDictionary*)rulesForWordByValue;
- (NSDictionary*)rulesForWordByLemma;
- (float)percentOfEmptyGraphs;

@end
