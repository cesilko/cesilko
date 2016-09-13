//
//  QSHandSite.m
//  Systems-Q
//
//  Created by Petr Homola on 14.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QSHandSide.h"
#import "QX_Unification.h"
#import "QSEdge.h"

@implementation QSHandSide

- (id)initWithEdges:(NSArray*)_edges {
	if (self = [super init]) {
		edges = [_edges retain];
	}
	return self;
}

+ (id)handSideWithEdges:(NSArray*)_edges {
	return [[[QSHandSide alloc] initWithEdges: _edges] autorelease];
}

- (id)initWithArray:(NSArray*)list {
	NSMutableArray* _edges = [NSMutableArray arrayWithCapacity: [list count]];
	NSEnumerator* enumerator = [list objectEnumerator];
	id fs; id ref = nil;
	while (fs = [enumerator nextObject]) {
		if ([fs isKindOfClass: [NSString class]]) {
			ref = [NSNumber numberWithInt: atoi([[fs substringFromIndex: 1] UTF8String])];
		} else {
			NSDictionary* dict = [NSDictionary dictionaryWithArray: fs];
			//NSLog(@"%@", dict); exit(0);
			QSEdge* edge = [QSEdge edgeWithLabel: dict];
			if (ref != nil) [edge setHead: ref];
			[_edges addObject: edge];
			ref = nil;
		}
	}
	return [self initWithEdges: _edges];
}

+ (id)handSideWithArray:(NSArray*)list {
	return [[[QSHandSide alloc] initWithArray: list] autorelease];
}

- (unsigned)length {
	return [edges count];
}

- (NSArray*)edges {
	return edges;
}

- (void)dealloc {
	[edges release];
	[super dealloc];
}

@end
