/*
 *  getpath.c
 *  SleepLess
 *
 *  Created by Alexey Mananikov on 28.12.04.
 *  Copyright 2004 __MyCompanyName__. All rights reserved.
 *
 */

#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <sys/param.h>
#include <stdlib.h>
#include <crt_externs.h>
#include <errno.h>
#include <mach-o/dyld.h>

typedef int (*NSGetExecutablePathProcPtr)(char *buf, size_t *bufsize);


int
MyGetExecutablePath(char *execPath, size_t *execPathSize)
{
    if (NSIsSymbolNameDefined("__NSGetExecutablePath"))
    {
        return ((NSGetExecutablePathProcPtr) NSAddressOfSymbol(NSLookupAndBindSymbol("__NSGetExecutablePath")))(execPath, execPathSize);
    }
	return(0);
}