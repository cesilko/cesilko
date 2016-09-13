//
//  QSVertex.h
//  Systems-Q
//
//  Created by Petr Homola on 14.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>

// vrchol grafu

@class QSEdge;

@interface QSVertex : NSObject {
	NSString* name; // label vrcholu
	NSMutableSet* leftEdges; // leve hrany
	NSMutableSet* rightEdges; // prave hrany
	BOOL checked; // zkontrolovano pri cisteni
	BOOL canReachEnd; // z tohoto vrcholu se lze dostat na konec grafu
	unsigned usedEdgesLeft;
	unsigned usedEdgesRight;
}

- (id)initWithName:(NSString*)_name;
+ (id)vertexWithName:(NSString*)_name;
- (NSString*)name;
- (void)addLeftEdge:(QSEdge*)edge;
- (void)addRightEdge:(QSEdge*)edge;
- (NSSet*)leftEdges;
- (NSSet*)rightEdges;
- (BOOL)isChecked;
- (void)setChecked:(BOOL)_checked;
- (BOOL)canReachEnd;
- (void)setCanReachEnd:(BOOL)_canReachEnd;
- (unsigned)usedEdgesLeft;
- (unsigned)usedEdgesRight;
- (void)setUsedEdgesLeft:(unsigned)used;
- (void)setUsedEdgesRight:(unsigned)used;

@end
