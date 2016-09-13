#import "QXVariable.h"

static NSMutableDictionary* bindings;

@implementation QXVariable

+ (void)initialize {
	[super initialize];
	bindings = [[NSMutableDictionary alloc] init];
}

- (id)initWithName:(NSString*)_name {
	if ((self = [super init])) {
		name = [_name retain];
	}
	return self;
}

+ (id)variableWithName:(NSString*)_name {
	return [[[QXVariable alloc] initWithName: _name] autorelease];
}

+ (unsigned)count {
	return [bindings count];
}

- (id)initWithCoder:(NSCoder*)coder {
	if ((self = [super init])) {
		name = [[coder decodeObject] retain];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
	[coder encodeObject: [self name]];
}

+ (void)clear {
	//NSLog(@"var: clearing");
	[bindings removeAllObjects];
}

- (void)setValue:(id)value {
	//NSLog(@"var: setting %@", [self name]);
	QXVariable* pointer = [[self class] immediatePointer: self];
	[bindings setObject: value forKey: [pointer name]];
}

- (id)getValue {
	QXVariable* pointer = [[self class] immediatePointer: self];
	return [bindings objectForKey: [pointer name]];
}

+ (QXVariable*)immediatePointer:(QXVariable*)variable {
	QXVariable* pointer;
	id value = variable;
	do {
		pointer = value;
		value = [bindings objectForKey: [pointer name]];
	} while (value != nil && [value isKindOfClass: [QXVariable class]]);
	return pointer;
}

- (void)dealloc {
	[name release];
	[super dealloc];
}

- (NSString*)name {
	return name;
}

- (BOOL)isFree {
	QXVariable* pointer = [[self class] immediatePointer: self];
	return [bindings objectForKey: [pointer name]] == nil;
}

- (NSString*)description {
	NSMutableString* string = [[NSMutableString alloc] initWithString: name];
	if ([self isFree]) [string appendString: @" = ???"];
	else {
		[string appendString: @" = "];
		[string appendString: [[self getValue] description]];
	}
	return string;
}

- (void)bind:(QXVariable*)variable {
	if (self != variable) {
		if (![[self name] isEqual: [variable name]]) {
			if ([self isFree]) [self setValue: variable];
			else if ([variable isFree]) [variable setValue: self];
		}
	}
}

@end
