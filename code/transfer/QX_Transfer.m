//
//  QX_Transfer.m
//  Systems-Q
//
//  Created by Petr Homola on 17.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QX_Transfer.h"
#import "QXLexicalTransfer.h"
#import "QXStructuralTransfer.h"
#import "CSMorphologicalGenerator.h"
#import "QX_String.h"

static int max_id = 1000;
//static int fs_id = 1;
static QXLexicalTransfer* lexicalTransfer;
static QXStructuralTransfer* structuralTransfer;
static CSMorphologicalGenerator* targetMorphology;

@implementation NSDictionary (QXTransfer)
+ (QXLexicalTransfer*)lexicalTransfer {
	return lexicalTransfer;
}

+ (void)setLexicalTransfer:(QXLexicalTransfer*)_lexicalTransfer {
	lexicalTransfer = _lexicalTransfer;
}

+ (QXStructuralTransfer*)structuralTransfer {
	return structuralTransfer;
}

+ (void)setStructuralTransfer:(QXStructuralTransfer*)_structuralTransfer {
	structuralTransfer = _structuralTransfer;
}

+ (CSMorphologicalGenerator*)targetMorphology {
	return targetMorphology;
}

+ (void)setTargetMorphology:(CSMorphologicalGenerator*)_targetMorphology {
	targetMorphology = _targetMorphology;
}

- (NSArray*)transfer:(BOOL)recursive done:(BOOL*)done {
	NSMutableArray* result = [NSMutableArray arrayWithCapacity: 2];
	
	//NSString* fsid = [self objectForKey: @"fsid"];
	if ([self objectForKey: @"lextr"] == nil) {
		[lexicalTransfer transfer: self result: result];
		/*NSEnumerator* enumerator = [result objectEnumerator];
		NSMutableDictionary* dict;
		while (dict = [enumerator nextObject]) {
			fsid = [[NSNumber numberWithInt: fs_id++] description];
			[dict setObject: fsid forKey: @"fsid"];
			[[structuralTransfer featureStructures] setObject: dict forKey: fsid];
			//NSLog(@"----- %@ %@", [dict objectForKey: @"lemma"], fsid);
		}*/
	} else if ([self objectForKey: @"preproctr"] == nil) {
		/*NSString* parentFsid = [self objectForKey: @"parent"];
		NSMutableDictionary* parent = [[structuralTransfer featureStructures] objectForKey: parentFsid];*/
		[structuralTransfer preprocess: (NSMutableDictionary*) self result: result]; // parent: parent];
	} else { // decomposition
		id childKey;
		childKey = [self leftMostChild];
		if (childKey != nil) {
			NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: self];
			id child = [NSMutableDictionary dictionaryWithDictionary: [head objectForKey: childKey]];
			//[child setObject: fsid forKey: @"parent"];
			[child setObject: [self objectForKey: @"left"] forKey: @"left"];
			NSString* num = [[NSNumber numberWithInt: max_id++] description];
			[child setObject: num forKey: @"right"];
			[head setObject: num forKey: @"left"];
			[head removeObjectForKey: childKey];
			[structuralTransfer transfer: head child: child result: result attribute: childKey];
			childKey = nil;
		} else childKey = [self rightMostChild];
		if (childKey != nil) {
			NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: self];
			id child = [NSMutableDictionary dictionaryWithDictionary: [head objectForKey: childKey]];
			//[child setObject: fsid forKey: @"parent"];
			[child setObject: [self objectForKey: @"right"] forKey: @"right"];
			NSString* num = [[NSNumber numberWithInt: max_id++] description];
			[child setObject: num forKey: @"left"];
			[head setObject: num forKey: @"right"];
			[head removeObjectForKey: childKey];
			[structuralTransfer transfer: head child: child result: result attribute: childKey];
		}
	}
	
	if ([result count] == 0) {
		*done = NO;
		result = [NSArray arrayWithObject: self];
	} else {
		*done = YES;
		if (recursive) result = [NSDictionary transferArray: result];
	}
	return result;
}

