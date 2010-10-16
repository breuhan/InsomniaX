//
//  NSApplicationPlus.h
//  detectPowerApp
//
//  Created by powerbookg4 on 23.06.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <CoreFoundation/CoreFoundation.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#include <IOKit/pwr_mgt/IOPM.h>
#include <IOKit/ps/IOPowerSources.h>

#import <IOKit/ps/IOPSKeys.h>
#import <Carbon/Carbon.h>


@interface NSApplicationPlus : NSApplication {}
- (void)powerSourceChanged;


@end
