#import "ButtonController.h"
//#define debug


/* Versioning system for Insomnia, vital to ensure we can update our kext */
#define insomnia_name @"Insomnia_r6.kext"
#define insomnia_name_ppc @"Insomnia.kext"
#define kReadmeVersion @"1.1"

@implementation ButtonController

#pragma mark NSApplication Methods
BOOL licence = 0;
- (void) awakeFromNib
{
	[NSApp setDelegate:self];
	[NSApp activateIgnoringOtherApps:YES];
	myInitAuthCommand();
	
	[DiskImageUtilities handleApplicationLaunchCheck];
	
	licence = [[NSUserDefaults standardUserDefaults] integerForKey:kReadmeVersion];
	
	if (!licence)
		[self makeReadme];
	
	
	NSString *supportPath = [NSHomeDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"Library/Application Support/%@", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"]]];
	NSBundle *bundle = [NSBundle mainBundle];
	
	long		gestaltReturnValue;
	Gestalt(gestaltSystemVersionMinor,&gestaltReturnValue);
	if (gestaltReturnValue >= 4) {
		//NSLog(@"Warning: Running on a system supported");
		insomniaPath = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@/%@", supportPath, insomnia_name]];
	} else {
		NSLog(@"Warning: Running on a system not supported, loading legacy Insomnia.kext");
		insomniaPath = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@/%@", supportPath, insomnia_name_ppc]];
	}
	/* Make sure InsomniaX is writeable */
	if (![[NSFileManager defaultManager] isWritableFileAtPath:[[NSBundle mainBundle] bundlePath]]){
		if (NSRunAlertPanel(@"InsomniaX",@"Please install InsomniaX to a location you have permission to write to",@"Ok",NULL,NULL) == NSAlertDefaultReturn){
			[NSApp terminate:self];
		}
	}
	
	/* Install latest InsomniaX */
	if (![[NSFileManager defaultManager] fileExistsAtPath:insomniaPath]){
		NSLog(@"Installing Latest Kext");
		
		NSString *source = [[[[[NSBundle mainBundle] bundlePath]
							stringByAppendingPathComponent:@"Contents"]
							stringByAppendingPathComponent:@"Resources"]
							stringByAppendingPathComponent:insomnia_name];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:source]) {
			[[NSFileManager defaultManager] createDirectoryAtPath:supportPath attributes:nil];
			[[NSFileManager defaultManager] copyPath:source toPath:[supportPath stringByAppendingPathComponent:insomnia_name] handler:nil];
		}
		
		NSLog(@"Latest Insomnia kext is installed at %@", insomniaPath);
		
		const char *CinsomniaPath = [insomniaPath UTF8String];
		[NSApp activateIgnoringOtherApps:YES];
		/* This is for that werid ass bug where Insomnia doesnt work the first load for some reason */
		NSRunAlertPanel(@"InsomniaX",@"We have just installed a new Insomnia kext, we now need to finish the installation",@"Ok",NULL,NULL);
		myPerformAuthCommand(kMyAuthorizedLoad, (char*)CinsomniaPath);
		myPerformAuthCommand(kMyAuthorizedUnload, (char*)CinsomniaPath);
	}
	
	
	
	/********************************	  Sounds  	 ********************************/
	if ([[NSUserDefaults standardUserDefaults] integerForKey:@"sound"]){
		loadSound = [[NSSound alloc] initWithContentsOfFile:[bundle pathForResource:@"loaded" ofType:@"mp3"]
												byReference:YES];
		unloadSound = [[NSSound alloc] initWithContentsOfFile:[bundle pathForResource:@"unloaded" ofType:@"mp3"]
												  byReference:YES];	
	}
	/********************************	Status Item 	********************************/
	if (!([[NSUserDefaults standardUserDefaults] integerForKey:@"disableStatusItem"])){
		statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
		
		loadImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"loaded" ofType:@"png"]];
		unloadImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"unloaded" ofType:@"png"]];
		
		[statusItem setMenu:statusMenu];
		[statusItem setHighlightMode:YES];
	}
	
	
	/******************************	AppleRemote 	******************************/
	//if ([[NSUserDefaults standardUserDefaults]  boolForKey:@"AppleRemote"]) {
	[[AppleRemote sharedRemote] setDelegate: self];
	[[AppleRemote sharedRemote] setOpenInExclusiveMode:NO];
	[[AppleRemote sharedRemote] startListening: self];
	//}
	/*******************************************************************************/

	/* Sets the hotkey */
	if ([[NSUserDefaults standardUserDefaults] integerForKey:@"hotkey"]){
		int keyCombo = [[NSUserDefaults standardUserDefaults] integerForKey:@"keyCombo"];
		int keyFlags = [[NSUserDefaults standardUserDefaults] integerForKey:@"keyFlags"];
		
		globalHotKey = [[PTHotKey alloc] initWithIdentifier:@"IXLoad"
												   keyCombo:[PTKeyCombo keyComboWithKeyCode:keyCombo
																				  modifiers:keyFlags]];
		
		[globalHotKey setTarget: self];
		[globalHotKey setAction: @selector(insomnia:)];
		
		[[PTHotKeyCenter sharedCenter] registerHotKey: globalHotKey];
		
		[hotkeyItem setState:YES];
	}

	/* Auto load function */
	globalInsomniaState = [self checkInsomnia];

	//if ([[NSUserDefaults standardUserDefaults] integerForKey:@"powerEvent"] || [[NSUserDefaults standardUserDefaults] integerForKey:@"disableOnBattery"]) {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(powerSourceChanged:) name:@"powerSourceChanged" object:NSApp];	
	[NSApp powerSourceChanged];
	//}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"autoLoad"] && ![[NSUserDefaults standardUserDefaults] integerForKey:@"powerEvent"]) {
		if (!globalInsomniaState) {
			[self insomniaLoader:ENABLE];
		}
		
	} else {
		[self setInsomniaStatus:globalInsomniaState];
}

	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"enableHibernation"] != nil) {
		//[hibernateItem setEnabled:TRUE];
		if ([self checkHibernate] >= 1){
			[hibernateItem setTitle:@"Disable Hibernation"];
		} else {
			[hibernateItem setTitle:@"Enable Hibernation"];
		}
	} else {
		[hibernateItem setHidden:TRUE];
	}

