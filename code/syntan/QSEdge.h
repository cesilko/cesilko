//
//  QSEdge.h
//  Systems-Q
//
//  Created by Petr Homola on 14.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "QSVertex.h"
#import "QSValue.h"

// hrana grafu ohodnocena sestavou rysu

@interface QSEdge : NSObject {
	QSVertex* leftNode; // levy vrchol
	QSVertex* rightNode; // pravy vrchol
	NSDictionary* label; // ohodnoceni
	unsigned level; // uroven hrany (kdy byla vytvorena), inicialni graf ma vsechny hrany s urovni 0
	BOOL used; // byla hrana pouzita pri aplikaci nejakeho pravidla?
	BOOL reachable; // lezi na nejake ceste od pocatecniho vrcholu do koncoveho
	NSNumber* head; // hlava pro unifikaci z LHS
	BOOL discarded; // hrana je smazana po cistici fazi
}

- (id)initWithLabel:(NSDictionary*)_label leftNode:(QSVertex*)_leftNode rightNode:(QSVertex*)_rightNode;
+ (id)edgeWithLabel:(NSDictionary*)_label leftNode:(QSVertex*)_leftNode rightNode:(QSVertex*)_rightNode;
+ (id)edgeWithLabel:(NSDictionary*)_label;
- (NSDictionary*)label; // ohodnoceni hrany
- (QSVertex*)leftNode; // levy vrchol
- (QSVertex*)rightNode; // pravy vrchol
- (void)setLeftNode:(QSVertex*)node; // nastavi levy vrchol
- (void)setRightNode:(QSVertex*)node; // nastavi pravy vrchol
- (BOOL)isUsed; // pouzita hrana?
- (void)setUsed:(BOOL)_used; // nastavi pouziti hrany
- (unsigned)level; // uroven hrany
- (void)setLevel:(unsigned)_level; // nastavi uroven hrany
- (BOOL)isReachable;
- (void)setReachanle:(BOOL)_reachable;
- (NSNumber*)head;
- (void)setHead:(NSNumber*)_head;
- (BOOL)isDiscarded;
- (void)setDiscarded:(BOOL)_discarded;
- (unsigned)pathScore;

@end
