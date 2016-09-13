//
//  QSGrammar.m
//  Systems-Q
//
//  Created by Petr Homola on 30.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QSGrammar.h"
#import "QXVariable.h"
#import "QSEdge.h"
#import "QX_Unification.h"
#import "QSCleaner.h"

@implementation QSGrammar
- (id)init {
	if (self = [super init]) {
		allRules = [[NSMutableSet alloc] initWithCapacity: 100];
		mapOfRules = [[NSMutableDictionary alloc] init];
		mapOfRulesByFixedSignature = [[NSMutableDictionary alloc] init];
		volatileAttributes = [[NSMutableDictionary alloc] init];
		fixedAttributes = [[NSMutableDictionary alloc] init];
		allAttributes = [[NSMutableDictionary alloc] init];
		//oddRules = [[NSMutableSet alloc] initWithCapacity: 100];
		//evenRules = [[NSMutableSet alloc] initWithCapacity: 100];
		rulesByFirstType = [[NSMutableDictionary alloc] init];
		rulesForWordByValue = [[NSMutableDictionary alloc] init];
		rulesForWordByLemma = [[NSMutableDictionary alloc] init];
	}
	return self;
}

+ (id)grammar {
	return [[[QSGrammar alloc] init] autorelease];
}

- (id)initWithArray:(NSArray*)input maxSpan:(unsigned)_maxSpan {
	self = [self init];
	maxSpan = _maxSpan;
	NSEnumerator* enumerator = [input objectEnumerator];
	NSArray* pair; int n = 0;
	while (pair = [enumerator nextObject]) {
		id firstElement = [pair objectAtIndex: 0];
		if (![firstElement isEqual: @"#"]) {
			unsigned span = [firstElement count];
			if (span > maxSpan) maxSpan = span;
			QSHandSide* lhs = [QSHandSide handSideWithArray: firstElement];
			QSHandSide* rhs = [QSHandSide handSideWithArray: [pair objectAtIndex: 1]];
			QSRule* rule = [QSRule ruleWithLeftHandSide: lhs rightHandSide: rhs id: ++n];
			[self addRule: rule];
			[self updateVolatileAttributes: lhs];
			// caching rules by type of the first LHS edge
			QSEdge* firstEdge = [[lhs edges] objectAtIndex: 0];
			NSDictionary* label = [firstEdge label];
			id value = [label objectForKey: @"type"];
			if (value == nil) { NSLog(@"no type in rule: %@", label); exit(1); }
			//else NSLog(@"rule cached by type");
			if (value == nil) value = [NSNull null];
			NSMutableArray* rules = [rulesByFirstType objectForKey: value];
			if (rules == nil) {
				rules = [[NSMutableArray alloc] init];
				[rulesByFirstType setObject: rules forKey: value];
				[rules release];
			}
			[rules addObject: rule];
		}
	}
	
	enumerator = [allRules objectEnumerator];
	QSRule* rule;
	while (rule = [enumerator nextObject]) {
		NSEnumerator* enumerator2 = [[[rule leftHandSide] edges] objectEnumerator];
		QSEdge* edge;
		while (edge = [enumerator2 nextObject]) {
			NSDictionary* avm = [edge label];
			NSString* type = [avm objectForKey: @"type"];
			NSMutableSet* set = [volatileAttributes objectForKey: type];
			NSEnumerator* enumerator3 = [[allAttributes objectForKey: type] objectEnumerator];
			NSString* key;
			while (key = [enumerator3 nextObject]) {
				if ([avm objectForKey: key] == nil) [set addObject: key];
			}
		}
	}
	
	enumerator = [[allAttributes allKeys] objectEnumerator];
	NSString* type;
	while (type = [enumerator nextObject]) {
		NSSet* all = [allAttributes objectForKey: type];
		NSSet* volatil = [volatileAttributes objectForKey: type];
		NSMutableArray* fixed = [NSMutableArray array];
		NSEnumerator* enumerator2 = [all objectEnumerator];
		NSString* key;
		while (key = [enumerator2 nextObject]) {
			if (![volatil member: key]) [fixed addObject: key];
		}
		[fixed sortUsingSelector: @selector(compare:)];
		[fixedAttributes setObject: fixed forKey: type];
		//NSLog(@"%@ %@", type, fixed);
	}
	
	enumerator = [allRules objectEnumerator];
	while (rule = [enumerator nextObject]) {
		NSString* signature = [self fixedSignatureOfChain: [[rule leftHandSide] edges]];
		//NSLog(@"%@", signature);
		NSMutableSet* set = [mapOfRulesByFixedSignature objectForKey: signature];
		if (set == nil) {
			set = [NSMutableSet set];
			[mapOfRulesByFixedSignature setObject: set forKey: signature];
		}
		[set addObject: rule];
	}
	return self;
}