/* Set update system */
if ([[NSUserDefaults standardUserDefaults] objectForKey:@"SUFeedURL"] != nil){
	[betaUpdate setState:YES];
} else {
	[betaUpdate setState:NO];
}

[acItem setState:[[NSUserDefaults standardUserDefaults] integerForKey:@"disableOnBattery"]];
[battItem setState:[[NSUserDefaults standardUserDefaults] integerForKey:@"powerEvent"]];
[loadOnStartItem setState:[[NSUserDefaults standardUserDefaults] integerForKey:@"autoLoad"]];

[NSApp activateIgnoringOtherApps:YES];

}

/*
 NSApp - Terminate Notification
 Notify user if they still have Insomnia loaded
 */
- (IBAction)quitInsomniaX:(id)sender{
	if ([self checkInsomnia]){
		[NSApp activateIgnoringOtherApps:YES];
		if (NSRunAlertPanel(@"InsomniaX",@"Insomnia is still loaded, do you want to unload",@"Yes",@"No",NULL) == NSAlertDefaultReturn){
			[self insomniaLoader:DISABLE];
		}
	}
	[NSApp terminate:self];
	
	
}


- (void) dealloc
{
	[loadImage release];
	[unloadImage release];
	
	[loadSound release];
	[unloadSound release];
	
	[super dealloc];
}

#pragma mark Menu Items

- (IBAction)insomnia:(id)sender
{
	if (!licence){
		[self makeReadme];
	} else {
		int state = [self checkInsomnia];
		if (state) {
			[self insomniaLoader:DISABLE];	
		} else {
			[self insomniaLoader:ENABLE];	
		}
	}
}

