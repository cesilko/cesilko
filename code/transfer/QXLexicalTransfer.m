//
//  QXLexicalTransfer.m
//  CzSk
//
//  Created by Petr Homola on 21.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QXLexicalTransfer.h"

static NSMutableSet* messages;
static NSMutableSet* unknownLemmas;

@implementation QXLexicalTransfer
+ (void)initialize {
	messages = [[NSMutableSet alloc] init];
	unknownLemmas = [[NSMutableSet alloc] init];
}

- (id)initWithFile:(NSString*)fileName {
	NSLog(@"abstract instance method invoked in %@", self.className);
	return nil;
}

+ (void)addUnknownLemma:(NSString*)lemma {
	[unknownLemmas addObject: lemma];
}

+ (NSSet*)unknownLemmas {
	return unknownLemmas;
}

- (void)transfer:(NSDictionary*)source result:(NSMutableArray*)result {
	NSLog(@"abstract instance method invoked in %@", self.className);
}

+ (void)log:(NSString*)message {
	[messages addObject: message];
}

+ (NSArray*)messages {
	return messages.allObjects;
}
@end
