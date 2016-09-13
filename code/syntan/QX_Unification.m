#import "QX_Unification.h"
#import "QXVariable.h"

@implementation NSDictionary (QXUnification)

- (NSSet*)signature {
	NSEnumerator* enumerator = [[self allKeys] objectEnumerator];
	NSString* key; NSMutableSet* signature = [NSMutableSet set];
	while (key = [enumerator nextObject]) {
		id value = [self objectForKey: key];
		if (![value isKindOfClass: [QXVariable class]]) [signature addObject: key];
	}
	return signature;
}

- (NSString*)safeDescription {
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	NSEnumerator* enumerator = [[self allKeys] objectEnumerator];
	id key;
	while (key = [enumerator nextObject]) {
		id value = [self objectForKey: key];
		if ([value isKindOfClass: [NSString class]]) [dict setObject: value forKey: key];
		else if ([value isKindOfClass: [QXVariable class]]) {
			[dict setObject: [NSString stringWithFormat: @"$%@", [value name]] forKey: key];
			//NSLog(@"# %@", [QXVariable count]);
		} else if ([value isKindOfClass: [NSDictionary class]]) [dict setObject: @"DICT" forKey: key];
		else {
			NSLog(@"???: %@", [value className]);
			exit(1);
		}
	}
	return [dict description];
}

- (NSDictionary*)unifyWith:(NSDictionary*)dict {
	NSMutableDictionary* result = [NSMutableDictionary dictionary];
	NSArray* keys = [self allKeys];
	NSEnumerator* enumerator = [keys objectEnumerator];
	id key;
	while ((key = [enumerator nextObject])) {
		//NSLog(@"%@", key);
		id value1 = [self objectForKey: key];
		//if ([value1 isKindOfClass: [QXVariable class]]) NSLog(@"################## %@", [value1 name]);
		if ([value1 isKindOfClass: [QXVariable class]] && [self isBound: value1]) value1 = [value1 getValue];
		id value2 = [dict objectForKey: key];
		//if ([key isEqual: @"+att"]) NSLog(@"########## +att %@ %@", value1, value2);
		if ([value2 isKindOfClass: [QXVariable class]] && [self isBound: value2]) value2 = [value2 getValue];
		//NSLog(@"#");
		if (value2 == nil) [result setObject: value1 forKey: key];
		else {
			//NSLog(@"%d %d", [self isBound: value1], [self isBound: value2]);
			//if ([key isEqual: @"lemma"] && [value1 isEqual: @"být"]) NSLog(@"##### %@ %@", value1, value2);
			if ([self isBound: value1] && [self isBound: value2]) {
				if ([value1 isEqual: value2]) [result setObject: value1 forKey: key]; else return nil;
			} else if ([self isFree: value1] && [self isFree: value2]) {
				//if (NSLog(@"both variables are free!");
				[value1 bind: value2];
				[result setObject: value1 forKey: key];
			} else if ([self isFree: value1] && [self isBound: value2]) {
				[value1 setValue: value2];
				[result setObject: value2 forKey: key];
			} else if ([self isFree: value2] && [self isBound: value1]) {
				[value2 setValue: value1];
				[result setObject: value1 forKey: key];
			} else if ([value1 isKindOfClass: [NSDictionary class]] && [value2 isKindOfClass: [NSDictionary class]]) {
				NSDictionary* value = [value1 unifyWith: value2];
				if (value == nil) return nil; else [result setObject: value forKey: key];
			} else {
				//if ([key isEqual: @"decl"]) NSLog(@"################## %@ %@ %d", [value1 objectForKey: @"type"], [value2 name], [self isBound: value1]);
				/*if ([self isFree: value2]) {
					value1 = [value1 objectForKey: @"list"];
					[value2 setValue: value1];
					[result setObject: value1 forKey: key];
				} else*/ return nil;
			}
		}
	}
	enumerator = [[result allKeys] objectEnumerator];
	while ((key = [enumerator nextObject])) {
		NSString* attKey = key;
		if ([key characterAtIndex: 0] == '+') {
			key = [key substringFromIndex: 1];
			id value = [result objectForKey: attKey];
			id list = [dict objectForKey: key];
			//NSLog(@"##########1 %@ %@", value, list);
			if (list != nil) [value setObject: list forKey: @"tail"];
			[result setObject: value forKey: key];
			[result removeObjectForKey: attKey];
		}
	}		
	keys = [dict allKeys];
	enumerator = [keys objectEnumerator];
	while ((key = [enumerator nextObject])) {
		NSString* attKey = key;
		BOOL mustBeBound = NO;
		if ([key characterAtIndex: 0] == '!') {
			key = [key substringFromIndex: 1];
			mustBeBound = YES;
		}
		id value1 = [result objectForKey: key];
		if (value1 == nil) {
			if (mustBeBound) return nil;
			id value2 = [dict objectForKey: attKey];
			[result setObject: value2 forKey: key];
		}
	}
	//if ([result objectForKey: @"att"] != nil) NSLog(@"#############2 %@", result);
	return result;
}

- (BOOL)isBound:(id)object {
	return [object isKindOfClass: [NSDictionary class]] || [object isKindOfClass: [NSString class]] || [object isKindOfClass: [QXVariable class]] && ![object isFree];
}

- (BOOL)isFree:(id)object {
	return [object isKindOfClass: [QXVariable class]] && [object isFree];
}

+ (NSDictionary*)dictionaryWithArray:(NSArray*)list {
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity: [list count]];
	NSEnumerator* enumerator = [list objectEnumerator];
	NSArray* pair;
	while (pair = [enumerator nextObject]) {
		NSString* key = [pair objectAtIndex: 0];
		id value = [pair objectAtIndex: 1];
		if ([value characterAtIndex: 0] == '$')
			value = [QXVariable variableWithName: [value substringFromIndex: 1]];
		[dict setObject: value forKey: key];
	}
	return dict;
}

@end
