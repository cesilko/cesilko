//
//  QSHandSite.h
//  Systems-Q
//
//  Created by Petr Homola on 14.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>

// cast pravidla

@interface QSHandSide : NSObject {
	NSArray* edges; // hrany podretezce
}

- (id)initWithEdges:(NSArray*)_edges;
+ (id)handSideWithEdges:(NSArray*)_edges;
- (id)initWithArray:(NSArray*)list;
+ (id)handSideWithArray:(NSArray*)list;
- (unsigned)length; // delka podretezce
- (NSArray*)edges;

@end
