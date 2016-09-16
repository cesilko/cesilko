//
//  QXStructuralTransfer.m
//  CzSk
//
//  Created by Petr Homola on 21.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QXStructuralTransfer.h"

static NSString* targetLanguage;

@implementation QXStructuralTransfer

/*- (id)init {
	if (self = [super init]) {
		featureStructures = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc {
	[featureStructures release];
	[super dealloc];
}*/

/*- (NSMutableDictionary*)featureStructures {
	return featureStructures;
}*/

+ (void)setTargetLanguage:(NSString*)lang {
	targetLanguage = lang;
}

+ (NSString*)targetLanguage {
	return targetLanguage;
}

- (void)transfer:(NSMutableDictionary*)head child:(NSMutableDictionary*)child result:(NSMutableArray*)result attribute:(NSString*)attName {
	NSLog(@"abstract instance method invoked in %@", self.className);
}

- (void)preprocess:(NSMutableDictionary*)dict result:(NSMutableArray*)result { // parent:(NSMutableDictionary*)parent {
	NSLog(@"abstract instance method invoked in %@", self.className);
}

@end