- (IBAction)hibernateItem:(id)sender{
	if (!licence){
		[self makeReadme];
	} else {
		int result_warn_panel;
		int result;
		[NSApp activateIgnoringOtherApps:YES];
		
		if (([self checkHibernate] == 5) || ([self checkHibernate] == 7)){
			NSRunAlertPanel(@"InsomniaX",@"You are using secure memory, hibernation will not work",@"OK",nil,nil);
			result_warn_panel = -1;
		} else {
			if ([[NSUserDefaults standardUserDefaults] integerForKey:@"warnings"]) {
				hibernation_warning = YES;
			}
			if (!hibernation_warning) {
				result_warn_panel = NSRunAlertPanel(@"InsomniaX",
													@"Warning: This option carries many warnings, please ensure you have fully read the readme and understand all the warnings and details", 
													@"I understand and accept the warnings", 
													@"Cancel", 
													nil);
			} else {
				result_warn_panel = NSOKButton;
			}
		}
		if (result_warn_panel == NSOKButton){
			hibernation_warning = YES;
			NSTask *task = [[NSTask alloc] init];
			[task setLaunchPath: @"/bin/sh"];
			
			NSArray *arguments = [NSArray arrayWithObjects: @"-c", @"pmset -g", nil];
			[task setArguments: arguments];
			
			NSPipe *pipe = [NSPipe pipe];
			[task setStandardOutput: pipe];
			
			NSFileHandle *file = [pipe fileHandleForReading];
			
			[task launch];
			
			NSString *string = [[NSString alloc] initWithData: [file readDataToEndOfFile]
													 encoding: NSUTF8StringEncoding];
			
			/* Installs and restarts the system */
			if (([string rangeOfString:@"hibernatefile"].location == NSNotFound) && ([string rangeOfString:@"hibernatemode"].location == NSNotFound)){
				int result_install_panel;
				result_install_panel = NSRunAlertPanel(@"InsomniaX",
													   @"It appears this system was not designed to support hibernation, if you continue you may cause damage to your machine, please refer to the readme", 
													   @"Enable", 
													   @"Cancel", 
													   nil);
				if (result_install_panel == NSOKButton){				
					//NSLog([[NSBundle mainBundle] pathForResource:@"enable-safe-sleep" ofType:@"sh"]);
					const char *enableScriptPath = [[[NSBundle mainBundle] pathForResource:@"enable-safe-sleep" ofType:@"sh"] UTF8String];
					result = myPerformAuthCommand(kMyAuthorizedHibernateInstall, (char*)enableScriptPath);
					if (result == SUCCESS) {
						int result_restart_panel;
						result_restart_panel = NSRunAlertPanel(@"InsomniaX",
															   @"To finish the install your system must restart", 
															   @"Restart", 
															   @"Cancel", 
															   nil);
						if (result_restart_panel == NSOKButton){
							NSAppleScript * as = [[NSAppleScript alloc] initWithSource:@"tell app \"Finder\" to restart"];
							[as executeAndReturnError:nil];
							[as release];
						}
					} else {
						NSRunCriticalAlertPanel(@"InsomniaX",@"Error: InsomniaX failed to install hibernation, please contact support",@"OK",NULL,NULL);
					}
					
				}
				/* Sets the modes if installed */
			} else {
				int state;
				state = [self checkHibernate];
				if (state < 1) {
					int result;
					result = NSRunAlertPanel(@"InsomniaX",
											 @"Please select the mode of hibernation you would like to enable, refer to the readme for mode listings.", 
											 @"Low Power", 
											 @"Cancel", 
											 @"Instant");
					
					switch (result) {
						case NSAlertDefaultReturn:
							//NSLog(@"Low Power");
							result = myPerformAuthCommand(kMyAuthorizedHibernateNormal, "");
							if (result == SUCCESS) {
								[hibernateItem setTitle:@"Disable Hibernation"];
							} else {
								NSRunCriticalAlertPanel(@"InsomniaX",@"Error: InsomniaX failed to set normal hibernation, please contact support",@"OK",NULL,NULL);
							}
								//[hibernateItem setState:YES];
								
								break;
						case NSAlertOtherReturn:
							//NSLog(@"Instant");
							result = myPerformAuthCommand(kMyAuthorizedHibernateInstant, "");
							if (result == SUCCESS) {
								[hibernateItem setTitle:@"Disable Hibernation"];
							} else {
								NSRunCriticalAlertPanel(@"InsomniaX",@"Error: InsomniaX failed to set instant hibernation, please contact support",@"OK",NULL,NULL);
							}
								break;
						default:
							//NSLog(@"Cancel");
							break;
					}
				} else {
					//NSLog(@"Enabled");
					result = myPerformAuthCommand(kMyAuthorizedHibernateDisable, "");
					NSLog(@"Result: %i", result);
					if (result == SUCCESS) {
						[hibernateItem setTitle:@"Enable Hibernation"];
					} else {
						NSRunCriticalAlertPanel(@"InsomniaX",@"Error: InsomniaX failed to disable hibernation, please contact support",@"OK",NULL,NULL);
					}
				}
			}
		}
	}
}