+ (id)grammarWithArray:(NSArray*)input maxSpan:(unsigned)_maxSpan {
	return [[[QSGrammar alloc] initWithArray: input maxSpan: _maxSpan] autorelease];
}

- (void)setDeterministic:(BOOL)d {
	deterministic = d;
}

- (void)updateVolatileAttributes:(QSHandSide*)handSide {
	NSEnumerator* enumerator = [[handSide edges] objectEnumerator];
	QSEdge* edge;
	while (edge = [enumerator nextObject]) {
		NSDictionary* avm = [edge label];
		NSString* type = [avm objectForKey: @"type"];
		NSMutableSet* set1 = [volatileAttributes objectForKey: type];
		if (set1 == nil) {
			set1 = [NSMutableSet set];
			[volatileAttributes setObject: set1 forKey: type];
		}
		NSMutableSet* set2 = [allAttributes objectForKey: type];
		if (set2 == nil) {
			set2 = [NSMutableSet set];
			[allAttributes setObject: set2 forKey: type];
		}
		NSEnumerator* enumerator2 = [[avm allKeys] objectEnumerator];
		NSString* key;
		while (key = [enumerator2 nextObject]) {
			[set2 addObject: key];
			id value = [avm objectForKey: key];
			if ([value isKindOfClass: [QXVariable class]]) {
				[set1 addObject: key];
				//NSLog(@"var: %@ %@ %@ %@", type, key, set1, set2);
			}
		}
	}
}

- (NSString*)fixedSignatureOfAVM:(NSDictionary*)avm {
	NSMutableArray* signature = [NSMutableArray array];
	NSString* type = [avm objectForKey: @"type"];
	NSEnumerator* enumerator = [[fixedAttributes objectForKey: type] objectEnumerator];
	NSString* key;
	while (key = [enumerator nextObject]) {
		id value = [avm objectForKey: key];
		/*if (value == nil) {
			value = @"#???#";
			//NSLog(@"!!! %@ %@ %@", type, [fixedAttributes objectForKey: type], avm);
		}*/
		[signature addObject: value];
	}
	return [signature componentsJoinedByString: @":"];
}

- (NSString*)fixedSignatureOfChain:(NSArray*)chain {
	NSMutableArray* signature = [NSMutableArray array];
	NSEnumerator* enumerator = [chain objectEnumerator];
	QSEdge* edge;
	while (edge = [enumerator nextObject]) {
		[signature addObject: [self fixedSignatureOfAVM: [edge label]]];
	}
	return [signature componentsJoinedByString: @"+"];
}

- (QSGraph*)applyTo:(QSGraph*)graph {
	if (stopWatch) [stopWatch start: @"parsing"];
	int nodeIndex = 100000;
	[self applyTo: graph level: 0 nodeIndex: &nodeIndex];
	if (stopWatch) [stopWatch stop: @"parsing"];
	QSCleaner* cleaner = [[QSCleaner alloc] init];
	if (stopWatch) [stopWatch start: @"cleaning"];
	QSGraph* result = [cleaner clean: graph];
	if (stopWatch) [stopWatch stop: @"cleaning"];
	//[cleaner reset: graph];
	noOfGraphs++;
	if ([cleaner isShouldBeEmpty]) noOfEmptyGraphs++;
	[cleaner release];
	return result;
}

- (void)applyTo:(QSGraph*)graph level:(unsigned)level nodeIndex:(int*)nodeIndex {
	//NSLog(@"level: %u %u", level, [graph numberOfAddedEdges]);
	BOOL success1; //, success2;
	[self applyTo: graph level: level nodeIndex: nodeIndex rules: allRules succeeded: &success1];
	//[self applyTo: graph level: level nodeIndex: &nodeIndex rules: oddRules succeeded: &success1];
	//[self applyTo: graph level: level nodeIndex: &nodeIndex rules: evenRules succeeded: &success2];
	if ((success1 /*|| success2*/) /*&& [graph numberOfAddedEdges] < 800*/) {
		NSLog(@"level succ. %u %d", level, *nodeIndex);
		[self applyTo: graph level: level + 1 nodeIndex: nodeIndex];
	}
}

