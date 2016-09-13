//
//  QXLexicalTransfer.h
//  CzSk
//
//  Created by Petr Homola on 21.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QXLexicalTransfer : NSObject {
}
- (id)initWithFile:(NSString*)fileName;
- (void)transfer:(NSDictionary*)source result:(NSMutableArray*)result;
+ (void)log:(NSString*)message;
+ (NSArray*)messages;
+ (void)addUnknownLemma:(NSString*)lemma;
+ (NSSet*)unknownLemmas;
@end