- (IBAction)defaultItem:(id)sender{
	[[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)acItem:(id)sender {
	if (!licence){
		[self makeReadme];
	} else {
		if ([[NSUserDefaults standardUserDefaults] integerForKey:@"disableOnBattery"]) {
			[[NSUserDefaults standardUserDefaults] setInteger:NO forKey:@"disableOnBattery"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		} else {
			[[NSUserDefaults standardUserDefaults] setInteger:YES forKey:@"disableOnBattery"];
			[[NSUserDefaults standardUserDefaults] setInteger:NO forKey:@"powerEvent"];
			[[NSUserDefaults standardUserDefaults] setInteger:NO forKey:@"autoLoad"];
			[[NSUserDefaults standardUserDefaults] synchronize];
			[NSApp powerSourceChanged];
		}
		[acItem setState:[[NSUserDefaults standardUserDefaults] integerForKey:@"disableOnBattery"]];
		[battItem setState:[[NSUserDefaults standardUserDefaults] integerForKey:@"powerEvent"]];
		[loadOnStartItem setState:[[NSUserDefaults standardUserDefaults] integerForKey:@"autoLoad"]];
	}
}

-(IBAction)battItem:(id)sender {
	if (!licence){
		[self makeReadme];
	} else {
		if ([[NSUserDefaults standardUserDefaults] integerForKey:@"powerEvent"]) {
			[[NSUserDefaults standardUserDefaults] setInteger:NO forKey:@"powerEvent"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		} else {
			[[NSUserDefaults standardUserDefaults] setInteger:NO forKey:@"disableOnBattery"];
			[[NSUserDefaults standardUserDefaults] setInteger:YES forKey:@"powerEvent"];
			[[NSUserDefaults standardUserDefaults] setInteger:NO forKey:@"autoLoad"];
			[[NSUserDefaults standardUserDefaults] synchronize];
			[NSApp powerSourceChanged];
		}
		[acItem setState:[[NSUserDefaults standardUserDefaults] integerForKey:@"disableOnBattery"]];
		[battItem setState:[[NSUserDefaults standardUserDefaults] integerForKey:@"powerEvent"]];
		[loadOnStartItem setState:[[NSUserDefaults standardUserDefaults] integerForKey:@"autoLoad"]];
	}
}

-(IBAction)loadOnStartItem:(id)sender {
	if (!licence){
		[self makeReadme];
	} else {
		if ([[NSUserDefaults standardUserDefaults] integerForKey:@"autoLoad"]) {
			[[NSUserDefaults standardUserDefaults] setInteger:NO forKey:@"autoLoad"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		} else {
			[[NSUserDefaults standardUserDefaults] setInteger:NO forKey:@"disableOnBattery"];
			[[NSUserDefaults standardUserDefaults] setInteger:NO forKey:@"powerEvent"];
			[[NSUserDefaults standardUserDefaults] setInteger:YES forKey:@"autoLoad"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
		[acItem setState:[[NSUserDefaults standardUserDefaults] integerForKey:@"disableOnBattery"]];
		[battItem setState:[[NSUserDefaults standardUserDefaults] integerForKey:@"powerEvent"]];
		[loadOnStartItem setState:[[NSUserDefaults standardUserDefaults] integerForKey:@"autoLoad"]];
	}
}

- (IBAction)aboutItem:(id)sender{
	[[NSApplication sharedApplication] orderFrontStandardAboutPanel: nil ];
	[NSApp activateIgnoringOtherApps:YES];
}

- (IBAction) hotkeyItem:(id)sender{
	if (!licence){
		[self makeReadme];
	} else {
		if ([[NSUserDefaults standardUserDefaults] integerForKey:@"hotkey"]){
			[[NSUserDefaults standardUserDefaults] setInteger:NO forKey:@"hotkey"];
			[hotkeyItem setState:NO];
			[[PTHotKeyCenter sharedCenter] unregisterHotKey: globalHotKey];
			[globalHotKey release];
			globalHotKey = nil;
		} else {
			[hotkeyPanel makeKeyAndOrderFront:nil];
			[NSApp activateIgnoringOtherApps:YES];
		}
	}
}

- (IBAction)soundItem:(id)sender{
	[[NSUserDefaults standardUserDefaults] synchronize];
	if ([[NSUserDefaults standardUserDefaults] integerForKey:@"sound"]){
		loadSound = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"loaded" ofType:@"mp3"]
												byReference:YES];
		unloadSound = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"unloaded" ofType:@"mp3"]
												  byReference:YES];	
	} else {
		[loadSound release];
		loadSound = nil;
		[unloadSound release];
		unloadSound = nil;
	}
}

/* Open the console.app */
- (IBAction)openConsole:(id)sender {
	NSWorkspace				*theWorkspace = [NSWorkspace sharedWorkspace];
	/* Generate our log path */
	NSString *applicationName = [NSString stringWithFormat: @"Library/Logs/%@.log", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"]]; 
	NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent: applicationName];
	
	/* Open the log */
	[theWorkspace openFile:logPath withApplication:@"Console.app"];	
}

/* Sleep the display */
- (IBAction)sleepDisplay:(id)sender{
	NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
	
    NSArray *arguments;
    arguments = [NSArray arrayWithObjects: @"-c", @"/usr/bin/pmset force -a displaysleep 107374183; sleep 1; /usr/bin/pmset force -a displaysleep `/usr/bin/pmset -g | /usr/bin/grep displaysleep | /usr/bin/awk '{print $2}'`", nil];
    [task setArguments: arguments];
	
    [task launch];
}

- (IBAction)sleepSystem:(id)sender{
	if (!licence){
		[self makeReadme];
	} else {
		int accept;
		if ([[NSUserDefaults standardUserDefaults] integerForKey:@"warnings"]) {
			[NSApp activateIgnoringOtherApps:YES];
			accept = NSRunAlertPanel(@"InsomniaX",@"Warning: Are you sure you want to sleep the system",@"Yes",@"No",nil);
		} else {
			accept = NSOKButton;
		}
		if ( accept == NSOKButton) {
			int state;
			state = [self checkInsomnia];
			if (state) {
				[self insomniaLoader:DISABLE];
				NSTimer *loadTimer;
				NSTimer *sleepTimer;
				sleepTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendSleepEvent) userInfo:nil repeats:NO];
				loadTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(loadInsomnia) userInfo:nil repeats:NO];
				
			} else {
				[self sendSleepEvent];
			}
		}
	}
}