- (BOOL*)applyInThreadTo:(QSGraph*)graph level:(unsigned)level nodeIndex:(int*)nodeIndex rules:(NSSet*)rules succeeded:(BOOL*)success {
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity: 5];
	[params setObject: graph forKey: @"graph"];
	[params setObject: [NSNumber numberWithUnsignedInt: level] forKey: @"level"];
	[params setObject: [NSValue valueWithPointer: nodeIndex] forKey: @"nodeIndex"];
	[params setObject: rules forKey: @"rules"];
	[params setObject: [NSValue valueWithPointer: success] forKey: @"succeeded"];
	BOOL* finished = malloc(sizeof(BOOL)); *finished = NO;
	[params setObject: [NSValue valueWithPointer: finished] forKey: @"finished"];
	[NSThread detachNewThreadSelector: @selector(applyWith:) toTarget: self withObject: params];
	return finished;
}

- (void)applyWith:(NSDictionary*)params {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	QSGraph* graph = [params objectForKey: @"graph"];
	unsigned level = [[params objectForKey: @"level"] unsignedIntValue];
	int* nodeIndex = [[params objectForKey: @"nodeIndex"] pointerValue];
	NSSet* rules = [params objectForKey: @"rules"];
	BOOL* success = [[params objectForKey: @"succeeded"] pointerValue];
	BOOL* finished = [[params objectForKey: @"finished"] pointerValue];
	[self applyTo: graph level: level nodeIndex: nodeIndex rules: rules succeeded: success];
	*finished = YES;
	[pool release];
}

- (BOOL)signature:(NSArray*)signature conformsToRuleSignature:(NSArray*)ruleSignature {
	NSEnumerator* enumerator = [signature objectEnumerator];
	NSEnumerator* enumerator2 = [ruleSignature objectEnumerator];
	NSSet *sig1, *sig2;
	while (sig1 = [enumerator nextObject]) {
		sig2 = [enumerator2 nextObject];
		if (![sig2 isSubsetOfSet: sig1]) {
			//NSLog(@"- %@ %@", sig1, sig2);
			return NO;
		}
	}
	return YES;
}

- (void)increaseRulesTriedToApply:(unsigned)count {
	rulesTriedToApply += count;
	countTriedToApply++;
}

