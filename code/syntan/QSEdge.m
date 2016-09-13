//
//  QSEdge.m
//  Systems-Q
//
//  Created by Petr Homola on 14.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QSEdge.h"

static unsigned numberOfInstances = 0;

@implementation QSEdge
- (id)initWithLabel:(NSDictionary*)_label leftNode:(QSVertex*)_leftNode rightNode:(QSVertex*)_rightNode {
	if (self = [super init]) {
		label = [_label retain];
		leftNode = _leftNode; // retain];
		rightNode = _rightNode; // retain];
		numberOfInstances++;
	}
	return self;
}

- (void)dealloc {
	numberOfInstances--;
	//NSLog(@"##### %u", numberOfInstances);
	[label release];
	//[leftNode release];
	//[rightNode release];
	[super dealloc];
}

+ (id)edgeWithLabel:(NSDictionary*)_label leftNode:(QSVertex*)_leftNode rightNode:(QSVertex*)_rightNode {
	return [[[QSEdge alloc] initWithLabel: _label leftNode: _leftNode rightNode: _rightNode] autorelease];
}

+ (id)edgeWithLabel:(NSDictionary*)_label {
	return [[[QSEdge alloc] initWithLabel: _label leftNode: nil rightNode: nil] autorelease];
}

- (void)setLeftNode:(QSVertex*)node {
	if (leftNode != node) {
		//[leftNode release];
		leftNode = node; // retain];
	}
}

- (void)setRightNode:(QSVertex*)node {
	if (node != rightNode) {
		//[rightNode release];
		rightNode = node; // retain];
	}
}

- (NSDictionary*)label {
	return label;
}

- (QSVertex*)leftNode {
	return leftNode;
}

- (QSVertex*)rightNode {
	return rightNode;
}

- (BOOL)isUsed {
	return used;
}

- (void)setUsed:(BOOL)_used {
	used = _used;
}

- (unsigned)level {
	return level;
}

- (void)setLevel:(unsigned)_level {
	level = _level;
}

- (BOOL)isReachable {
	return reachable;
}

- (void)setReachanle:(BOOL)_reachable {
	reachable = _reachable;
}

- (NSString*)description {
	NSMutableString* result = [NSMutableString stringWithString: @"-"];
	[result appendString: [leftNode name]];
	[result appendString: @"- "];
	[result appendString: [label description]];
	[result appendString: @" -"];
	[result appendString: [rightNode name]];
	[result appendString: @"-"];
	return result;
}

- (NSNumber*)head {
	return head;
}

- (void)setHead:(NSNumber*)_head {
	head = _head;
}

- (BOOL)isDiscarded {
	return discarded;
}

- (void)setDiscarded:(BOOL)_discarded {
	discarded = _discarded;
}

- (unsigned)pathScore {
	unsigned usedLeft = [[self leftNode] usedEdgesLeft];
	unsigned usedRight = [[self rightNode] usedEdgesRight];
	return usedLeft + usedRight + ([self isUsed] ? 1 : 0);
}
@end