- (IBAction)enableBeta:(id)sender{
	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"SUFeedURL"] != nil){
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SUFeedURL"];
		[betaUpdate setState:NO];
	} else {
		[[NSUserDefaults standardUserDefaults] setObject:@"http://insomniax.semaja2.net/sparkle/updateBETA.php" forKey:@"SUFeedURL"];
		[betaUpdate setState:YES];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];
}

/* Locates the readme file and opens it */
- (IBAction)readmeItem:(id)sender {
	//[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"Readme" ofType:@"rtf"] withApplication:@"TextEdit.app"];	
	[self makeReadme];
}

#pragma mark Apple Remote

/* Legacy Apple Remote system, used in a Work Around */

- (AppleRemote*) appleRemote 
{
	return [AppleRemote sharedRemote];
}

- (void) appleRemoteButton: (AppleRemoteEventIdentifier)buttonIdentifier pressedDown: (BOOL) pressedDown 
{
	switch(buttonIdentifier) {
		case kRemoteButtonPlay_Sleep:
		{
			if ([self checkInsomnia]) {
				[self insomniaLoader:DISABLE];
				NSTimer *loadTimer;
				NSTimer *sleepTimer;
				sleepTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendSleepEvent) userInfo:nil repeats:NO];
				loadTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(loadInsomnia) userInfo:nil repeats:NO];
				[self sendSleepEvent];
			}
			break;			
		}
		default:
			break;
	}	
}

-(void)loadInsomnia{
	[self insomniaLoader:ENABLE];
}

#pragma mark Insomnia

-(BOOL)checkInsomnia{
	NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
	
    NSArray *arguments = [NSArray arrayWithObjects: @"-c", @"kextstat | grep insomnia", nil];
    [task setArguments: arguments];
	
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
	
    NSFileHandle *file = [pipe fileHandleForReading];
	
    [task launch];
	
    NSData *data = [file readDataToEndOfFile];
    NSString *string = [[NSString alloc] initWithData: data
											 encoding: NSUTF8StringEncoding];
	
	if ([string isEqualToString:@""]) {
		return NO;
	}
	else {
		return YES;
	}
}

