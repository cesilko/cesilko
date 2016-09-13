//
//  HashtableForNGrams.h
//  HMM
//
//  Created by Petr Homola on 29.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct _NGram {
	int pos;
} NGram;

typedef struct _HashnodeForNGrams {
	NGram* key;
	int value;
	struct _HashnodeForNGrams* next;
} HashnodeForNGrams;

typedef struct _HashtableIntForNGrams {
	HashnodeForNGrams** array;
} HashtableIntForNGrams;

@interface HashtableForNGrams : NSObject {
	HashtableIntForNGrams* ht;
	int* data;
	unsigned size;
	unsigned count;
	unsigned ngramSize;
}

- (id)initWithCapacity:(unsigned)numItems ngramSize:(unsigned)_ngramSize data:(int*)_data;
- (HashnodeForNGrams*)setInt:(int)value forKey:(NGram*)key;
- (int)intForKey:(NGram*)key;
- (unsigned)hashForNGram:(NGram*)ngram;
- (BOOL)isEqualNGram:(NGram*)ngram1 toNGram:(NGram*)ngram2;
- (int)intForKey:(NGram*)key withData:(int*)_data;
- (unsigned)hashForNGram:(NGram*)ngram withData:(int*)_data;
- (BOOL)isEqualNGram:(NGram*)ngram1 toNGram:(NGram*)ngram2 withData:(int*)_data;
- (unsigned)count;

@end
