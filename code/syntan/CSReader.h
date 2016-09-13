//
//  CSReader.h
//  CzSk
//
//  Created by Petr Homola on 21.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface CSReader : NSObject {
	NSString* fileName;
}
- (id)initWithFile:(NSString*)_fileName;
+ (id)readerWithFile:(NSString*)_fileName;
- (id)initWithTaggedFile:(NSString*)_fileName;
+ (id)readerWithTaggedFile:(NSString*)_fileName;
- (NSArray*)sentences;
- (NSArray*)taggedSentences;
@end
