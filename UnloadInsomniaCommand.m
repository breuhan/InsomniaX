//
//  LoadInsomniaCommand.m
//  InsomniaX
//
//  Created by Andrew James on 9/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "UnloadInsomniaCommand.h"


@implementation UnloadInsomniaCommand : NSScriptCommand

//NSScriptCommand override
- (id)performDefaultImplementation
{
	[[NSApp delegate] insomniaLoad:NO];
	
	return nil;
}


@end
