//
//  QSCleaner.m
//  Systems-Q
//
//  Created by Petr Homola on 14.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QSCleaner.h"
#import "QSEdge.h"

@implementation QSCleaner

/*- (void)reset:(QSGraph*)graph {
	NSEnumerator* enumerator = [[graph allEdges] objectEnumerator];
	QSEdge* edge;
	while (edge = [enumerator nextObject]) {
		//if (![edge isUsed]) [edge setLevel: 0]; else [edge setLevel: 1000];
		[edge setLevel: 0];
	}
}*/

- (QSGraph*)clean:(QSGraph*)graph {
	[self traceRight: graph fromNode: [graph firstNode] usedLeft: 0];
	[self traceLeft: graph fromNode: [graph lastNode] usedRight: 0];
	unsigned minScore = INT_MAX;
	NSArray* allEdges = [graph allEdges];
	//NSLog(@"%u", [allEdges count]);
	NSEnumerator* enumerator = [allEdges objectEnumerator];
	QSEdge* edge;
	while ((edge = [enumerator nextObject])) {
		unsigned score = [edge pathScore];
		if (score < minScore) minScore = score;
	}
	NSLog(@"min. score: %u", minScore);
	if (minScore > 0) [self setShouldBeEmpty];
	enumerator = [[graph allEdges] objectEnumerator];
	while ((edge = [enumerator nextObject])) {
		if (minScore < [edge pathScore]) {
			[edge setDiscarded: YES];
			[(NSMutableArray*) [[edge rightNode] leftEdges] removeObject: edge];
			[(NSMutableArray*) [[edge leftNode] rightEdges] removeObject: edge];
		}
	}
	return graph;
}

- (void)setShouldBeEmpty {
	shouldBeEmpty = YES;
}

- (BOOL)isShouldBeEmpty {
	return shouldBeEmpty;
}

- (void)traceRight:(QSGraph*)graph fromNode:(QSVertex*)initialNode usedLeft:(unsigned)usedLeft {
	if (usedLeft < [initialNode usedEdgesLeft]) {
		[initialNode setUsedEdgesLeft: usedLeft];
		if (initialNode != [graph lastNode]) {
			NSEnumerator* enumerator = [[initialNode rightEdges] objectEnumerator];
			QSEdge* edge;
			while ((edge = [enumerator nextObject])) {
				unsigned increment = [edge isUsed] ? 1 : 0;
				QSVertex* node = [edge rightNode];
				[self traceRight: graph fromNode: node usedLeft: usedLeft + increment];
			}
		}
	}
}

- (void)traceLeft:(QSGraph*)graph fromNode:(QSVertex*)initialNode usedRight:(unsigned)usedRight {
	if (usedRight < [initialNode usedEdgesRight]) {
		[initialNode setUsedEdgesRight: usedRight];
		if (initialNode != [graph firstNode]) {
			NSEnumerator* enumerator = [[initialNode leftEdges] objectEnumerator];
			QSEdge* edge;
			while ((edge = [enumerator nextObject])) {
				unsigned increment = [edge isUsed] ? 1 : 0;
				QSVertex* node = [edge leftNode];
				[self traceLeft: graph fromNode: node usedRight: usedRight + increment];
			}
		}
	}
}

/*- (QSGraph*)clean:(QSGraph*)graph {
	// "mekke" cisteni, povolujeme stale vice pouzitych hran ve vysledku, az najdeme cestu od pocatku do konce
	QSGraph* copy = [graph copy];
	BOOL wasAtEnd = [self clean: graph fromNode: [graph firstNode] allowedUsedEdges: 0];
	unsigned allowedUsedEdges = 1;
	while (!wasAtEnd) {
		graph = copy;
		copy = [graph copy];
		NSLog(@"graph cleaned completely - trying with %u used edge(s)", allowedUsedEdges);
		wasAtEnd = [self clean: graph fromNode: [graph firstNode] allowedUsedEdges: allowedUsedEdges];
		allowedUsedEdges++;
	}
	[copy release];
	/#/ //pokud chceme cistit "prisne", tj. zustanou pouze nepouzite hrany
	BOOL wasAtEnd = [self clean: graph fromNode: [graph firstNode] allowedUsedEdges: 0];
	if (!wasAtEnd) {
		[graph setFirstNode: [graph lastNode]]; // v grafu nic nezustalo
	} /##/
	//NSLog(@"cleaned: %d", wasAtEnd);
	return graph;
}

- (BOOL)clean:(QSGraph*)graph fromNode:(QSVertex*)initialNode allowedUsedEdges:(unsigned)allowedUsedEdges {
	//NSLog(@"cleaning from %@", [initialNode name]);
	QSVertex* node = initialNode;
	if (node == [graph lastNode]) { return YES; } // konec grafu
	[node setChecked: YES];
	NSMutableArray* edges = (NSMutableArray*) [node rightEdges];
	NSEnumerator* enumerator = [edges objectEnumerator];
	QSEdge* edge; BOOL wasAtEnd = NO;
	while (edge = [enumerator nextObject]) {
		//NSLog(@"%@ %@", [[edge rightNode] name], [[edge label] description]);
		BOOL toBeRemoved = NO;
		if (allowedUsedEdges > 0 && [edge isUsed]) {
			if (![[edge rightNode] isChecked]) {
				if(![self clean: graph fromNode: [edge rightNode] allowedUsedEdges: allowedUsedEdges - 1]) toBeRemoved = YES; // nelze se dostat na konec => odstranit hranu
				else { wasAtEnd = YES; } // pres nepouzitou hranu se lze dostat na konec => zustane
			} else {
				if ([[edge rightNode] canReachEnd]) wasAtEnd = YES;
				else toBeRemoved = YES;
			}
			//NSLog(@"ok %u %d", allowedUsedEdges, toBeRemoved);
		} else {
			toBeRemoved = [edge isUsed]; // pouzite hrany budou odstraneny
			if (!toBeRemoved) {
				if (![[edge rightNode] isChecked]) {
					if(![self clean: graph fromNode: [edge rightNode] allowedUsedEdges: allowedUsedEdges]) toBeRemoved = YES; // nelze se dostat na konec => odstranit hranu
					else { wasAtEnd = YES; } // pres nepouzitou hranu se lze dostat na konec => zustane
				} else {
					if ([[edge rightNode] canReachEnd]) wasAtEnd = YES;
					else toBeRemoved = YES;
				}
			}
		}
		if (toBeRemoved) {
			[edge setDiscarded: YES];
			//NSLog(@"discarding %@ %@", [[edge leftNode] name], [[edge rightNode] name]);
			//[edges removeObject: edge];
			[(NSMutableArray*) [[edge rightNode] leftEdges] removeObject: edge];
			[(NSMutableSet*) [node rightEdges] removeObject: edge];
		}
	}
	//NSLog(@"cleaned from %@ - %d", [initialNode name], wasAtEnd);
	[initialNode setCanReachEnd: wasAtEnd];
	return wasAtEnd;
}*/

@end
