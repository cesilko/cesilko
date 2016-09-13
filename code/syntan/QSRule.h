//
//  QSRule.h
//  Systems-Q
//
//  Created by Petr Homola on 14.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "QSHandSide.h"
#import "QSCondition.h"

// pravidlo gramatiky

@interface QSRule : NSObject {
	QSHandSide* leftHandSide; // leva strana (k unifikaci)
	QSHandSide* rightHandSide; // prava strana (k pridani ke grafu)
	QSCondition* condition; // podminka (momentalne se nepouziva, resi se unifikaci)
	int uid; // id pravidla
	NSMutableArray* signature;
}
- (id)initWithLeftHandSide:(QSHandSide*)lhs rightHandSide:(QSHandSide*)rhs id:(int)_id;
+ (id)ruleWithLeftHandSide:(QSHandSide*)lhs rightHandSide:(QSHandSide*)rhs id:(int)_id;
- (QSHandSide*)leftHandSide;
- (QSHandSide*)rightHandSide;
- (int)id;
- (NSArray*)signature;
@end
