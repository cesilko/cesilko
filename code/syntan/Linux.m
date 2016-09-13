#import "Linux.h"

@implementation NSString (Linux)

+ (id)stringWithContentsOfFile:(NSString *)path encoding:(NSStringEncoding)enc error:(NSError **)error {
	NSData* data = [NSData dataWithContentsOfFile: path];
	NSString* string = [[[NSString alloc] initWithData: data encoding: enc] autorelease];
	*error = nil;
	return string;
}

@end
