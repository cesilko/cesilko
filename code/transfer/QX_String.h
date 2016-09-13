//
//  QX_String.h
//

#import <Foundation/Foundation.h>

@interface NSString (QXString)

- (NSString*)trim;
- (NSArray*)split;
- (NSArray*)splitBy:(NSCharacterSet*)separators;
- (NSArray*)splitBy:(NSCharacterSet*)separators keepSeparators:(BOOL)keepSeparators;
- (NSArray*)tokenize;
- (NSArray*)tokenizeHomogenous:(BOOL)homogenous;
+ (NSString*)stringWithArray:(NSArray*)array;
+ (NSString*)stringWithArray:(NSArray*)array omit:(NSString*)omit;
- (NSString*)capitalize;
- (NSString*)decapitalize;
- (NSString*)lowercaseAndCapitalized;
- (NSString*)plainAsciiString;
- (BOOL)isInteger;
+ (NSString*)completize:(NSArray*)array;

@end

@interface NSMutableString (QXString)

- (unsigned)_replaceOccurrencesOfString:(NSString*)target withString:(NSString*)replacement options:(unsigned)opts range:(NSRange)searchRange;

@end
