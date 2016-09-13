//
//  QSRule.m
//  Systems-Q
//
//  Created by Petr Homola on 14.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QSRule.h"
#import "QSEmptyCondition.h"
#import "QSEdge.h"
#import "QX_Unification.h"

@implementation QSRule
- (id)initWithLeftHandSide:(QSHandSide*)lhs rightHandSide:(QSHandSide*)rhs id:(int)_id {
	if (self = [super init]) {
		leftHandSide = [lhs retain];
		rightHandSide = [rhs retain];
		condition = [[QSEmptyCondition alloc] init]; // podminky nepouzivame, proto je zde prazdna podminka
		signature = [[NSMutableArray alloc] init];
		NSEnumerator* enumerator = [[lhs edges] objectEnumerator];
		QSEdge* edge;
		while (edge = [enumerator nextObject]) {
			NSDictionary* avm = [edge label];
			NSSet* singleSignature = [avm signature];
			[signature addObject: singleSignature];
		}
		//NSLog(@"signature: %@", signature);
		uid = _id;
	}
	return self;
}

+ (id)ruleWithLeftHandSide:(QSHandSide*)lhs rightHandSide:(QSHandSide*)rhs id:(int)_id {
	return [[[QSRule alloc] initWithLeftHandSide: lhs rightHandSide: rhs id: _id] autorelease];
}

- (QSHandSide*)leftHandSide {
	return leftHandSide;
}

- (QSHandSide*)rightHandSide {
	return rightHandSide;
}

- (int)id {
	return uid;
}

- (NSArray*)signature {
	return signature;
}

- (void)dealloc {
	[leftHandSide release];
	[rightHandSide release];
	[condition release];
	[signature release];
	[super dealloc];
}
@end
