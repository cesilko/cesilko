#import <Foundation/Foundation.h>

@interface NSDictionary (QXUnification)

- (NSDictionary*)unifyWith:(NSDictionary*)dict;
- (BOOL)isBound:(id)object;
- (BOOL)isFree:(id)object;
+ (NSDictionary*)dictionaryWithArray:(NSArray*)list;
- (NSSet*)signature;
- (NSString*)safeDescription;

@end
