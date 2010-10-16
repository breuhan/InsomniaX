//
//  LoadInsomniaCommand.m
//  InsomniaX
//
//  Created by Andrew James on 9/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "LoadInsomniaCommand.h"


@implementation LoadInsomniaCommand : NSScriptCommand

//NSScriptCommand override
- (id)performDefaultImplementation
{
	[[NSApp delegate] insomniaLoad:YES];
	
	return nil;
}


@end