-(void)setInsomniaStatus:(int)state{
	if (state) {
		[statusInsomniaItem setTitle:@"Disable Insomnia"];
		[statusItem setImage:loadImage];
		if ([[NSUserDefaults standardUserDefaults] integerForKey:@"sound"]){
			if (loadSound != nil) {
				[loadSound play];
			}
		}
	}
	else {
		[statusInsomniaItem setTitle:@"Enable Insomnia"];
		[statusItem setImage:unloadImage];
		if ([[NSUserDefaults standardUserDefaults] integerForKey:@"sound"]){
			if (unloadSound != nil) {
				[unloadSound play];
			}
		}
	}
}

/* Legacy Code */
-(void)shakeIt:(NSTimer *)timer{
	UpdateSystemActivity(OverallAct);
}

- (int)insomniaLoader:(BOOL)state{
	int result;
	if (!licence){
		[self makeReadme];
		result = 1;
	} else {
		[NSApp activateIgnoringOtherApps:YES];
		const char *CinsomniaPath = [insomniaPath UTF8String];
		if (state) {
			result = myPerformAuthCommand(kMyAuthorizedUnload, (char*)CinsomniaPath);
			NSLog(@"%i", result);
			//if (result == -1) {
				globalInsomniaState = NO;
				[self setInsomniaStatus:NO];
				if ([[NSUserDefaults standardUserDefaults] integerForKey:@"jiggler"]) {
					[jigglerTimer invalidate];
					jigglerTimer = nil;
				}
			/*} else {
				NSRunCriticalAlertPanel(@"InsomniaX",@"Error: InsomniaX failed to unload Insomnia, please contact support",@"OK",NULL,NULL);
			}*/
		} else {
			result = myPerformAuthCommand(kMyAuthorizedLoad, (char*)CinsomniaPath);
			NSLog(@"%i", result);
			//if (result == -1) {
				globalInsomniaState = YES;
				[self setInsomniaStatus:YES];
				/* Legacy jiggler */
				if ([[NSUserDefaults standardUserDefaults] integerForKey:@"jiggler"]) {
					jigglerTimer = [NSTimer scheduledTimerWithTimeInterval: 5
																	target: self
																  selector: @selector(shakeIt:)
																  userInfo: nil
																   repeats: YES];
					[[NSRunLoop currentRunLoop] addTimer:jigglerTimer forMode:NSDefaultRunLoopMode];
				}
			/*} else {
				NSRunCriticalAlertPanel(@"InsomniaX",@"Error: InsomniaX failed to load Insomnia, please contact support",@"OK",NULL,NULL);
			}*/
		}
		[NSApp activateIgnoringOtherApps:YES];
	}
	return result;
}

