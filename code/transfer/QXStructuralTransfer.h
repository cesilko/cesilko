//
//  QXStructuralTransfer.h
//  CzSk
//
//  Created by Petr Homola on 21.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QXStructuralTransfer : NSObject {
	//NSMutableDictionary* featureStructures;
}

- (void)transfer:(NSMutableDictionary*)head child:(NSMutableDictionary*)child result:(NSMutableArray*)result attribute:(NSString*)attName;
- (void)preprocess:(NSMutableDictionary*)dict result:(NSMutableArray*)result; // parent:(NSMutableDictionary*)parent;
//- (NSMutableDictionary*)featureStructures;
+ (void)setTargetLanguage:(NSString*)lang;
+ (NSString*)targetLanguage;

@end
