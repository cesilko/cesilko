//
//  CSCzechToXStructuralTransfer.m
//  transfer
//
//  Created by Petr Homola on 14.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CSCzechToXStructuralTransfer.h"
#import "QX_Transfer.h"

@implementation CSCzechToXStructuralTransfer

- (void)transfer:(NSMutableDictionary*)head child:(NSMutableDictionary*)child result:(NSMutableArray*)result attribute:(NSString*)attName {
	NSString* pos1 = [head objectForKey: @"pos"];
	NSString* pos2 = [child objectForKey: @"pos"];
	NSString* prontype = [child objectForKey: @"prontype"];
	
	// adapting case, gender and number of an agreeing adjective, article and pronoun (recursively)
	if ([pos1 isEqual: @"n"] && ([pos2 isEqual: @"art"] || [pos2 isEqual: @"a"] || [pos2 isEqual: @"pron"] && ([prontype isEqual: @"dem"] || [prontype isEqual: @"poss"]))) {
		NSString* gender = [head objectForKey: @"gender"];
		NSString* number = [head objectForKey: @"number"];
		NSString* cas = [head objectForKey: @"case"];
		NSString* def = [head objectForKey: @"def"];
		id son = child;
		while (son != nil) {
			[son setObject: gender forKey: @"gender"];
			if (number != nil) [son setObject: number forKey: @"number"];
			[son setObject: cas forKey: @"case"];
			if (def != nil) [son setObject: def forKey: @"def"];
			son = [son objectForKey: @"tail"];
		}
		[result addObject: child];
		[result addObject: head];
	} else
	// adapting gender and number of a verb according to its subject
	if ([pos1 isEqual: @"verb"] && [attName isEqual: @"subj"]) {
		//NSLog(@"##### SUBJ");
		[child setObject: @"subj" forKey: @"gramfunc"];
		BOOL done;
		NSArray* childResult = [child transfer: YES done: &done];
		NSEnumerator* enumerator = [childResult objectEnumerator];
		NSMutableDictionary* transferredChild; unsigned order = 0;
		while (transferredChild = [enumerator nextObject]) {
		  NSString* gramfunc = [transferredChild objectForKey: @"gramfunc"];
		  if (gramfunc && [gramfunc isEqual: @"subj"]) {
			NSMutableDictionary* newHead = [NSMutableDictionary dictionaryWithDictionary: head];
			NSString* gender = [transferredChild objectForKey: @"gender"];
			[newHead setObject: gender forKey: @"gender"];
			NSString* headLeft = [newHead objectForKey: @"left"];
			NSString* headRight = [newHead objectForKey: @"right"];
			NSString* childLeft = [transferredChild objectForKey: @"left"];
			NSString* childRight = [transferredChild objectForKey: @"right"];
			if ([childRight isEqual: headLeft]) {
				NSString* nodeLabel = [childRight stringByAppendingFormat: @"-%u", ++order];
				[transferredChild setObject: nodeLabel forKey: @"right"];
				[newHead setObject: nodeLabel forKey: @"left"];
			} else if ([childLeft isEqual: headRight]) {
				NSString* nodeLabel = [childLeft stringByAppendingFormat: @"-%u", ++order];
				[transferredChild setObject: nodeLabel forKey: @"left"];
				[newHead setObject: nodeLabel forKey: @"right"];
			} //else NSLog(@"##### %@", [transferredChild objectForKey: @"lemma"]);
			[transferredChild setObject: @"1" forKey: @"trdone"];
			[result addObject: newHead];
		  }
		  [result addObject: transferredChild];
		} /**/
	} else
	if ([[QXStructuralTransfer targetLanguage] isEqual: @"de"] && [attName isEqual: @"nom-pred-n"]) { // nominal predicate -> nom
		[child setObject: @"nom" forKey: @"case"];
		[result addObject: child];
		[result addObject: head];
	} else {
		[result addObject: child];
		[result addObject: head];
	}
}

