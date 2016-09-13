//
//  QSVertex.m
//  Systems-Q
//
//  Created by Petr Homola on 14.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QSVertex.h"
#import "QSEdge.h"

static unsigned numberOfInstances = 0;

@implementation QSVertex
- (id)initWithName:(NSString*)_name {
	if (self = [super init]) {
		numberOfInstances++;
		name = [_name retain];
		leftEdges = [[NSMutableSet alloc] initWithCapacity: 5];
		rightEdges = [[NSMutableSet alloc] initWithCapacity: 5];
		usedEdgesLeft = usedEdgesRight = INT_MAX;
	}
	return self;
}

- (void)dealloc {
	numberOfInstances--;
	//NSLog(@"##### %u", numberOfInstances);
	[name release];
	[leftEdges release];
	[rightEdges release];
	[super dealloc];
}

+ (id)vertexWithName:(NSString*)_name {
	return [[[QSVertex alloc] initWithName: _name] autorelease];
}

- (NSString*)name {
	return name;
}

- (BOOL)canReachEnd {
	return canReachEnd;
}

- (void)setCanReachEnd:(BOOL)_canReachEnd {
	canReachEnd = _canReachEnd;
}

- (void)addLeftEdge:(QSEdge*)edge {
	[leftEdges addObject: edge];
}

- (void)addRightEdge:(QSEdge*)edge {
	[rightEdges addObject: edge];
}

- (NSSet*)rightEdges {
	return rightEdges;
}

- (NSSet*)leftEdges {
	return leftEdges;
}

- (BOOL)isChecked {
	return checked;
}

- (void)setChecked:(BOOL)_checked {
	checked = _checked;
}

- (unsigned)usedEdgesLeft {
	return usedEdgesLeft;
}

- (unsigned)usedEdgesRight {
	return usedEdgesRight;
}

- (void)setUsedEdgesLeft:(unsigned)used {
	usedEdgesLeft = used;
}

- (void)setUsedEdgesRight:(unsigned)used {
	usedEdgesRight = used;
}
@end