#pragma mark Misc
-(void)makeReadme{
	NSView *readmeView;
	NSRect screenRect = [[NSScreen mainScreen] frame];
	float x = screenRect.size.width/2 - 225;
	float y = screenRect.size.height/2 - 300;
	NSRect windowRect = NSMakeRect(x,y,650,450);
	readmePanel = [[NSWindow alloc] initWithContentRect:windowRect
											  styleMask:NSTitledWindowMask | NSMiniaturizableWindowMask
												backing:NSBackingStoreBuffered
												  defer:NO
												 screen:[NSScreen mainScreen]];
	[readmePanel setReleasedWhenClosed:YES];
	[readmePanel setTitle:NSLocalizedString(@"readmeTitle", @"Readme Panel Title")];
	[readmePanel center];
	readmeView = [[NSView alloc] initWithFrame:windowRect];
	
	NSImage *logo;
	logo =  [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"InsomniaX" ofType:@"icns"]];
	
	NSImageView *logoView;
	logoView = [[NSImageView alloc] initWithFrame:NSMakeRect(8,windowRect.size.height - 12 -128,128,128)];
	[logoView setImage:logo];
	[readmeView addSubview:logoView];
	
	NSTextField *versionNumber;
	versionNumber = [[NSTextField alloc] initWithFrame:NSMakeRect(12,50,128,40)];
	NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:14.0] forKey:NSFontAttributeName];
	NSDictionary *bolddict = [NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:14.0] forKey:NSFontAttributeName];
	NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"InsomniaX" attributes:bolddict];
	
	[str appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n Version: 1.3.2" attributes:dict] autorelease]];
	
	[versionNumber setAttributedStringValue:str];
	/*NSDictionary *dict = [[NSDictionary alloc] init];
	[dict setValue:[NSFont boldSystemFontOfSize:12.0] forKey:NSFontAttributeName];
	//[versionNumber setStringValue:@"SyncBar 0.2a"];
	NSAttributedString *txtStr;
	[txtStr initWithString:@"SyncBar 0.2a" attributes:dict];
	[versionNumber setAttributedStringValue:txtStr];*/
	[versionNumber setBordered:NO];
	[versionNumber setAlignment:NSCenterTextAlignment];
	[versionNumber setEditable:NO];
	[versionNumber setDrawsBackground:NO];
	[readmeView addSubview:versionNumber];
	
	NSTextView *message = [[[NSTextView alloc] initWithFrame:NSMakeRect(0,0,650-142-12-16,800)] autorelease];
	[message setEditable:NO]; 
	[message setRichText:YES];
	[message readRTFDFromFile:[[NSBundle mainBundle] pathForResource:@"Readme" ofType:@"rtf"]];
	NSScrollView *myScrollView =  [[[NSScrollView alloc] initWithFrame:NSMakeRect(142,windowRect.size.height - (windowRect.size.height - 72) - 12,650-142-12,windowRect.size.height - 72)] autorelease];
	[myScrollView setDocumentView:message];
	[myScrollView setHasVerticalScroller:YES];
	[myScrollView setAutohidesScrollers:YES];
	[myScrollView setBorderType:NSGrooveBorder];
	[readmeView addSubview:myScrollView];
	
	if (![[NSUserDefaults standardUserDefaults] integerForKey:kReadmeVersion]) {
		NSTextField *logoSubText;
		logoSubText = [[NSTextField alloc] initWithFrame:NSMakeRect(12,windowRect.size.height - 12 - 256 -12 -128,128,256)];
		[logoSubText setStringValue:NSLocalizedString(@"readmeLicence", @"Readme Panel Licence")];
		[logoSubText setBordered:NO];
		//[logoSubText setAlignment:NSJustifiedTextAlignment];
		[logoSubText setEditable:NO];
		[logoSubText setDrawsBackground:NO];
		[readmeView addSubview:logoSubText];
		
		NSButton *agreeButton;
		agreeButton = [[NSButton alloc] initWithFrame:NSMakeRect((650 - 100 - 12),12,100,32)];
		[agreeButton setButtonType:NSMomentaryPushInButton];
		[agreeButton setBezelStyle:NSRoundedBezelStyle];
		[agreeButton setAction:@selector(acceptButton:)];
		[agreeButton setTarget:self];
		[agreeButton setTitle:NSLocalizedString(@"Agree", @"Agree")];
		[readmeView addSubview:agreeButton];
		
		
		NSButton *disagreeButton;
		disagreeButton = [[NSButton alloc] initWithFrame:NSMakeRect((650 - 100 - 100 - 12 - 12),12,100,32)];
		[disagreeButton setButtonType:NSMomentaryPushInButton];
		[disagreeButton setBezelStyle:NSRoundedBezelStyle];
		[disagreeButton setAction:@selector(terminate:)];
		[disagreeButton setTarget:NSApp];
		[disagreeButton setTitle:NSLocalizedString(@"Disagree", @"Disagree")];
		[readmeView addSubview:disagreeButton];
		
	} else {
		NSButton *agreeButton;
		agreeButton = [[NSButton alloc] initWithFrame:NSMakeRect((650 - 100 - 12),12,100,32)];
		[agreeButton setButtonType:NSMomentaryPushInButton];
		[agreeButton setBezelStyle:NSRoundedBezelStyle];
		[agreeButton setAction:@selector(close)];
		[agreeButton setTarget:readmePanel];
		[agreeButton setTitle:NSLocalizedString(@"Ok", @"Ok")];
		[readmeView addSubview:agreeButton];
	}
	
	[readmePanel setContentView:readmeView];
	[readmeView autorelease];
	[readmePanel makeKeyAndOrderFront:self];
}

-(IBAction)acceptButton:(id)sender{
	[[NSUserDefaults standardUserDefaults] setInteger:YES forKey:kReadmeVersion];
	[[NSUserDefaults standardUserDefaults] synchronize];
	licence = 1;
	[readmePanel close];
	//[readmePanel autorelease];
}
/* 
Hotkey Window - Ok Button
 Sets up Hotkey 
 */
