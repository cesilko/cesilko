//
//  CSMorphologicalGenerator.m
//  CzSk
//
//  Created by Petr Homola on 21.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CSMorphologicalGenerator.h"

static NSMutableSet* messages;

@implementation CSMorphologicalGenerator
+ (void)initialize {
	messages = [[NSMutableSet alloc] init];
}

- (id)initWithFile:(NSString*)_fileName {
	NSLog(@"abstract instance method invoked in %@", [self className]);
	return nil;
}

- (void)load {
	NSLog(@"abstract instance method invoked in %@", [self className]);
}

- (NSArray*)generate:(NSString*)lemma tagPrefix:(id)tagPrefix {
	NSLog(@"abstract instance method invoked in %@", [self className]);
	return nil;
}

- (NSArray*)generateArray:(NSArray*)sentence {
	NSLog(@"abstract instance method invoked in %@", [self className]);
	return nil;
}

- (NSArray*)generateByExtendingAVMs:(NSArray*)avms {
	NSLog(@"abstract instance method invoked in %@", [self className]);
	return nil;
}

/*- (NSArray*)analyze:(NSString*)form {
	NSLog(@"abstract instance method invoked in %@", [self className]);
	return nil;
}*/

+ (void)log:(NSString*)message {
	[messages addObject: message];
}

+ (NSArray*)messages {
	return [messages allObjects];
}
@end