+ (NSMutableArray*)transferArray:(NSMutableArray*)array {
	NSMutableArray* result = [NSMutableArray arrayWithCapacity: 5];
	NSEnumerator* enumerator = [array objectEnumerator];
	id obj;
	while (obj = [enumerator nextObject]) {
		if ([obj objectForKey: @"trdone"]) { //NSLog(@"##### %@", [obj objectForKey: @"lemma"]);
			[result addObject: obj];
		} else {
			BOOL done;
			NSArray* subresult = [obj transfer: YES done: &done];
			if (done) [result addObjectsFromArray: subresult]; else [result addObject: obj];
		}
	}
	return result;
}

+ (NSArray*)linearize:(NSEnumerator*)enumerator {
	NSMutableDictionary* edges = [NSMutableDictionary dictionaryWithCapacity: 5];
	NSMutableSet* leftIds = [NSMutableSet setWithCapacity: 10];
	NSMutableSet* rightIds = [NSMutableSet setWithCapacity: 10];
	//NSEnumerator* enumerator = [array objectEnumerator];
	id obj;
	while (obj = [enumerator nextObject]) {
		[leftIds addObject: [obj objectForKey: @"left"]];
		[rightIds addObject: [obj objectForKey: @"right"]];
		NSMutableSet* set = [edges objectForKey: [obj objectForKey: @"left"]];
		if (set == nil) {
			set = [NSMutableSet setWithCapacity: 5];
			[edges setObject: set forKey: [obj objectForKey: @"left"]];
		}
		[set addObject: obj];
	}
	NSString* start = [[NSNumber numberWithInt: INT_MAX] description];
	enumerator = [leftIds objectEnumerator];
	while (obj = [enumerator nextObject]) {
		if (![rightIds member: obj] && [start intValue] > [obj intValue]) start = obj;
	}
	NSString* end = @"0";
	enumerator = [rightIds objectEnumerator];
	while (obj = [enumerator nextObject]) {
		if (![leftIds member: obj] && [obj intValue] < 100000 && [end intValue] < [obj intValue]) end = obj;
	}
	NSLog(@"coverage: %@-%@", start, end);
	NSMutableDictionary* cache = [NSMutableDictionary dictionary];
	return [NSDictionary paths: start end: end edges: edges cache: cache];
}

+ (NSArray*)paths:(NSString*)start end:(NSString*)end edges:(NSDictionary*)edges cache:(NSMutableDictionary*)cache {
	id cached = [cache objectForKey: [NSArray arrayWithObjects: start, end, nil]];
	if (cached != nil) {
		//NSLog(@"cached result for %@-%@", start, end);
		return cached;
	}
	NSMutableArray* result = [NSMutableArray arrayWithCapacity: 5];
	NSSet* set = [edges objectForKey: start];
	NSEnumerator* enumerator = [set objectEnumerator];
	id obj;
	while (obj = [enumerator nextObject]) {
		NSString* right = [obj objectForKey: @"right"];
		id repr = obj; //[obj objectForKey: @"lemma"];
		if (![edges objectForKey: right]) {
			if ([right isEqual: end]) {
				//NSLog(@"##### %@", repr);
				[result addObject: [NSArray arrayWithObject: repr]];
			} //else { NSLog(@"##### oops: %@ %@", right, end); exit(1); }
		} else {
			NSArray* tails = [NSDictionary paths: right end: end edges: edges cache: cache];
			NSEnumerator* enumerator2 = [tails objectEnumerator];
			id obj2;
			while (obj2 = [enumerator2 nextObject]) {
				NSMutableArray* path = [NSMutableArray arrayWithObject: repr];
				[path addObjectsFromArray: obj2];
				[result addObject: path];
			}
		}
	}
	[cache setObject: result forKey: [NSArray arrayWithObjects: start, end, nil]];
	return result;
}