- (IBAction) hotkeyOK:(id)sender{
	
	if ([shortcutRecorder keyComboString] == nil){
		NSRunCriticalAlertPanel(@"InsomniaX",@"You didnt set a Hot Key, are you friggin mad you'll blow your self up",@"OK",nil,nil);
	} else {
		
		int keyCombo = [shortcutRecorder keyCombo].code;
		int keyFlags = [shortcutRecorder cocoaToCarbonFlags:[shortcutRecorder keyCombo].flags];
		
		[[NSUserDefaults standardUserDefaults] setInteger:keyCombo forKey:@"keyCombo"];
		[[NSUserDefaults standardUserDefaults] setInteger:keyFlags forKey:@"keyFlags"];
		[[NSUserDefaults standardUserDefaults] setInteger:YES forKey:@"hotkey"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		globalHotKey = [[PTHotKey alloc] initWithIdentifier:@"IXLoad"
												   keyCombo:[PTKeyCombo keyComboWithKeyCode:keyCombo
																				  modifiers:keyFlags]];
		
		[globalHotKey setTarget: self];
		[globalHotKey setAction: @selector(insomnia:)];
		
		[[PTHotKeyCenter sharedCenter] registerHotKey: globalHotKey];
		
		[hotkeyItem setState:YES];
		
		[hotkeyPanel orderOut:nil];
	}
}


- (BOOL)sendSleepEvent {
	OSErr               err;
	ProcessSerialNumber psn = { 0, kSystemProcess };
	AEAddressDesc       addressDesc;
	AppleEvent          eventDesc;
	
	err = AECreateDesc (typeProcessSerialNumber,
						&psn, sizeof (psn),
						&addressDesc);
	
	if (err != noErr) {
		NSLog (@"Error %d creating address descriptor.", err);
		return NO;
	}
	
	err = AECreateAppleEvent (kCoreEventClass,
							  kAESleep,
							  &addressDesc,
							  kAutoGenerateReturnID,
							  kAnyTransactionID,
							  &eventDesc);
	
	if (err == noErr) {
		err = AESendMessage (&eventDesc,
							 NULL,
							 kAENoReply | kAECanInteract,
							 kAEDefaultTimeout);
		if (err != noErr) {
			NSLog (@"Error %d sending apple event.", err);
		}
	} else {
		NSLog (@"Error %d creating apple event.", err);
	}
	
	AEDisposeDesc (&addressDesc);
	AEDisposeDesc (&eventDesc);
	
	return err == noErr;
}

#pragma mark Power Source Notification
-(void)powerSourceChanged:(NSNotification *)notification{
	//NSLog(@" notif");
	
	if ([[NSUserDefaults standardUserDefaults] integerForKey:@"powerEvent"]) {
		NSString *powerSourceState = [[notification userInfo] objectForKey:@"powerSourceState"];
		if ([powerSourceState isEqualToString:@"AC Power"]) {
			//NSLog(@"AC");
			if ([self checkInsomnia]) {
				[self insomniaLoader:DISABLE];
			}
		} else if ([powerSourceState isEqualToString:@"Battery Power"]) {
			//NSLog(@"Battery");
			if (![self checkInsomnia]) {
				[self insomniaLoader:ENABLE];
			}
		} else {
			//NSLog(@"Error");
		}
	} else if ([[NSUserDefaults standardUserDefaults] integerForKey:@"disableOnBattery"]) {
		NSString *powerSourceState = [[notification userInfo] objectForKey:@"powerSourceState"];
		if ([powerSourceState isEqualToString:@"AC Power"]) {
			//NSLog(@"AC");
			if (![self checkInsomnia]) {
				[self insomniaLoader:ENABLE];
			}
		} else if ([powerSourceState isEqualToString:@"Battery Power"]) {
			//NSLog(@"Battery");
			if ([self checkInsomnia]) {
				[self insomniaLoader:DISABLE];
			}
		} else {
			//NSLog(@"Error");
		}
	}
}

#pragma mark Hibernation
-(int)checkHibernate{
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath: @"/bin/sh"];
	
	NSArray *arguments = [NSArray arrayWithObjects: @"-c", @"pmset -g | grep hibernatemode | /usr/bin/colrm 1 16", nil];
	[task setArguments: arguments];
	
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput: pipe];
	
	NSFileHandle *file = [pipe fileHandleForReading];
	
	[task launch];
	
	NSString *string = [[NSString alloc] initWithData: [file readDataToEndOfFile]
											 encoding: NSUTF8StringEncoding];
	
	return [string intValue];
}
@end