- (void)applyTo:(QSGraph*)graph level:(unsigned)level nodeIndex:(int*)nodeIndex rules:(NSSet*)_rules succeeded:(BOOL*)success {
	BOOL extended = NO;
	unsigned span;
	for (span = 1; span <= maxSpan; span++) {
		//NSLog(@"span: %u", span);
		NSArray* chains = [graph chainsWithLength: span level: level type: nil unusedOnly: deterministic];
		//if ([chains count] == 0) break;
		//NSLog(@"ok: %u", [chains count]);
		NSEnumerator* chainsEnumerator = [chains objectEnumerator];
		NSArray* chain; BOOL ruleApplied = NO; //unsigned chainNo = 0;
		while (chain = [chainsEnumerator nextObject]) { // mozne podretezce grafu k unifikaci
			//NSLog(@"chain: %u/%u", ++chainNo, [chains count]);
			NSEnumerator* chainEnumerator = [chain objectEnumerator];
			QSEdge* edge1; BOOL hasEdgeWithLevel = NO;
			//NSMutableArray* signature = [NSMutableArray array];
			while (edge1 = [chainEnumerator nextObject]) { // kontrola urovne, aspon pro jednu hranu musi byt level
				if ([edge1 level] == level) hasEdgeWithLevel = YES;
				//[signature addObject: [[edge1 label] signature]];
			}
			if (!hasEdgeWithLevel) continue;
			if (deterministic == YES) { // je-li parsing deterministicky, uvazujeme jen nepouzite hrany
				chainEnumerator = [chain objectEnumerator];
				while (edge1 = [chainEnumerator nextObject]) {
					if ([edge1 isUsed]) {
						//NSLog(@"########## used edge -- ignoring chain");
						continue;
					}
				}
			} //else NSLog(@"nondet");
			/*NSMutableSet* rules = [NSMutableSet set];
			NSEnumerator* enumerator = [[mapOfRules allKeys] objectEnumerator];
			NSArray* ruleSignature; //int i = 0;
			while (ruleSignature = [enumerator nextObject]) {
				//NSLog(@"%d %u", i++, [[mapOfRules objectForKey: ruleSignature] count]);
				if ([self signature: signature conformsToRuleSignature: ruleSignature]) {
					[rules addObjectsFromArray: [[mapOfRules objectForKey: ruleSignature] allObjects]];
				} //else NSLog(@"refused");
			}*/
			NSSet* rules = nil;
			/*if ([chain count] == 1
				&& [[[(QSEdge*) [chain objectAtIndex: 0] label] objectForKey: @"type"] isEqual: @"word"]) {
				id value = [[(QSEdge*) [chain objectAtIndex: 0] label] objectForKey: @"value"];
				if (value != nil) rules = [rulesForWordByValue objectForKey: value];
				id lemma = [[(QSEdge*) [chain objectAtIndex: 0] label] objectForKey: @"lemma"];
				if (lemma != nil) rules = [rulesForWordByLemma objectForKey: lemma];
			} else*/ {
				NSString* signature = [self fixedSignatureOfChain: chain];
				rules = [mapOfRulesByFixedSignature objectForKey: signature];
				//if (rules != nil) NSLog(@"rules for %@: %u", signature, [rules count]);
			}
			if (rules == nil) {
				continue;
			} //else NSLog(@"%@ %u", signature, [rules count]);
			/*/ NSSet* rules = _rules; /**/
			//NSLog(@"%u", [rules count]);
			[self increaseRulesTriedToApply: [rules count]];
			NSEnumerator* rulesEnumerator = [rules objectEnumerator];
			QSRule* rule; //unsigned ruleNo = 0;
			while (rule = [rulesEnumerator nextObject]) { // zkusime aplikovat jednotliva pravidla
				//NSLog(@"rule: %u / %d", ++ruleNo, [rule id]);
				if ([[rule leftHandSide] length] != [chain count]) continue;
				[QXVariable clear]; // vsechny promenne jsou zpocatku volne
				chainEnumerator = [chain objectEnumerator];
				NSEnumerator* lhsEnumerator = [[[rule leftHandSide] edges] objectEnumerator];
				QSEdge* edge2; BOOL succeeded = YES;
				//NSLog(@"-- %d %d", [[[rule leftHandSide] edges] count], [chain count]);
				int pos = 1;
				while (edge1 = [chainEnumerator nextObject]) { // pokus o unifikaci vsech hran
					edge2 = [lhsEnumerator nextObject];
					/*NSString* type1 = [[edge1 label] objectForKey: @"type"];
					//NSString* type2 = [[edge2 label] objectForKey: @"type"];
					if ([type1 isEqual: @"word"]) {
						NSString* value1 = [[edge1 label] objectForKey: @"value"];
						NSString* value2 = [[edge2 label] objectForKey: @"value"];
						if (value1 != nil && value2 != nil && ![value1 isEqual: value2]) {
							succeeded = NO;
							break;
						}
						NSString* lemma1 = [[edge1 label] objectForKey: @"lemma"];
						NSString* lemma2 = [[edge2 label] objectForKey: @"lemma"];
						if (lemma1 != nil && lemma2 != nil && ![lemma1 isEqual: lemma2]) {
							succeeded = NO;
							break;
						}
					}*/
					//fprintf(stderr, "ok1: %s %s\n", [[[edge1 label] safeDescription] UTF8String], [[[edge2 label] safeDescription] UTF8String]);
					NSDictionary* unifResult = [[edge1 label] unifyWith: [edge2 label]];
					//fprintf(stderr, "ok2: %s\n", unifResult != nil ? "OK" : "oops");
					if (unifResult == nil) {
						succeeded = NO; // nelze unifikovat
						//NSLog(@"unif. failed %@ %@ %@ %@", [[edge1 leftNode] name], [[edge1 rightNode] name], [[edge1 label] description], [[edge2 label] description]);
						break;
					} else {
						// vysledek unifikace dame do promenne $N, aby bylo mozne na RHS vytvorit vnorenou FS
						QXVariable* var = [QXVariable variableWithName: [[NSNumber numberWithInt: pos++] description]];
						[var setValue: unifResult];
						//NSLog(@"unif. ok %@ %@ %@ %@", [[edge1 leftNode] name], [[edge1 rightNode] name], [[edge1 label] description], [[edge2 label] description]);
					}
				}
				if (succeeded) { // unifikace se povedla, rozsirime graf
					NSMutableArray* newChain = [NSMutableArray arrayWithCapacity: [[rule rightHandSide] length]];
					NSEnumerator* enumerator = [[[rule rightHandSide] edges] objectEnumerator];
					QSEdge* edge;
					while (edge = [enumerator nextObject]) { // na zaklade pravidla vytvorime novy podretezec
						// pripadne unifikace se strukturou hlavy
						NSNumber* headRef = [edge head];
						NSDictionary* head = headRef != nil ? [[QXVariable variableWithName: [headRef description]] getValue] : [NSDictionary dictionaryWithObjectsAndKeys: nil];
						NSDictionary* dict = [[edge label] unifyWith: head];
						if (dict == nil) { // the variable value cannot be unified
							succeeded = NO;
							break;
						}
						QSEdge* newEdge = [QSEdge edgeWithLabel: dict];
						[newEdge setLevel: level + 1];
						[newChain addObject: newEdge];
					}
					if (succeeded) {
						[graph increaseNumberOfAddedEdgesBy: [[[rule rightHandSide] edges] count]];
						//NSLog(@"# %u %u", [chain count], [newChain count]);
						enumerator = [chain objectEnumerator];
						QSVertex *firstNode = nil, *lastNode;
						while (edge = [enumerator nextObject]) { // oznaceni starych hran jako pouzite
							[edge setUsed: YES];
							if (firstNode == nil) firstNode = [edge leftNode];
							lastNode = [edge rightNode];
						}
						enumerator = [newChain objectEnumerator];
						QSEdge *prev = nil, *firstEdge = nil, *lastEdge;
						while (edge = [enumerator nextObject]) { // vzajemne propojeni novy hran
							//NSLog(@"# %@", [edge label]);
							if (firstEdge == nil) firstEdge = edge;
							lastEdge = edge;
							if (prev != nil) {
								QSVertex* vertex = [[QSVertex alloc] initWithName: [[NSNumber numberWithInt: (*nodeIndex)++] description]];
								//NSLog(@"# %d", *nodeIndex);
								[graph addVertex: vertex];
								[vertex release];
								[prev setRightNode: vertex];
								[edge setLeftNode: vertex];
								[vertex addLeftEdge: prev];
								[vertex addRightEdge: edge];
							}
							prev = edge;
						}
						// napojeni noveho podretezce do grafu
						[firstEdge setLeftNode: firstNode];
						[lastEdge setRightNode: lastNode];
						[firstNode addRightEdge: firstEdge];
						[lastNode addLeftEdge: lastEdge];
						//NSLog(@"%@ %@", [firstNode name], [lastNode name]);
						extended = ruleApplied = YES;
						NSLog(@"succ. rule appl. %@-%@ (level %d, rule %d)", [firstNode name], [lastNode name], level, [rule id]);
						//if (deterministic == YES) break; // je-li parsing deterministicky, ignorujeme zbytek
					}
				}
			}
		}
	}
	//if ([graph numberOfAddedEdges] > 20) NSLog(@"***** cut *****");
	*success = extended; // && [graph numberOfAddedEdges] <= 20;
	//NSLog(@"OK");
}

