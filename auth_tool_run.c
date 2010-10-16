/*
 *  auth_tool_run.c
 *  SleepLess
 *
 *  Created by Alexey Mananikov on 28.12.04.
 *  Copyright 2004 __MyCompanyName__. All rights reserved.
 *
 */
#include "authtool.h"

#include <Security/AuthorizationTags.h>
#include <CoreFoundation/CoreFoundation.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/wait.h>

//extern void showError_loader(void);

AuthorizationRef authorizationRef;
MyAuthorizedCommand myCommand;

static bool
pathForTool(CFStringRef toolName, char path[MAXPATHLEN])
{
    CFBundleRef bundle;
    CFURLRef resources;
    CFURLRef toolURL;
    Boolean success = true;
    
    bundle = CFBundleGetMainBundle();
    if (!bundle)
        return FALSE;
    
    resources = CFBundleCopyResourcesDirectoryURL(bundle);
    if (!resources)
        return FALSE;
    
    toolURL = CFURLCreateCopyAppendingPathComponent(NULL, resources, toolName, FALSE);
    CFRelease(resources);
    if (!toolURL)
        return FALSE;
    
    success = CFURLGetFileSystemRepresentation(toolURL, TRUE, (UInt8 *)path, MAXPATHLEN);
    
    CFRelease(toolURL);
    return !access(path, X_OK);
}




/* Return one of our defined error codes. */
static int
performCommand(AuthorizationRef authorizationRef, MyAuthorizedCommand myCommand)
{
    char path[MAXPATHLEN];
    int comms[2] = {};
    int childStatus = 0;
    int written;
    pid_t pid;
	
    AuthorizationExternalForm extAuth;
	
	if(myDebug) fprintf(stderr, "searching authtool\n");
	
    if (!pathForTool(CFSTR("loader"), path))
    {
        /* The tool could disappear from inside the application's package if a user tries to copy the
		 application.  Currently, the Finder will complain that it doesn't have permission to copy the
		 tool and if the user decides to go ahead with the copy, the application gets copied without
		 the tool inside.  At this point, you should recommend that the user re-install the application. */
        
        if(myDebug) fprintf(stderr, "The authtool could not be found.\n");
        
		//showError_loader();
		
		return kMyAuthorizedCommandInternalError;
    }
    if(myDebug) fprintf(stderr, "authtool found.\n");
	
    /* Turn an AuthorizationRef into an external "byte blob" form so it can be transmitted to the authtool. */
    if (AuthorizationMakeExternalForm(authorizationRef, &extAuth))
        return kMyAuthorizedCommandInternalError;
	
	if(myDebug) fprintf(stderr, "AuthorizationMakeExternalForm done.\n");
    
	/* Create a descriptor pair for interprocess communication. */
    if (pipe(comms))
        return kMyAuthorizedCommandInternalError;
	
	if(myDebug) fprintf(stderr, "pipe done.\n");
	
    switch(pid = fork())
    {
        case 0:	/* Child */
        {            
            char *const envp[] = { NULL };
			
            dup2(comms[0], 0);
            close(comms[0]);
            close(comms[1]);
            execle(path, path, NULL, envp);
            _exit(1);
        }
        case -1: /* an error occured */
            close(comms[0]);
            close(comms[1]);
            return kMyAuthorizedCommandInternalError;
        default: /* Parent */
            break;
    }
	
	if(myDebug) fprintf(stderr, "child done.\n");
	
    /* Parent */
    /* Don't abort the program if write fails. */
    signal(SIGPIPE, SIG_IGN);
    
    /* Close input pipe since we are not reading from client. */
    close(comms[0]);
	
	
    if(myDebug) fprintf(stderr, "Passing child externalized authref.\n");
	
    /* Write the ExternalizedAuthorization to our output pipe. */
    if (write(comms[1], &extAuth, sizeof(extAuth)) != sizeof(extAuth))
    {
        close(comms[1]);
        return kMyAuthorizedCommandInternalError;
    }
	
	if(myDebug) fprintf(stderr, "write done.\n");
	
    if(myDebug) fprintf(stderr, "Passing child command.\n");
	
    /* Write the commands we want to execute to our output pipe */
    written = write(comms[1], &myCommand, sizeof(MyAuthorizedCommand));
    
    /* Close output pipe to notify client we are done. */
    close(comms[1]);
    
    if (written != sizeof(MyAuthorizedCommand))
        return kMyAuthorizedCommandInternalError;
	
	if(myDebug) fprintf(stderr, "written != command done.\n");
	
    /* Wait for the tool to return */
    if (waitpid(pid, &childStatus, 0) != pid)
        return kMyAuthorizedCommandInternalError;
	
	
	if(myDebug) fprintf(stderr, "waitpid done.\n");
	
    if (!WIFEXITED(childStatus))
        return kMyAuthorizedCommandInternalError;
    
	if(myDebug) fprintf(stderr, "wifexited done.\n");
	
	
	
    return WEXITSTATUS(childStatus);
}

int myPerformAuthCommand(UInt16	what, char	*file)
{
	OSStatus status;
	
	myCommand.authorizedCommandId = what;
	
	strcpy(myCommand.file, file);
	
    
	status = performCommand(authorizationRef, myCommand);
	if(myDebug) fprintf(stderr, "Performing the command returned %ld.\n", status);
	
	return(status);
}

int myFreeAuthCommand(void)
{
	AuthorizationFree(authorizationRef, kAuthorizationFlagDestroyRights);
	
	return(0);
}

int myInitAuthCommand(void)
{
    
	// AuthorizationItem right = { "com.alxsoft.iCooked.loader", 0, NULL, 0 };
    //AuthorizationRights rightSet = { 1, &right };
    OSStatus status;
    
    //AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagPreAuthorize
	//     | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;
	
	
    /* Create a new authorization reference which will later be passed to the tool. */
    
    status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef);
	
    if (status != errAuthorizationSuccess)
    {
        if(myDebug) fprintf(stderr, "Failed to create the authref: %ld.\n", status);
        return kMyAuthorizedCommandInternalError;
    }
    
    /* This shows how AuthorizationCopyRights() can be used in order to pre-authorize the user before
	 attempting to perform the privileged operation.  Pre-authorization is optional but can be useful in
	 certain situations.  For example, in the Installer application, the user is asked to pre-authorize before
	 configuring the installation because it would be a waste of time to let the user proceed through the
	 entire installation setup, only to be denied at the final stage because they weren't the administrator. */
    
	// status = AuthorizationCopyRights(authorizationRef, &rightSet, kAuthorizationEmptyEnvironment, flags, NULL);
    status = errAuthorizationSuccess;
	
    if (status == errAuthorizationSuccess)
    {
        
		
        
        /* Specifying the kAuthorizationFlagDestroyRights causes the granted rights to be destroyed so
		 they can't be shared between sessions and used again.  Rights will automatically timeout by default
		 after 5 minutes, but the timeout value can be changed by editing the file located at /etc/authorization. 
		 The config file gives System Administrators the ability to enforce a stricter security policy, and it's
		 recommended that you test with a zero second timeout enabled to make sure your application continues
		 to behave as expected. */
        
        //AuthorizationFree(authorizationRef, kAuthorizationFlagDestroyRights);
    }
    else
    {
        if(myDebug) fprintf(stderr, "Pre-authorization failed, giving up.\n");
        return kMyAuthorizedCommandInternalError;
    }
    
    return 0;
}