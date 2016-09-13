#import <Foundation/Foundation.h>

@interface QXVariable : NSObject {
	NSString* name;
}

- (void)setValue:(id)value;
- (id)getValue;
+ (QXVariable*)immediatePointer:(QXVariable*)variable;
- (id)initWithName:(NSString*)_name;
+ (id)variableWithName:(NSString*)_name;
- (NSString*)name;
- (BOOL)isFree;
- (void)bind:(QXVariable*)variable;
+ (void)clear;
+ (unsigned)count;

@end