- (void)deprecated_applyTo:(QSGraph*)graph level:(unsigned)level nodeIndex:(int*)nodeIndex rules:(NSSet*)rules succeeded:(BOOL*)success {
	BOOL extended = NO;
	NSMutableDictionary* cachedChains = [NSMutableDictionary dictionaryWithCapacity: 100];
	NSEnumerator* rulesEnumerator = [rules objectEnumerator];
	QSRule* rule;
	while (rule = [rulesEnumerator nextObject]) { // zkusime aplikovat jednotliva pravidla
		QSHandSide* lhs = [rule leftHandSide];
		unsigned lhsLength = [lhs length];
		//NSArray* chains = [graph chainsWithLength: lhsLength level: level];
		id label = [[[lhs edges] objectAtIndex: 0] label];
		id type = [label objectForKey: @"type"];
		if (type == nil) { NSLog(@"type in rule is nil"); exit(1); }
		id cacheKey;
		if (type == nil) cacheKey = [NSNumber numberWithInt: lhsLength];
		else cacheKey = [NSString stringWithFormat: @"%d-%@", lhsLength, type];
		NSArray* chains = [cachedChains objectForKey: cacheKey];
		if (chains == nil) {
			chains = [graph chainsWithLength: lhsLength level: level type: type unusedOnly: deterministic];
			if (chains == nil) chains = [NSMutableArray arrayWithCapacity: 1];
			[cachedChains setObject: chains forKey: cacheKey];
		}
		//NSLog(@"%@", [chains description]);
		NSEnumerator* chainsEnumerator = [chains objectEnumerator];
		NSArray* chain;
		while (chain = [chainsEnumerator nextObject]) { // mozne podretezce grafu k unifikaci
			NSEnumerator* chainEnumerator = [chain objectEnumerator];
			QSEdge* edge1; BOOL hasEdgeWithLevel = NO;
			while (edge1 = [chainEnumerator nextObject]) { // kontrola urovne, aspon pro jednu hranu musi byt level
				if ([edge1 level] == level) hasEdgeWithLevel = YES;
			}
			if (!hasEdgeWithLevel) continue;
			if (deterministic == YES) { // je-li parsing deterministicky, uvazujeme jen nepouzite hrany
				chainEnumerator = [chain objectEnumerator];
				while (edge1 = [chainEnumerator nextObject]) {
					if ([edge1 isUsed]) {
						//NSLog(@"########## used edge -- ignoring chain");
						continue;
					}
				}
			}
			[QXVariable clear]; // vsechny promenne jsou zpocatku volne
			chainEnumerator = [chain objectEnumerator];
			NSEnumerator* lhsEnumerator = [[[rule leftHandSide] edges] objectEnumerator];
			QSEdge* edge2; BOOL succeeded = YES;
			//NSLog(@"-- %d %d", lhsLength, [chain count]);
			int pos = 1;
			while (edge1 = [chainEnumerator nextObject]) { // pokus o unifikaci vsech hran
				edge2 = [lhsEnumerator nextObject];
				NSDictionary* unifResult = [[edge1 label] unifyWith: [edge2 label]];
				if (unifResult == nil) {
					succeeded = NO; // nelze unifikovat
					//NSLog(@"unif. failed %@ %@ %@ %@", [[edge1 leftNode] name], [[edge1 rightNode] name], [[edge1 label] description], [[edge2 label] description]);
					break;
				} else {
					// vysledek unifikace dame do promenne $N, aby bylo mozne na RHS vytvorit vnorenou FS
					QXVariable* var = [QXVariable variableWithName: [[NSNumber numberWithInt: pos++] description]];
					[var setValue: unifResult];
					//NSLog(@"unif. ok %@ %@ %@ %@", [[edge1 leftNode] name], [[edge1 rightNode] name], [[edge1 label] description], [[edge2 label] description]);
				}
			}
			if (succeeded) { // unifikace se povedla, rozsirime graf
				NSMutableArray* newChain = [NSMutableArray arrayWithCapacity: [[rule rightHandSide] length]];
				NSEnumerator* enumerator = [[[rule rightHandSide] edges] objectEnumerator];
				QSEdge* edge;
				while (edge = [enumerator nextObject]) { // na zaklade pravidla vytvorime novy podretezec
					// pripadne unifikace se strukturou hlavy
					NSNumber* headRef = [edge head];
					NSDictionary* head = headRef != nil ? [[QXVariable variableWithName: [headRef description]] getValue] : [NSDictionary dictionaryWithObjectsAndKeys: nil];
					NSDictionary* dict = [[edge label] unifyWith: head];
					if (dict == nil) { // the variable value cannot be unified
						succeeded = NO;
						break;
					}
					QSEdge* newEdge = [QSEdge edgeWithLabel: dict];
					[newEdge setLevel: level + 1];
					[newChain addObject: newEdge];
				}
				if (succeeded) {
					[graph increaseNumberOfAddedEdgesBy: [[[rule rightHandSide] edges] count]];
					enumerator = [chain objectEnumerator];
					QSVertex *firstNode = nil, *lastNode;
					while (edge = [enumerator nextObject]) { // oznaceni starych hran jako pouzite
						[edge setUsed: YES];
						if (firstNode == nil) firstNode = [edge leftNode];
						lastNode = [edge rightNode];
					}
					enumerator = [newChain objectEnumerator];
					QSEdge *prev = nil, *firstEdge = nil, *lastEdge;
					while (edge = [enumerator nextObject]) { // vzajemne propojeni novy hran
						//NSLog(@"%@", [edge label]);
						if (firstEdge == nil) firstEdge = edge;
						lastEdge = edge;
						if (prev != nil) {
							QSVertex* vertex = [[QSVertex alloc] initWithName: [[NSNumber numberWithInt: (*nodeIndex)++] description]];
							[graph addVertex: vertex];
							[vertex release];
							[prev setRightNode: vertex];
							[edge setLeftNode: vertex];
							[vertex addLeftEdge: prev];
							[vertex addRightEdge: edge];
						}
						prev = edge;
					}
					// napojeni noveho podretezce do grafu
					[firstEdge setLeftNode: firstNode];
					[lastEdge setRightNode: lastNode];
					[firstNode addRightEdge: firstEdge];
					[lastNode addLeftEdge: lastEdge];
					extended = YES;
					//NSLog(@"succ. rule appl. %@-%@ (level %d, rule %d)", [firstNode name], [lastNode name], level, [rule id]);
					//if (deterministic == YES) break; // je-li parsing deterministicky, ignorujeme zbytek
				}
			}
		}
	}
	//if ([graph numberOfAddedEdges] > 20) NSLog(@"***** cut *****");
	*success = extended; // && [graph numberOfAddedEdges] <= 20;
}