- (id)leftMostChild {
	id result = nil;
	id objOrder = [self objectForKey: @"order"];
	if (objOrder == nil) return nil;
	float order1 = atof([objOrder cString]);
	float min = order1;
	NSEnumerator* enumerator = [[self allKeys] objectEnumerator];
	id key;
	while (key = [enumerator nextObject]) {
		id obj = [self objectForKey: key];
		if ([obj isKindOfClass: [NSDictionary class]]) {
			float order2 = atof([[obj objectForKey: @"order"] cString]);
			if (order2 < min) { result = key; min = order2; }
		}
	}
	return result;
}

- (id)leftClosestChild {
	id result = nil;
	float order1 = atof([[self objectForKey: @"order"] cString]);
	float max = 0;
	NSEnumerator* enumerator = [[self allKeys] objectEnumerator];
	id key;
	while (key = [enumerator nextObject]) {
		id obj = [self objectForKey: key];
		if ([obj isKindOfClass: [NSDictionary class]]) {
			float order2 = atof([[obj objectForKey: @"order"] cString]);
			if (order2 > max && order2 < order1) { result = key; max = order2; }
		}
	}
	return result;
}

- (id)rightMostChild {
	id result = nil;
	id objOrder = [self objectForKey: @"order"];
	if (objOrder == nil) return nil;
	float order1 = atof([objOrder cString]);
	float max = order1;
	NSEnumerator* enumerator = [[self allKeys] objectEnumerator];
	id key;
	while (key = [enumerator nextObject]) {
		id obj = [self objectForKey: key];
		if ([obj isKindOfClass: [NSDictionary class]]) {
			float order2 = atof([[obj objectForKey: @"order"] cString]);
			if (order2 > max) { result = key; max = order2; }
		}
	}
	return result;
}

- (id)rightClosestChild {
	id result = nil;
	float order1 = atof([[self objectForKey: @"order"] cString]);
	float min = 1000000;
	NSEnumerator* enumerator = [[self allKeys] objectEnumerator];
	id key;
	while (key = [enumerator nextObject]) {
		id obj = [self objectForKey: key];
		if ([obj isKindOfClass: [NSDictionary class]]) {
			float order2 = atof([[obj objectForKey: @"order"] cString]);
			if (order2 < min && order2 > order1) { result = key; min = order2; }
		}
	}
	return result;
}
@end

@implementation NSArray (QXTransfer)
/*- (void)prune {
	int i, j;
	for (i = 0; i < [self count]; i++) {
		NSDictionary* dict1 = [self objectAtIndex: i];
		for (j = i + 1; j < [self count]; j++) {
			NSDictionary* dict2 = [self objectAtIndex: j];
			if ([[dict1 objectForKey: @"left"] isEqual: [dict2 objectForKey: @"left"]]
			  && [[dict1 objectForKey: @"right"] isEqual: [dict2 objectForKey: @"right"]]
			  && [[dict1 objectForKey: @"target_form"] isEqual: [dict2 objectForKey: @"target_form"]]) {
				[(NSMutableArray*) self removeObjectAtIndex: j--];
			}
		}
	}
}*/

- (void)prune {
	NSMutableSet* pruned = [NSMutableSet set];
	int i, j;
	for (i = 0; i < [self count]; i++) {
		if (![pruned member: [NSNumber numberWithInt: i]]) {
			NSDictionary* dict1 = [self objectAtIndex: i];
			for (j = i + 1; j < [self count]; j++) {
				if (![pruned member: [NSNumber numberWithInt: j]]) {
					NSDictionary* dict2 = [self objectAtIndex: j];
					if ([[dict1 objectForKey: @"left"] isEqual: [dict2 objectForKey: @"left"]]
					  && [[dict1 objectForKey: @"target_form"] isEqual: [dict2 objectForKey: @"target_form"]]) {
						[self tryToPrune: dict1 :dict2 rightNode: [dict1 objectForKey: @"right"] :[dict2 objectForKey: @"right"] pruned: pruned pruneIndex: j];
					}
				}
			}
		}
	}
	NSEnumerator* enumerator = [pruned objectEnumerator];
	NSNumber* num;
	while ((num = [enumerator nextObject])) {
		int index = [num intValue];
		[(NSMutableArray*) self replaceObjectAtIndex: index withObject: [NSNull null]];
	}
	for (i = 0; i < [self count]; i++) {
		id el = [self objectAtIndex: i];
		if (el == [NSNull null]) {
			[(NSMutableArray*) self removeObjectAtIndex: i--];
		}
	}
}

