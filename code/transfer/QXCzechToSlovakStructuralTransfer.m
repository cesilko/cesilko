//
//  QXCzechToSlovakStructuralTransfer.m
//  CzSk
//
//  Created by Petr Homola on 21.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QXCzechToSlovakStructuralTransfer.h"

@implementation QXCzechToSlovakStructuralTransfer
/*- (void)transfer:(NSMutableDictionary*)head child:(NSMutableDictionary*)child result:(NSMutableArray*)result attribute:(NSString*)attName {
	//NSString* pos1 = [head objectForKey: @"pos"];
	//NSString* pos2 = [child objectForKey: @"pos"];
	[result addObject: child];
	[result addObject: head];
}

- (void)preprocess:(NSMutableDictionary*)dict result:(NSMutableArray*)result {
	//NSString* pos = [dict objectForKey: @"pos"];
	NSString* lemma = [dict objectForKey: @"lemma"];
	NSString* tags = [dict objectForKey: @"tags"];
	
	if ([lemma isEqual: @"rok"] && [[dict objectForKey: @"gender"] isEqual: @"neut"]) {
		NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
		[head setObject: @"1" forKey: @"preproctr"];
		NSMutableString* tags2 = [NSMutableString stringWithString: tags];
		[tags2 replaceCharactersInRange: NSMakeRange(1, 1) withString: @"I"];
		[head setObject: tags2 forKey: @"tags"];
		[result addObject: head];
	}
	
	if ([result count] == 0) {
		NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
		[head setObject: @"1" forKey: @"preproctr"];
		[result addObject: head];
	}
}*/
@end
