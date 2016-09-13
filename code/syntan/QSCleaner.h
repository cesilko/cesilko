//
//  QSCleaner.h
//  Systems-Q
//
//  Created by Petr Homola on 14.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "QSGraph.h"

// cisteni grafu

@interface QSCleaner : NSObject {
	BOOL shouldBeEmpty;
}

- (QSGraph*)clean:(QSGraph*)graph; // vycisti graf
- (void)traceRight:(QSGraph*)graph fromNode:(QSVertex*)initialNode usedLeft:(unsigned)usedLeft;
- (void)traceLeft:(QSGraph*)graph fromNode:(QSVertex*)initialNode usedRight:(unsigned)usedRight;
//- (BOOL)clean:(QSGraph*)graph fromNode:(QSVertex*)initialNode allowedUsedEdges:(unsigned)allowedUsedEdges; // dtto od daneho vrcholu, vrati YES pokud dosahl konce grafu
//- (void)reset:(QSGraph*)graph; // resetuje graf
- (void)setShouldBeEmpty;
- (BOOL)isShouldBeEmpty;

@end
