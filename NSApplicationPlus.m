//
//  NSApplicationPlus.m
//  detectPowerApp
//
//  Created by powerbookg4 on 23.06.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSApplicationPlus.h"

io_connect_t  root_port;
static NSApplicationPlus *me;

void callbackPwr(void *in){
	[me powerSourceChanged];
}

@implementation NSApplicationPlus

- (id) init {
	self = [super init];
	if (self != nil) {
		me = self;
		CFRunLoopSourceRef maSource = NULL;
		maSource = IOPSNotificationCreateRunLoopSource(callbackPwr, NULL);
		CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop],maSource,kCFRunLoopDefaultMode);
		CFRelease(maSource);
	}
	return self;
}


- (void)powerSourceChanged{

	CFTypeRef sourcesInfo = IOPSCopyPowerSourcesInfo();
	NSString* sourcesDesc = (NSString *)IOPSGetProvidingPowerSourceType(sourcesInfo);
	CFRelease(sourcesInfo);
	if (sourcesDesc == nil) sourcesDesc = @"Error";
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSDictionary *userDict = [NSDictionary dictionaryWithObject:sourcesDesc forKey:@"powerSourceState"];
	[nc postNotification:[NSNotification notificationWithName:@"powerSourceChanged" object:self userInfo:userDict]];
}


- (void) dealloc {
	[super dealloc];
}




@end
