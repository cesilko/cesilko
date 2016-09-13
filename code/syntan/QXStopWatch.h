//
//  QXStopWatch.h
//  Jyxo Parser
//
//  Created by Petr Homola on 10.04.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface QXStopWatch : NSObject {
	NSMutableDictionary* sum;
	NSMutableDictionary* running;
	NSLock* lock;
}

- (void)start:(NSString*)section;
- (void)stop:(NSString*)section;
- (void)summarize;

@end