- (void)preprocess:(NSMutableDictionary*)dict result:(NSMutableArray*)result { //parent:(NSMutableDictionary*)parent {
	NSString* pos = [dict objectForKey: @"pos"];
	NSString* lemma = [dict objectForKey: @"lemma"];
	NSString* tags = [dict objectForKey: @"tags"];
	NSDictionary* prep = [dict objectForKey: @"prep"];
	NSString* degree = [dict objectForKey: @"degree"];
	NSString* vform = [dict objectForKey: @"vform"];
	NSString* tense = [dict objectForKey: @"tense"];
	NSString* subj = [dict objectForKey: @"subj"];
	
	// universal
	
	// for Russian
	
	if ([[QXStructuralTransfer targetLanguage] isEqual: @"ru"]) {
	
	if ([pos isEqual: @"n"] && prep != nil && [prep isKindOfClass: [NSDictionary class]]) { // adapting case of an NP according to its preposition
		NSString* cas =
			[[prep objectForKey: @"lemma"] isEqual: @"do-1"] && [[prep objectForKey: @"case"] isEqual: @"gen"] ? @"acc" :
			nil;
		//NSLog(@"##### %@ %@", cas, dict);
		if (cas != nil)  {
			NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
			[head setObject: cas forKey: @"case"];
			[head setObject: @"1" forKey: @"preproctr"];
			[result addObject: head];
		}
	}
	if ([pos isEqual: @"verb"] && [vform isEqual: @"fin"] && [tense isEqual: @"pres"]) {
		if ([lemma isEqual: @"быть"]) { // adapting aux 'být'
		  if (![dict objectForKey: @"subj"]) {
			NSString* person = [dict objectForKey: @"person"];
			NSString* number = [dict objectForKey: @"number"];
			NSString* lemma;
			if ([number isEqual: @"sg"]) {
				if ([person isEqual: @"1"]) lemma = @"я";
				if ([person isEqual: @"2"]) lemma = @"ты";
				if ([person isEqual: @"3"]) lemma = @"он";
			} else {
				if ([person isEqual: @"1"]) lemma = @"мы";
				if ([person isEqual: @"2"]) lemma = @"вы";
				if ([person isEqual: @"3"]) lemma = @"они";
			}
			NSMutableDictionary* head = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				lemma, @"lemma", @"nom", @"case", [dict objectForKey: @"order"], @"order",
				[dict objectForKey: @"left"], @"left",  [dict objectForKey: @"right"], @"right",
				@"pron", @"pos", @"pres", @"prontype", @"1", @"lextr", @"1", @"lextr_dict", nil];
			[head setObject: @"1" forKey: @"preproctr"];
			[result addObject: head];
		  }
		} else {
			NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
			[head removeObjectForKey: @"tense"];
			[head setObject: @"1" forKey: @"preproctr"];
			[result addObject: head];
		}
	}
	if ([pos isEqual: @"a"] && [degree isEqual: @"3"]) { // superlative - adding самый
		NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
		NSString* gender = [head objectForKey: @"gender"];
		NSString* number = [head objectForKey: @"number"];
		NSString* cas = [head objectForKey: @"case"];
		NSMutableDictionary* child = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"самый", @"lemma", gender, @"gender", number, @"number", cas, @"case", @"0", @"order",
			@"pron", @"pos", @"dem", @"prontype", @"1", @"lextr", @"1", @"lextr_dict", nil];
		[head setObject: child forKey: @"adj-sup"];
		[head setObject: @"1" forKey: @"preproctr"];
		[result addObject: head];
	}
	
	}
	
	// for German
	
	if ([[QXStructuralTransfer targetLanguage] isEqual: @"de"]) {
		
		if ([pos isEqual: @"n"] && prep != nil && [prep isKindOfClass: [NSDictionary class]]) { // adapting case of an NP according to its preposition
			NSString* cas =
				[[prep objectForKey: @"lemma"] isEqual: @"mezi-1"] && [[prep objectForKey: @"case"] isEqual: @"ins"] ? @"dat" :
				[[prep objectForKey: @"lemma"] isEqual: @"kvůli"] && [[prep objectForKey: @"case"] isEqual: @"dat"] ? @"gen" :
				nil;
			NSLog(@"##### %@ %@", lemma, cas);
			if (cas != nil)  {
				NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
				[head setObject: cas forKey: @"case"];
				[head setObject: @"1" forKey: @"preproctr"];
				[result addObject: head];
			}
		}
		if ([pos isEqual: @"verb"] && [vform isEqual: @"fin"] && subj == nil) { // adding missing subject
			NSString* person = [dict objectForKey: @"person"];
			NSString* number = [dict objectForKey: @"number"];
			NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
			id headOrder = [head objectForKey: @"order"];
			id childOrder = [NSNumber numberWithFloat: [[headOrder description] intValue] - 0.1];
			NSMutableDictionary* child = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				person, @"person", number, @"number", @"nom", @"case", @"masca", @"gender", // !!!
				[childOrder description], @"order", @"pron", @"pos", @"pers", @"prontype",
				@"1", @"lextr", @"1", @"lextr_dict", nil];
			if ([person isEqual: @"1"] && [number isEqual: @"sg"]) [child setObject: @"ich" forKey: @"lemma"];
			if ([person isEqual: @"1"] && [number isEqual: @"pl"]) [child setObject: @"wir" forKey: @"lemma"];
			[head setObject: child forKey: @"subj"];
			[result addObject: head];
		}
		if (lemma != nil) {
			NSRange range = [lemma rangeOfString: @"+"]; // separable prefixes
			if (range.location != NSNotFound) {
				//NSLog(@"########## %@", lemma);
				NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
				[head setObject: @"1" forKey: @"preproctr"];
				[head setObject: [lemma substringFromIndex: range.location + 1] forKey: @"lemma"];
				id headOrder = [head objectForKey: @"order"];
				id childOrder = [NSNumber numberWithFloat: [[headOrder description] intValue] - 0.1];
				//NSLog(@"########## %@ %@", [childOrder className], childOrder);
				NSMutableDictionary* child = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					[[lemma substringToIndex: range.location] stringByAppendingString: @"≈≈"], @"lemma",
					[childOrder description], @"order", @"prep", @"pos",
					@"1", @"lextr", @"1", @"lextr_dict", nil];
				[head setObject: child forKey: @"sep-pref"];
				[result addObject: head];
			}
		} //else NSLog(@"########## %@", dict);

		if ([pos isEqual: @"n"] && [dict objectForKey: @"def"] == nil) { // adding definite article
			NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
			[head setObject: @"1" forKey: @"preproctr"];
			NSString* childOrder = @"0";
			NSDictionary* prep = [dict objectForKey: @"prep"];
			if (prep != nil) {
				id prepOrder = [prep objectForKey: @"order"];
				childOrder = [[NSNumber numberWithFloat: [[prepOrder description] intValue] + 0.1] description];
			}
			NSMutableDictionary* child = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				@"der", @"lemma", childOrder, @"order", @"art", @"pos",
										  [dict objectForKey: @"gender"], @"gender",
										  [dict objectForKey: @"case"], @"case",
										  [dict objectForKey: @"number"], @"number",
				@"1", @"lextr", @"1", @"lextr_dict", nil];
			[head setObject: child forKey: @"art"];
			[head setObject: @"def" forKey: @"def"];
			[result addObject: head];
		}
		
	}
	
	// for Slovak
	
	if ([[QXStructuralTransfer targetLanguage] isEqual: @"sk"]) {
	
	if ([lemma isEqual: @"rok"] && [[dict objectForKey: @"gender"] isEqual: @"neut"]) {
		NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
		[head setObject: @"1" forKey: @"preproctr"];
		NSMutableString* tags2 = [NSMutableString stringWithString: tags];
		[tags2 replaceCharactersInRange: NSMakeRange(1, 1) withString: @"I"];
		[head setObject: tags2 forKey: @"tags"];
		[result addObject: head];
	}
	
	}
	
	if ([result count] == 0) {
		NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
		[head setObject: @"1" forKey: @"preproctr"];
		[result addObject: head];
	}
}

@end