- (void)addRule:(QSRule*)rule {
	//if ([oddRules count] == [evenRules count]) [oddRules addObject: rule];
	//else  [evenRules addObject: rule];
	[allRules addObject: rule];
	NSArray* signature = [rule signature];
	NSMutableSet* rules = [mapOfRules objectForKey: signature];
	if (rules == nil) {
		rules = [NSMutableSet set];
		[mapOfRules setObject: rules forKey: signature];
	}
	[rules addObject: rule];
	if ([[rule leftHandSide] length] == 1) {
		NSDictionary* dict = [(QSEdge*) [[[rule leftHandSide] edges] objectAtIndex: 0] label];
		if ([[dict objectForKey: @"type"] isEqual: @"word"]) {
			//NSLog(@"adding unary rule for word");
			id value = [dict objectForKey: @"value"];
			if (value != nil) {
				NSMutableSet* set = [rulesForWordByValue objectForKey: value];
				if (set == nil) {
					set = [[NSMutableSet alloc] init];
					[rulesForWordByValue setObject: set forKey: value];
					[set release];
				}
				[set addObject: rule];
			}
			id lemma = [dict objectForKey: @"lemma"];
			if (lemma != nil) {
				NSMutableSet* set = [rulesForWordByValue objectForKey: lemma];
				if (set == nil) {
					set = [[NSMutableSet alloc] init];
					[rulesForWordByValue setObject: set forKey: lemma];
					[set release];
				}
				[set addObject: rule];
			}
		}
	}
}

- (float)percentOfEmptyGraphs {
	return noOfEmptyGraphs / (float) noOfGraphs;
}

- (NSDictionary*)mapOfRules {
	return mapOfRules;
}

- (void)setStopWatch:(QXStopWatch*)_stopWatch {
	stopWatch = [_stopWatch retain];
}

- (NSSet*)rules {
	return allRules;
}

- (NSArray*)rulesForType:(NSString*)type {
	return [rulesByFirstType objectForKey: type];
}

- (NSDictionary*)rulesForWordByValue {
	return rulesForWordByValue;
}

- (NSDictionary*)rulesForWordByLemma {
	return rulesForWordByLemma;
}

- (void)dealloc {
	NSLog(@"applied: %f%%", (rulesTriedToApply / (countTriedToApply * (float) [allRules count])) * 100);
	[allRules release];
	[mapOfRules release];
	[mapOfRulesByFixedSignature release];
	[volatileAttributes release];
	[fixedAttributes release];
	[allAttributes release];
	[stopWatch release];
	//[oddRules release];
	//[evenRules release];
	[rulesByFirstType release];
	[rulesForWordByValue release];
	[rulesForWordByLemma release];
	[super dealloc];
}
@end
