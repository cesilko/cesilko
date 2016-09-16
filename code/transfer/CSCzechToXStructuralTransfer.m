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
	NSString* pos1 = head[@"pos"];
	NSString* pos2 = child[@"pos"];
	NSString* prontype = child[@"prontype"];
	
	// adapting case, gender and number of an agreeing adjective, article and pronoun (recursively)
	if ([pos1 isEqual: @"n"] && ([pos2 isEqual: @"art"] || [pos2 isEqual: @"a"] || [pos2 isEqual: @"pron"] && ([prontype isEqual: @"dem"] || [prontype isEqual: @"poss"]))) {
		NSString* gender = head[@"gender"];
		NSString* number = head[@"number"];
		NSString* cas = head[@"case"];
		NSString* def = head[@"def"];
		id son = child;
		while (son != nil) {
			son[@"gender"] = gender;
			if (number != nil) son[@"number"] = number;
			son[@"case"] = cas;
			if (def != nil) son[@"def"] = def;
			son = son[@"tail"];
		}
		[result addObject: child];
		[result addObject: head];
	} else
	// adapting gender and number of a verb according to its subject
	if ([pos1 isEqual: @"verb"] && [attName isEqual: @"subj"]) {
		//NSLog(@"##### SUBJ");
		child[@"gramfunc"] = @"subj";
		BOOL done;
		NSArray* childResult = [child transfer: YES done: &done];
		NSEnumerator* enumerator = [childResult objectEnumerator];
		NSMutableDictionary* transferredChild; unsigned order = 0;
		while (transferredChild = [enumerator nextObject]) {
		  NSString* gramfunc = transferredChild[@"gramfunc"];
		  if (gramfunc && [gramfunc isEqual: @"subj"]) {
			NSMutableDictionary* newHead = [NSMutableDictionary dictionaryWithDictionary: head];
			NSString* gender = transferredChild[@"gender"];
			newHead[@"gender"] = gender;
			NSString* headLeft = newHead[@"left"];
			NSString* headRight = newHead[@"right"];
			NSString* childLeft = transferredChild[@"left"];
			NSString* childRight = transferredChild[@"right"];
			if ([childRight isEqual: headLeft]) {
				NSString* nodeLabel = [childRight stringByAppendingFormat: @"-%u", ++order];
				transferredChild[@"right"] = nodeLabel;
				newHead[@"left"] = nodeLabel;
			} else if ([childLeft isEqual: headRight]) {
				NSString* nodeLabel = [childLeft stringByAppendingFormat: @"-%u", ++order];
				transferredChild[@"left"] = nodeLabel;
				newHead[@"right"] = nodeLabel;
			} //else NSLog(@"##### %@", [transferredChild objectForKey: @"lemma"]);
			transferredChild[@"trdone"] = @"1";
			[result addObject: newHead];
		  }
		  [result addObject: transferredChild];
		} /**/
	} else
	if ([[QXStructuralTransfer targetLanguage] isEqual: @"de"] && [attName isEqual: @"nom-pred-n"]) { // nominal predicate -> nom
		child[@"case"] = @"nom";
		[result addObject: child];
		[result addObject: head];
	} else {
		[result addObject: child];
		[result addObject: head];
	}
}

