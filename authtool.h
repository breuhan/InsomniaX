/*
 *  authtool.h
 *  SleepLess
 *
 *  Created by Alexey Mananikov on 28.12.04.
 *  Copyright 2004 __MyCompanyName__. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>

#include <Security/Authorization.h>
#include <sys/param.h>



// Command Ids
enum
{
    kMyAuthorizedLoad = 1,
    kMyAuthorizedUnload = 2,
	kMyAuthorizedHibernateInstant = 3,
	kMyAuthorizedHibernateNormal = 4,
	kMyAuthorizedHibernateDisable = 5,
	kMyAuthorizedHibernateInstall = 6
};



// Command structure
typedef struct MyAuthorizedCommand
{
    int authorizedCommandId;
	
    char file[1024];
	
} MyAuthorizedCommand;



// Exit codes (positive values) and return codes from exec function
enum
{
    kMyAuthorizedCommandInternalError = -1,
    kMyAuthorizedCommandSuccess = 0,
    kMyAuthorizedCommandExecFailed,
    kMyAuthorizedCommandChildError,
    kMyAuthorizedCommandAuthFailed,
    kMyAuthorizedCommandOperationFailed
};

int myDebug=1;
