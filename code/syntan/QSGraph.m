//
//  QSGraph.m
//  Systems-Q
//
//  Created by Petr Homola on 14.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QSGraph.h"
#import "QSEdge.h"

@implementation QSGraph
- (id)init {
	if (self = [super init]) {
		vertices = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)initWithArray:(NSArray*)input {
	if (self = [super init]) {
		//NSLog(@"> %u", [input count]);
		vertices = [[NSMutableArray alloc] init];
		firstNode = [[QSVertex alloc] initWithName: @"1"];
		[vertices addObject: firstNode];
		[firstNode release];
		int i; QSVertex* node, *prev = firstNode;
		for (i = 0; i < [input count]; i++) {
			node = [[QSVertex alloc] initWithName: [[NSNumber numberWithInt: i + 2] description]];
			[vertices addObject: node];
			[node release];
			id labels = [input objectAtIndex: i];
			//if (i == 18) NSLog(@"> %@", labels);
			if ([labels isKindOfClass: [NSDictionary class]]) {
				QSEdge* edge = [QSEdge edgeWithLabel: labels leftNode: prev rightNode: node];
				[prev addRightEdge: edge];
				[node addLeftEdge: edge];
			} else {
				NSEnumerator* enumerator = [labels objectEnumerator];
				id label;
				while (label = [enumerator nextObject]) {
					QSEdge* edge = [QSEdge edgeWithLabel: label leftNode: prev rightNode: node];
					[prev addRightEdge: edge];
					[node addLeftEdge: edge];
				}
			}
			prev = node;
		}
		lastNode = node;
		//NSLog(@"> %@", self);
	}
	return self;
}

+ (id)graphWithArray:(NSArray*)input {
	return [[[QSGraph alloc] initWithArray: input] autorelease];
}

- (id)initWithArrayAsSequence:(NSArray*)input {
	NSMutableArray* edges = [NSMutableArray arrayWithCapacity: [input count]];
	NSEnumerator* enumerator = [input objectEnumerator];
	id element;
	while (element = [enumerator nextObject]) {
		if ([element isKindOfClass: [NSString class]]) {
			NSScanner* scanner = [NSScanner scannerWithString: element];
			NSString* type = @"unresolved";
			
			if ([element isEqual: @"."]) type = @"note";
			else {
				// type - number
				int n;
				BOOL scanned = [scanner scanInt: &n];
				if (scanned == YES) type = @"integer";
				else {
			
					// type - word
					NSString* word;
					BOOL scanned = [scanner scanCharactersFromSet: [NSCharacterSet alphanumericCharacterSet] intoString: &word];
					if (scanned == YES) type = @"word";
				}
			}
			
			[edges addObject:
				[NSDictionary dictionaryWithObjectsAndKeys: type, @"type", element, @"value", nil]
			];
		} /*else {
			NSLog(@"cannot add %@ instance to the graph", [element className]);
		}*/
	}
	return [self initWithArray: edges];
}

+ (id)graphWithArrayAsSequence:(NSArray*)input {
	return [[[QSGraph alloc] initWithArrayAsSequence: input] autorelease];
}

- (id)copyWithZone:(NSZone*)zone {
	QSGraph* graph = [[QSGraph alloc] init];
	NSMutableDictionary* nodes = [NSMutableDictionary dictionaryWithCapacity: 10];
	graph->firstNode = [[QSVertex alloc] initWithName: [firstNode name]];
	[nodes setObject: graph->firstNode forKey: [firstNode name]];
	[graph->vertices addObject: graph->firstNode];
	[graph->firstNode release];
	graph->lastNode = [[QSVertex alloc] initWithName: [lastNode name]];
	[nodes setObject: graph->lastNode forKey: [lastNode name]];
	[graph->vertices addObject: graph->lastNode];
	[graph->lastNode release];
	NSEnumerator* enumerator = [[self allEdges] objectEnumerator];
	QSEdge* edge;
	while (edge = [enumerator nextObject]) {
		QSVertex* leftNode = [nodes objectForKey: [[edge leftNode] name]];
		if (leftNode == nil) {
			leftNode = [[QSVertex alloc] initWithName: [[edge leftNode] name]];
			[nodes setObject: leftNode forKey: [[edge leftNode] name]];
			[graph->vertices addObject: leftNode];
			[leftNode release];
		}
		QSVertex* rightNode = [nodes objectForKey: [[edge rightNode] name]];
		if (rightNode == nil) {
			rightNode = [[QSVertex alloc] initWithName: [[edge rightNode] name]];
			[nodes setObject: rightNode forKey: [[edge rightNode] name]];
			[graph->vertices addObject: rightNode];
			[rightNode release];
		}
		QSEdge* newEdge = [QSEdge edgeWithLabel: [edge label] leftNode: leftNode rightNode: rightNode];
		//if ([edge isUsed]) [newEdge setUsed: YES];
		[leftNode addRightEdge: newEdge];
		[rightNode addLeftEdge: newEdge];
	}
	return graph;
}

- (void)dealloc {
	//NSLog(@"%u %u #%u", [vertices retainCount], [firstNode retainCount], [vertices count]);
	[vertices release];
	[super dealloc];
}

- (NSArray*)chainsWithLength:(unsigned)length level:(unsigned)level type:(NSString*)type unusedOnly:(BOOL)unusedOnly {
	NSMutableSet* processedNodes = [NSMutableSet setWithCapacity: 10];
	NSMutableDictionary* tails = nil; //[NSMutableDictionary dictionaryWithCapacity: 10];
	NSArray* chains = [self chainsWithLength: length level: level type: type unusedOnly: unusedOnly fromNode: firstNode restrictToNode: NO processedNodes: processedNodes tails: tails];
	//return [chains count] > 0 ? chains : nil;
	if ([chains count] > 0) return chains ; else return nil;
}

- (NSArray*)chainsWithLength:(unsigned)length level:(unsigned)level type:(NSString*)type unusedOnly:(BOOL)unusedOnly fromNode:(QSVertex*)initialNode restrictToNode:(BOOL)restr processedNodes:(NSMutableSet*)processedNodes tails: (NSMutableDictionary*)tails {
	NSMutableArray* chains = [NSMutableArray arrayWithCapacity: 5];
	if (!restr) [processedNodes addObject: initialNode];
	NSSet* edges = [initialNode rightEdges];
	NSEnumerator* enumerator = [edges objectEnumerator];
	QSEdge* edge;
	while (edge = [enumerator nextObject]) {
	  if ([edge level] <= level && !([edge isUsed] && unusedOnly)) { // je dana nejvyssi mozna uroven
		NSString* type2 = type == nil ? nil : [[edge label] objectForKey: @"type"];
		if (type != nil && type2 == nil) { NSLog(@"no type in edge label"); exit(1); }
		if (length == 1) { // posledni hrana
			if (type == nil || [type isEqual: type2]) {
				NSMutableArray* chain = [NSMutableArray arrayWithObject: edge];
				[chains addObject: chain];
			}
		}
		QSVertex* rightNode = [edge rightNode];
		if (rightNode != lastNode) { // nejsme na konci
			if (length > 1) { // jeste zbyva podretezec delsi nez jedna hrana
			  if (type == nil || [type isEqual: type2]) {
				// vsechna zakonceni pro danou hranu
				NSArray* rightTails = [self chainsWithLength: length - 1 level: level type: nil unusedOnly: unusedOnly fromNode: rightNode restrictToNode: YES processedNodes: processedNodes tails: tails];
				/*NSArray* rightTails = [tails objectForKey: [rightNode name]];
				if (rightTails == nil) {
					rightTails = [self chainsWithLength: length - 1 level: level fromNode: rightNode restrictToNode: YES processedNodes: processedNodes tails: tails];
					[tails setObject: rightTails forKey: [rightNode name]];
				}*/
				NSEnumerator* enumerator2 = [rightTails objectEnumerator];
				NSArray* tail;
				while (tail = [enumerator2 nextObject]) { // spojeni dane hrany a vsech zakonceni
					NSMutableArray* chain = [NSMutableArray arrayWithObject: edge];
					[chain addObjectsFromArray: tail];
					[chains addObject: chain];
				}
			  }
			}
			if (restr == NO && ![processedNodes member: rightNode]) { // neni-li omezen pocatecni vrchol, rekurze dale vpravo v grafu
				//NSLog(@"-- %d", length);
				NSArray* otherChains = [self chainsWithLength: length level: level type: type unusedOnly: unusedOnly fromNode: rightNode restrictToNode: NO processedNodes: processedNodes tails: tails];
				[chains addObjectsFromArray: otherChains];
			}
		}
	  }
	}
	return chains;
}

- (QSVertex*)firstNode {
	return firstNode;
}

- (QSVertex*)lastNode {
	return lastNode;
}

- (void)setFirstNode:(QSVertex*)node {
	if (node != firstNode) {
		//[firstNode release];
		firstNode = node; // retain];
	}
}

- (NSSet*)traverse {
	return [self traverseFrom: firstNode];
}

- (NSSet*)traverseFrom:(QSVertex*)node {
	if (node == lastNode) return nil;
	NSMutableSet* sequences = [NSMutableSet setWithCapacity: 10];
	NSEnumerator* enumerator = [[node rightEdges] objectEnumerator];
	QSEdge* edge;
	while (edge = [enumerator nextObject]) {
		NSSet* tails = [self traverseFrom: [edge rightNode]];
		if (tails == nil) {
			NSMutableArray* sequence = [NSMutableArray arrayWithObject: [edge label]];
			[sequences addObject: sequence];
		} else {
			NSEnumerator* enumerator2 = [tails objectEnumerator];
			NSArray* tail;
			while (tail = [enumerator2 nextObject]) {
				NSMutableArray* sequence = [NSMutableArray arrayWithObject: [edge label]];
				[sequence addObjectsFromArray: tail];
				[sequences addObject: sequence];
			}
		}
	}
	return sequences;
}

- (NSArray*)dictionaries {
	NSMutableArray* result = [NSMutableArray arrayWithCapacity: 5];
	NSEnumerator* enumerator = [[self allEdges] objectEnumerator];
	QSEdge* edge;
	while (edge = [enumerator nextObject]) {
		[(NSMutableDictionary*) [edge label] setObject: [[edge leftNode] name] forKey: @"left"];
		[(NSMutableDictionary*) [edge label] setObject: [[edge rightNode] name] forKey: @"right"];
		if ([edge label] == nil) NSLog(@"edge label is nil -- %@ %@", [[edge leftNode] name], [[edge rightNode] name]);
		[result addObject: [edge label]];
	}
	return result;
}

- (NSArray*)allEdges {
	NSMutableSet* processedNodes = [NSMutableSet setWithCapacity: 10];
	return [self allEdges: firstNode processedNodes: processedNodes];
}

- (NSArray*)allEdges:(QSVertex*)initialNode processedNodes:(NSMutableSet*)processedNodes {
	NSMutableArray* result = [NSMutableArray arrayWithCapacity: 5];
	[processedNodes addObject: initialNode];
	NSMutableSet* nextNodes = [NSMutableSet setWithCapacity: 5];
	if (initialNode != lastNode) {
		NSEnumerator* enumerator = [[initialNode rightEdges] objectEnumerator];
		QSEdge* edge;
		while (edge = [enumerator nextObject]) {
			if (![edge isDiscarded]) {
				[result addObject: edge];
				QSVertex* node = [edge rightNode];
				if (![processedNodes member: node]) [nextNodes addObject: node];
			} else {
				NSLog(@"oops");
				exit(1);
			}
		}
		enumerator = [nextNodes objectEnumerator];
		QSVertex* node;
		while (node = [enumerator nextObject]) {
			NSArray* followingEdges = [self allEdges: node processedNodes: processedNodes];
			[result addObjectsFromArray: followingEdges];
		}
	}
	return result;
}

- (void)addVertex:(QSVertex*)vertex {
	[vertices addObject: vertex];
}

- (unsigned)numberOfAddedEdges {
	return numberOfAddedEdges;
}

- (void)increaseNumberOfAddedEdgesBy:(unsigned)n {
	numberOfAddedEdges += n;
}

- (NSString*)description { // kontrolni vypis grafu jako sekvence hran (nenavazanych)
	NSMutableString* result = [NSMutableString stringWithString: @"Q graph:\n"];
	NSEnumerator* enumerator = [[self allEdges] objectEnumerator];
	QSEdge* edge;
	while (edge = [enumerator nextObject]) {
		//[result appendFormat: @"-%@- %@ -%@- (%d)\n", [[edge leftNode] name], [[edge label] description], [[edge rightNode] name], [edge isUsed]];
		//[result appendFormat: @"-%@- %@ -%@- (%d-%u/%u)\n", [[edge leftNode] name], [[edge label] description], [[edge rightNode] name], [edge isUsed], [[edge leftNode] usedEdgesLeft], [[edge rightNode] usedEdgesRight]];
		[result appendFormat: @"-%@- %@ -%@- (%d/%u)\n", [[edge leftNode] name], [[edge label] description], [[edge rightNode] name], [edge isUsed], [edge pathScore]];
	}
	return result;
}
@end
