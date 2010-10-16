/*
 *  authtool.c
 *  SleepLess
 *
 *  Created by Alexey Manannikov on 28.12.04.
 *  Removed some commands so if leaked alexey is safer
 *  Copyright 2004 __MyCompanyName__. All rights reserved.
 *
 */

#include "authtool.h"

#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <sys/fcntl.h>
#include <sys/errno.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <mach-o/dyld.h>


extern int MyGetExecutablePath(char *execPath, size_t *execPathSize);


/* Return the name of the right to verify for the operation specified in myCommand. */

/*static const char *
 rightNameForCommand(const MyAuthorizedCommand * myCommand)
 {
 switch (myCommand->authorizedCommandId)
 {
 case kMyAuthorizedCommandOperation1:
 return "com.alxsoft.SleepLess.loader";
 // case kMyAuthorizedCommandOperation2:
 //    return "com.mycompany.myapplication.command2";
 }
 return "system.unknown";
 }
 
 */


/* Perform the operation specified in myCommand. */
/* Perform the operation specified in myCommand. */
static int
performOperation(const MyAuthorizedCommand * myCommand)
{
	//char commandToExec[255];
	int result = -1;
	pid_t	pid;
	if(myDebug) fprintf(stderr, "Tool performing command %d.\n", myCommand->authorizedCommandId);
	
	switch(myCommand->authorizedCommandId)
	{
		case 1://load
			
			if(myDebug) fprintf(stderr, "Tool performing load.\n");
			//if (
			chown(myCommand->file, 0, 0);
			//	return -1;
			//if (
			chmod(myCommand->file, S_IRWXU|S_IRGRP|S_IXGRP);
			//	return -1;
			
			/*switch(pid = fork())
		{
			case 0:	//child
				if(myDebug) fprintf(stderr, "chown done\n");
				
				
				result = execl("/usr/sbin/chown", "chown", "-R",  "root:wheel", myCommand->file, NULL);
				
				_exit(result);
				break;
				
				case -1: //error
				if(myDebug) fprintf(stderr, "chown error\n");
				return kMyAuthorizedCommandInternalError;
				
				default: //parent
				if(myDebug) fprintf(stderr, "chown parent\n");
				
				//execl("/usr/sbin/chown", "chown", "-R",  "root:wheel", myCommand->file, NULL);
				break;
		}
			
			switch(pid = fork())
		{
			case 0:	//child
				if(myDebug) fprintf(stderr, "chmod done\n");
				
				result = execl("/bin/chmod", "chmod", "-R", "g-w", myCommand->file, NULL);
				
				
				_exit(result);
				break;
				
				case -1: //error
				if(myDebug) fprintf(stderr, "chmod error\n");
				return kMyAuthorizedCommandInternalError;
				
				default: //parent
				if(myDebug) fprintf(stderr, "chmod parent\n");
				//execl("/bin/chmod", "chmod", "-R", "g-w", myCommand->file, NULL);
				break;
		}
			
			switch(pid = fork())
		{
			case 0:	//child
				if(myDebug) fprintf(stderr, "chmode done\n");
				
				if (execl("/bin/chmod", "chmod", "-R", "o-wrx", myCommand->file, NULL) != 0) {
					_exit(0);
				}
				
				_exit(1);
				break;
				
				case -1: //error
				if(myDebug) fprintf(stderr, "chmod error\n");
				return kMyAuthorizedCommandInternalError;
				
				default: //parent
				if(myDebug) fprintf(stderr, "chmod parent\n");
				//execl("/bin/chmod", "chmod", "-R", "o-wrx", myCommand->file, NULL);
				break;
		}
			*/
			switch(pid = fork())
		{
			case 0:	//child
				if(myDebug) fprintf(stderr, "kext loading\n");
				//execl("/usr/sbin/chown", "chown", "-R",  "root:wheel", myCommand->file, NULL);
				result = execl("/sbin/kextload", "kextload", myCommand->file, NULL);
				//execl("/bin/chmod", "chmod", "-R", "g-w", myCommand->file, NULL);
				//execl("/bin/chmod", "chmod", "-R", "o-wrx", myCommand->file, NULL);
				return result;
				//_exit(1);
				break;
				
				/*case -1: //error
				if(myDebug) fprintf(stderr, "kextload error\n");
				return kMyAuthorizedCommandInternalError;
				
				default: //parent
				if(myDebug) fprintf(stderr, "kextload parent\n");
				break;*/
		}
			
			break;
			
			case 2://unload
			if(myDebug) fprintf(stderr, "Tool performing unload.\n");
			//execl("/sbin/kextunload", "-b", "net.swieskowski.iCook");
			switch(pid = fork())
		{
			case 0:	//child
				//if (
					result = execl("/sbin/kextunload", "kextunload", myCommand->file, NULL); //!= 0)
					//_exit(0);
				//_exit(1);
					return result;
				break;
				
				case -1: //error
				return kMyAuthorizedCommandInternalError;
				default: //parent
				break;
		}
			break;
#pragma mark INSTANT
			case kMyAuthorizedHibernateInstant:
		{
			result = system("/usr/bin/pmset -a hibernatemode 1");
			if (result != 0) {
				return result;
			}
			break;
		}
#pragma mark NORMAL
			case kMyAuthorizedHibernateNormal:
		{
			result = system("/usr/bin/pmset -a hibernatemode 3");
			if (result != 0) {
				return result;
			}
			break;
		}
#pragma mark DISABLE
			case kMyAuthorizedHibernateDisable:
		{
			result = system("/usr/bin/pmset -a hibernatemode 0");
			if (result != 0) {
				return result;
			}
			break;
		}
#pragma mark INSTALL
			case kMyAuthorizedHibernateInstall:
		{
			result = system(myCommand->file);
			if (result != 0) {
				return result;
			}
			break;
		}
			
			default:
			if(myDebug) fprintf(stderr, "Unrecognized command.\n");
			break;
	}
	
	if (myDebug) fprintf(stderr, "Tool performing Command %d on path %s.\n", myCommand->authorizedCommandId, myCommand->file);
	return result;
}