- (void)preprocess:(NSMutableDictionary*)dict result:(NSMutableArray*)result { //parent:(NSMutableDictionary*)parent {
	NSString* pos = dict[@"pos"];
	NSString* lemma = dict[@"lemma"];
	NSString* tags = dict[@"tags"];
	NSDictionary* prep = dict[@"prep"];
	NSString* degree = dict[@"degree"];
	NSString* vform = dict[@"vform"];
	NSString* tense = dict[@"tense"];
	NSString* subj = dict[@"subj"];
	
	// universal
	
	// for Russian
	
	if ([[QXStructuralTransfer targetLanguage] isEqual: @"ru"]) {
	
	if ([pos isEqual: @"n"] && prep != nil && [prep isKindOfClass: [NSDictionary class]]) { // adapting case of an NP according to its preposition
		NSString* cas =
			[prep[@"lemma"] isEqual: @"do-1"] && [prep[@"case"] isEqual: @"gen"] ? @"acc" :
			nil;
		//NSLog(@"##### %@ %@", cas, dict);
		if (cas != nil)  {
			NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
			head[@"case"] = cas;
			head[@"preproctr"] = @"1";
			[result addObject: head];
		}
	}
	if ([pos isEqual: @"verb"] && [vform isEqual: @"fin"] && [tense isEqual: @"pres"]) {
		if ([lemma isEqual: @"быть"]) { // adapting aux 'být'
		  if (!dict[@"subj"]) {
			NSString* person = dict[@"person"];
			NSString* number = dict[@"number"];
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
				lemma, @"lemma", @"nom", @"case", dict[@"order"], @"order",
				dict[@"left"], @"left",  dict[@"right"], @"right",
				@"pron", @"pos", @"pres", @"prontype", @"1", @"lextr", @"1", @"lextr_dict", nil];
			head[@"preproctr"] = @"1";
			[result addObject: head];
		  }
		} else {
			NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
			[head removeObjectForKey: @"tense"];
			head[@"preproctr"] = @"1";
			[result addObject: head];
		}
	}
	if ([pos isEqual: @"a"] && [degree isEqual: @"3"]) { // superlative - adding самый
		NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
		NSString* gender = head[@"gender"];
		NSString* number = head[@"number"];
		NSString* cas = head[@"case"];
		NSMutableDictionary* child = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"самый", @"lemma", gender, @"gender", number, @"number", cas, @"case", @"0", @"order",
			@"pron", @"pos", @"dem", @"prontype", @"1", @"lextr", @"1", @"lextr_dict", nil];
		head[@"adj-sup"] = child;
		head[@"preproctr"] = @"1";
		[result addObject: head];
	}
	
	}
	
	// for German
	
	if ([[QXStructuralTransfer targetLanguage] isEqual: @"de"]) {
		
		if ([pos isEqual: @"n"] && prep != nil && [prep isKindOfClass: [NSDictionary class]]) { // adapting case of an NP according to its preposition
			NSString* cas =
				[prep[@"lemma"] isEqual: @"mezi-1"] && [prep[@"case"] isEqual: @"ins"] ? @"dat" :
				[prep[@"lemma"] isEqual: @"kvůli"] && [prep[@"case"] isEqual: @"dat"] ? @"gen" :
				nil;
			NSLog(@"##### %@ %@", lemma, cas);
			if (cas != nil)  {
				NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
				head[@"case"] = cas;
				head[@"preproctr"] = @"1";
				[result addObject: head];
			}
		}
		if ([pos isEqual: @"verb"] && [vform isEqual: @"fin"] && subj == nil) { // adding missing subject
			NSString* person = dict[@"person"];
			NSString* number = dict[@"number"];
			NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
			id headOrder = head[@"order"];
			id childOrder = [NSNumber numberWithFloat: [headOrder description].intValue - 0.1];
			NSMutableDictionary* child = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				person, @"person", number, @"number", @"nom", @"case", @"masca", @"gender", // !!!
				[childOrder description], @"order", @"pron", @"pos", @"pers", @"prontype",
				@"1", @"lextr", @"1", @"lextr_dict", nil];
			if ([person isEqual: @"1"] && [number isEqual: @"sg"]) child[@"lemma"] = @"ich";
			if ([person isEqual: @"1"] && [number isEqual: @"pl"]) child[@"lemma"] = @"wir";
			head[@"subj"] = child;
			[result addObject: head];
		}
		if (lemma != nil) {
			NSRange range = [lemma rangeOfString: @"+"]; // separable prefixes
			if (range.location != NSNotFound) {
				//NSLog(@"########## %@", lemma);
				NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
				head[@"preproctr"] = @"1";
				head[@"lemma"] = [lemma substringFromIndex: range.location + 1];
				id headOrder = head[@"order"];
				id childOrder = [NSNumber numberWithFloat: [headOrder description].intValue - 0.1];
				//NSLog(@"########## %@ %@", [childOrder className], childOrder);
				NSMutableDictionary* child = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					[[lemma substringToIndex: range.location] stringByAppendingString: @"≈≈"], @"lemma",
					[childOrder description], @"order", @"prep", @"pos",
					@"1", @"lextr", @"1", @"lextr_dict", nil];
				head[@"sep-pref"] = child;
				[result addObject: head];
			}
		} //else NSLog(@"########## %@", dict);

		if ([pos isEqual: @"n"] && dict[@"def"] == nil) { // adding definite article
			NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
			head[@"preproctr"] = @"1";
			NSString* childOrder = @"0";
			NSDictionary* prep = dict[@"prep"];
			if (prep != nil) {
				id prepOrder = prep[@"order"];
				childOrder = [NSNumber numberWithFloat: [prepOrder description].intValue + 0.1].description;
			}
			NSMutableDictionary* child = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				@"der", @"lemma", childOrder, @"order", @"art", @"pos",
										  dict[@"gender"], @"gender",
										  dict[@"case"], @"case",
										  dict[@"number"], @"number",
				@"1", @"lextr", @"1", @"lextr_dict", nil];
			head[@"art"] = child;
			head[@"def"] = @"def";
			[result addObject: head];
		}
		
	}
	
	// for Slovak
	
	if ([[QXStructuralTransfer targetLanguage] isEqual: @"sk"]) {
	
	if ([lemma isEqual: @"rok"] && [dict[@"gender"] isEqual: @"neut"]) {
		NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
		head[@"preproctr"] = @"1";
		NSMutableString* tags2 = [NSMutableString stringWithString: tags];
		[tags2 replaceCharactersInRange: NSMakeRange(1, 1) withString: @"I"];
		head[@"tags"] = tags2;
		[result addObject: head];
	}
	
	}
	
	if (result.count == 0) {
		NSMutableDictionary* head = [NSMutableDictionary dictionaryWithDictionary: dict];
		head[@"preproctr"] = @"1";
		[result addObject: head];
	}
}

@end
