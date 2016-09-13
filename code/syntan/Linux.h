#import <Foundation/Foundation.h>

@interface NSString (Linux)

+ (id)stringWithContentsOfFile:(NSString *)path encoding:(NSStringEncoding)enc error:(NSError **)error;

@end
