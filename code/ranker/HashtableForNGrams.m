//
//  HashtableForNGrams.m
//  HMM
//
//  Created by Petr Homola on 29.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "HashtableForNGrams.h"

@implementation HashtableForNGrams

- (id)initWithCapacity:(unsigned)numItems ngramSize:(unsigned)_ngramSize data:(int*)_data {
	if (self = [super init]) {
		size = numItems;
		ngramSize = _ngramSize;
		data = _data;
		ht = malloc(sizeof(HashtableIntForNGrams));
		ht->array = malloc(numItems * sizeof(HashnodeForNGrams));
		int i;
		for (i = 0; i < numItems; i++) ht->array[i] = NULL;
	}
	return self;
}

- (int)intForKey:(NGram*)key {
	return [self intForKey: key withData: data];
}

- (int)intForKey:(NGram*)key withData:(int*)_data {
	unsigned hash = [self hashForNGram: key withData: _data] % size;
	HashnodeForNGrams* node = ht->array[hash];
	while (node != NULL) {
		if ([self isEqualNGram: key toNGram: node->key withData: _data]) return node->value;
		node = node->next;
	}
	return -1;
}

- (HashnodeForNGrams*)setInt:(int)value forKey:(NGram*)key {
	unsigned hash = [self hashForNGram: key] % size;
	HashnodeForNGrams* node = ht->array[hash];
	if (node == NULL) {
		node = malloc(sizeof(HashnodeForNGrams));
		NGram* key2 = malloc(sizeof(NGram));
		key2->pos = key->pos;
		node->key = key2;
		node->value = value;
		node->next = NULL;
		ht->array[hash] = node;
		count++;
		return node;
	} else {
		HashnodeForNGrams* prev;
		while (node != NULL) {
			if ([self isEqualNGram: key toNGram: node->key]) {
				node->value = value;
				return node;
			} else {
				prev = node;
				node = node->next;
			}
		}
		node = malloc(sizeof(HashnodeForNGrams));
		NGram* key2 = malloc(sizeof(NGram));
		key2->pos = key->pos;
		node->key = key2;
		node->value = value;
		node->next = NULL;
		prev->next = node;
		count++;
		return node;
	}
}

- (unsigned)hashForNGram:(NGram*)ngram {
	return [self hashForNGram: ngram withData: data];
}

- (unsigned)hashForNGram:(NGram*)ngram withData:(int*)_data {
	unsigned hash = 17; int i;
	int limit = ngram->pos < ngramSize ? ngram->pos + 1 : ngramSize;
	for (i = 0; i < limit; i++) hash = 37 * hash + _data[ngram->pos - i];
	return hash;
}

- (BOOL)isEqualNGram:(NGram*)ngram1 toNGram:(NGram*)ngram2 {
	return [self isEqualNGram: ngram1 toNGram: ngram2 withData: data];
}

- (BOOL)isEqualNGram:(NGram*)ngram1 toNGram:(NGram*)ngram2 withData:(int*)_data {
	int i;
	int limit1 = ngram1->pos < ngramSize ? ngram1->pos + 1 : ngramSize;
	int limit2 = ngram2->pos < ngramSize ? ngram2->pos + 1 : ngramSize;
	if (limit1 != limit2) return NO;
	for (i = 0; i < limit1; i++)
		if (_data[ngram1->pos - i] != data[ngram2->pos - i]) return NO;
	return YES;
}

- (unsigned)count {
	return count;
}

@end