- (BOOL)tryToPrune:(NSDictionary*)dict1 :(NSDictionary*)dict2 rightNode:(id)node1 :(id)node2 pruned:(NSMutableSet*)pruned pruneIndex:(int)index {
	if ([node1 isEqual: node2]) {
		[pruned addObject: [NSNumber numberWithInt: index]];
		return YES;
	} else {
		int i, nextPruneIndex; NSDictionary *next1 = nil, *next2 = nil;
		for (i = 0; i < [self count]; i++) {
			NSDictionary* dict = [self objectAtIndex: i];
			if ([[dict objectForKey: @"left"] isEqual: node1]) next1 = dict;
			if ([[dict objectForKey: @"left"] isEqual: node2]) { next2 = dict; nextPruneIndex = i; }
			if (next1 != nil && next2 != nil) break;
		}
		if (![[next1 objectForKey: @"target_form"] isEqual: [next2 objectForKey: @"target_form"]]) return NO;
		else {
			BOOL succeeded = [self tryToPrune: next1 :next2 rightNode: [next1 objectForKey: @"right"] :[next2 objectForKey: @"right"] pruned: pruned pruneIndex: nextPruneIndex];
			if (succeeded) [pruned addObject: [NSNumber numberWithInt: index]];
			return succeeded;
		}
	}
}

- (NSArray*)completize {
	NSMutableArray* results = [[NSMutableArray alloc] initWithCapacity: [self count]];
	NSEnumerator* enumerator = [self objectEnumerator];
	NSMutableArray* array;
	while (array = [enumerator nextObject]) {
		if ([[array objectAtIndex: [array count] - 1] isEqual: [NSArray arrayWithObject: @""]]) [array removeObjectAtIndex: [array count] - 1];
		NSString* sentence = [NSString completize: array];
		[results addObject: sentence];
	}
	return results;
}

- (NSArray*)translate {
	return [self translateTagsAsOutput: NO];
}

- (NSArray*)translateTagsAsOutput:(BOOL)tagsAsOutput {
	NSMutableArray* results = [[NSMutableArray alloc] initWithCapacity: [self count]];
	NSEnumerator* enumerator = [self objectEnumerator];
	id dict;
	while (dict = [enumerator nextObject]) {
		BOOL done;
		NSArray* result = [dict transfer: YES done: &done];
		[results addObjectsFromArray: result];
	}
	//NSLog(@"#results: %d", [results count]);
	//if ([results count] > 200) return nil; // "neverending" threads won't be waited for
	
	/*enumerator = [results objectEnumerator];
	id result;
	while (result = [enumerator nextObject]) {
		NSLog(@"%@-%@ %@ %@", [result objectForKey: @"left"], [result objectForKey: @"right"], [result objectForKey: @"order"], [result description]);
	}*/
	
	NSArray* extendedAVMs = [targetMorphology generateByExtendingAVMs: results];
	[extendedAVMs prune];
	NSLog(@"pruned: %d -> %d", [results count], [extendedAVMs count]);
	//NSLog(@"%@", extendedAVMs);
	NSArray* sequences = [NSDictionary linearize: [extendedAVMs objectEnumerator]];
	NSLog(@"#sequences: %d", [sequences count]);
	//if ([sequences count] > 1000) return nil; // "neverending" threads won't be waited for
	//NSArray* results2 = [targetMorphology generateArray: sequences];
	//NSArray* results2 = [sequences extractTargetForms];
	//NSLog(@"%@", results2);
	NSSet* results3 = [sequences extractTargetFormsTagsAsOutput: tagsAsOutput]; //[NSMutableSet setWithCapacity: [results2 count]];
	//[results3 addObjectsFromArray: results2];
	NSLog(@"#unique sequences: %d", [results3 count]);
	//if ([results3 count] > 100) return nil; // "neverending" threads won't be waited for
	NSMutableArray* results4 = [NSMutableArray arrayWithCapacity: [results3 count]];
	[results4 addObjectsFromArray: [results3 allObjects]];
	
	/*enumerator = [results3 objectEnumerator];
	id result;
	while (result = [enumerator nextObject]) {
		NSLog(@"%@", [result textualDescription]);
	}*/
	
	return results4;
}

