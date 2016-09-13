//
//  QXStopWatch.m
//  Jyxo Parser
//
//  Created by Petr Homola on 10.04.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "QXStopWatch.h"

@implementation QXStopWatch

- (id)init {
	if (self = [super init]) {
		sum = [[NSMutableDictionary alloc] init];
		running = [[NSMutableDictionary alloc] init];
		lock = [[NSLock alloc] init];
	}
	return self;
}

- (void)summarize {
	NSEnumerator* enumerator = [[sum allKeys] objectEnumerator];
	NSString* section;
	while (section = [enumerator nextObject]) {
		NSNumber* total = [sum objectForKey: section];
		NSLog(@"Stop watch - %@: %@", section, total);
	}
}

- (void)start:(NSString*)section {
	[lock lock];
	if ([running objectForKey: section] != nil) {
		NSLog(@"error: already measuring section %@", section);
	} else {
		[running setObject: [NSDate date] forKey: section];
	}
	[lock unlock];
}

- (void)stop:(NSString*)section {
	[lock lock];
	NSDate* start = [running objectForKey: section];
	if (start == nil) {
		NSLog(@"error: not measuring section %@", section);
	} else {
		NSTimeInterval duration = -[start timeIntervalSinceNow];
		NSNumber* total = [sum objectForKey: section];
		if (total != nil) total = [NSNumber numberWithFloat: [total floatValue] + duration];
		else total = [NSNumber numberWithFloat: 0];
		[sum setObject: total forKey: section];
		[running removeObjectForKey: section];
	}
	[lock unlock];
}

- (void)dealloc {
	[sum release];
	[running release];
	[lock release];
	[super dealloc];
}

@end