int
main(int argc, char * const *argv)
{
	//freopen("/Users/jamesas/Library/Logs/InsomniaX.log", "a", stderr);
	
	// OSStatus status;
    AuthorizationRef auth;
    int bytesRead;
    MyAuthorizedCommand myCommand;
    
    unsigned long path_to_self_size = 0;
    char *path_to_self = NULL;
	
    
    /* MyGetExecutablePath() attempts to use _NSGetExecutablePath() (see NSModule(3)) if it's available in
	 order to get the actual path of the tool. */
	
    path_to_self_size = MAXPATHLEN;
    if (! (path_to_self = malloc(path_to_self_size)))
        exit(kMyAuthorizedCommandInternalError);
    if (MyGetExecutablePath(path_to_self, &path_to_self_size) == -1)
    {
        /* Try again with actual size */
        if (! (path_to_self = realloc(path_to_self, path_to_self_size + 1)))
            exit(kMyAuthorizedCommandInternalError);
        if (MyGetExecutablePath(path_to_self, &path_to_self_size) != 0)
            exit(kMyAuthorizedCommandInternalError);
    }                
	
    if (argc == 2 && !strcmp(argv[1], "--self-repair"))
    {
        /*  Self repair code.  We ran ourselves using AuthorizationExecuteWithPrivileges()
		 so we need to make ourselves setuid root to avoid the need for this the next time around. */
        
        struct stat st;
        int fd_tool;
		
		if(myDebug) fprintf(stderr, "got --self-repair\n");
		
        /* Recover the passed in AuthorizationRef. */
        if (AuthorizationCopyPrivilegedReference(&auth, kAuthorizationFlagDefaults))
            exit(kMyAuthorizedCommandInternalError);
		
        /* Open tool exclusively, so noone can change it while we bless it */
        fd_tool = open(path_to_self, O_NONBLOCK|O_RDONLY|O_EXLOCK, 0);
		
        if (fd_tool == -1)
        {
            if(myDebug) fprintf(stderr, "Exclusive open while repairing tool failed: %d.\n", errno);
            exit(kMyAuthorizedCommandInternalError);
        }
		
        if (fstat(fd_tool, &st))
            exit(kMyAuthorizedCommandInternalError);
        
        if (st.st_uid != 0)
            fchown(fd_tool, 0, st.st_gid);
		
        /* Disable group and world writability and make setuid root. */
        fchmod(fd_tool, (st.st_mode & (~(S_IWGRP|S_IWOTH))) | S_ISUID);
		
        close(fd_tool);
		
        if(myDebug) fprintf(stderr, "Tool self-repair done.\n");
		
    }
    else
    {
		
	    AuthorizationExternalForm extAuth;
		
        // Read the Authorization "byte blob" from our input pipe. 
        if (read(0, &extAuth, sizeof(extAuth)) != sizeof(extAuth))
            exit(kMyAuthorizedCommandInternalError);
        
        // Restore the externalized Authorization back to an AuthorizationRef
        if (AuthorizationCreateFromExternalForm(&extAuth, &auth))
            exit(kMyAuthorizedCommandInternalError);
		
        // If we are not running as root we need to self-repair. 
        if (geteuid() != 0)
        {
			
            int status;
            int pid;
            FILE *commPipe = NULL;
            char *arguments[] = { "--self-repair", NULL };
            char buffer[1024];
            int bytesRead;
			
            // Set our own stdin and stdout to be the communication channel with ourself. 
            
            if(myDebug) fprintf(stderr, "Tool about to self-exec through AuthorizationExecuteWithPrivileges.\n");
            
            if (AuthorizationExecuteWithPrivileges(auth, path_to_self, kAuthorizationFlagDefaults, arguments, &commPipe))
                exit(kMyAuthorizedCommandInternalError);
			
            // Read from stdin and write to commPipe. 
            for (;;)
            {
                bytesRead = read(0, buffer, 1024);
                if (bytesRead < 1) break;
                fwrite(buffer, 1, bytesRead, commPipe);
            }
			
            // Flush any remaining output. 
            fflush(commPipe);
            
            // Close the communication pipe to let the child know we are done. 
            fclose(commPipe);
			
            // Wait for the child of AuthorizationExecuteWithPrivileges to exit. 
            pid = wait(&status);
            if (pid == -1 || ! WIFEXITED(status))
                exit(kMyAuthorizedCommandInternalError);
			
            // Exit with the same exit code as the child spawned by AuthorizationExecuteWithPrivileges() 
            exit(WEXITSTATUS(status));
        }
		
    }
	
    /* No need for it anymore */
    if (path_to_self)
        free(path_to_self);
	
	if(myDebug) fprintf(stderr, "getting command\n");
	
    /* Read a 'MyAuthorizedCommand' object from stdin. */
    bytesRead = read(0, &myCommand, sizeof(MyAuthorizedCommand));
    
    /* Make sure that we received a full 'MyAuthorizedCommand' object */
    if (bytesRead == sizeof(MyAuthorizedCommand))
    {
		// const char *rightName = rightNameForCommand(&myCommand);
		// AuthorizationItem right = { rightName, 0, NULL, 0 } ;
		// AuthorizationRights rights = { 1, &right };
		// AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed
        //                            | kAuthorizationFlagExtendRights;
        
        /* Check to see if the user is allowed to perform the tasks stored in 'myCommand'. This may
		 or may not prompt the user for a password, depending on how the system is configured. */
		
		// if(myDebug) fprintf(stderr, "Tool authorizing right %s for command.\n", rightName);
        
		// if (status = AuthorizationCopyRights(auth, &rights, kAuthorizationEmptyEnvironment, flags, NULL))
		// {
		//     if(myDebug) fprintf(stderr, "Tool authorizing command failed authorization: %ld.\n", status);
		//     exit(kMyAuthorizedCommandAuthFailed);
		// }
		
		if(myDebug) fprintf(stderr, "try to perform a command\n");
		
        /* Peform the opertion stored in 'myCommand'. */
        if (performOperation(&myCommand) != 0)
            exit(kMyAuthorizedCommandOperationFailed);
    }
    else
    {
        exit(kMyAuthorizedCommandChildError);
    }
	
    exit(0);
}