- (NSSet*)extractTargetFormsTagsAsOutput:(BOOL)tagsAsOutput {
	NSMutableSet* results = [[NSMutableSet alloc] initWithCapacity: [self count]];
	NSEnumerator* enumerator = [self objectEnumerator];
	NSArray* sequence; unsigned n = 0, max = 10000;
	while ((sequence = [enumerator nextObject])) {
		NSMutableArray* sentence = [[NSMutableArray alloc] initWithCapacity: [sequence count]];
		NSEnumerator* enumerator2 = [sequence objectEnumerator];
		NSDictionary* dict;
		while ((dict = [enumerator2 nextObject])) {
			NSSet* forms = [dict objectForKey: @"target_form"];
			//if ([forms count] > 1) { NSLog(@"########## %@ %@", forms, dict); [NSThread sleepForTimeInterval: 1]; }
			//NSString* form = [[forms objectEnumerator] nextObject];
			if (tagsAsOutput == NO) {
				[sentence addObject: forms];
			} else {
				NSString* form = [forms count] == 0 ? @"xxx" : [[forms objectEnumerator] nextObject];
				NSRange range = [form rangeOfString: @"≈≈"];
				if (range.location != NSNotFound) {
					[sentence addObject: [NSSet setWithObject: form]];
				} else {
					NSString* pos = [dict objectForKey: @"pos"];
					if (pos == nil) pos = @"x";
					NSMutableString* tag = [pos mutableCopy];
					NSArray* features =
					[NSArray arrayWithObjects: @"vform", @"prontype", @"def", @"gender", @"number", @"case", @"person", nil];
					NSEnumerator* enumerator = [features objectEnumerator];
					NSString* feature;
					while (feature = [enumerator nextObject]) {
						id value = [dict objectForKey: feature];
						if (value != nil && [value isKindOfClass: [NSString class]]) [tag appendFormat: @"_%@", value];
					}
					[sentence addObject: [NSSet setWithObject: [form stringByAppendingFormat: @"_%@", tag]]];
				}
			}
		}
		[results addObject: sentence];
		if (++n == max) {
			NSLog(@"taking first %u sequences", max);
			break;
		}
	}
	return results;
}

- (NSString*)textualDescription {
	NSMutableString* string = [NSMutableString stringWithString: @""];
	NSEnumerator* enumerator = [self objectEnumerator];
	id obj;
	while (obj = [enumerator nextObject]) {
		[string appendString: [obj description]];
		[string appendString: @" "];
	}
	return string;
}

- (void)writeToFileAtPath:(NSString*)path {
	FILE* file = fopen([path UTF8String], "w");
	NSEnumerator* enumerator = [self objectEnumerator];
	NSString* el;
	while ((el = [enumerator nextObject])) {
		NSArray* tokens = [el split];
		fprintf(file, "%s|%s\n", [[tokens objectAtIndex: 5] UTF8String], [[tokens objectAtIndex: 6] UTF8String]);
	}
	fclose(file);
}
@end
