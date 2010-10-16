/* ButtonController */

#import <Cocoa/Cocoa.h>
#import "AppleRemote.h"
#import "HotKey/ShortcutRecorder.h"
#import "HotKey/PTHotKeyCenter.h"
#import "HotKey/PTHotKey.h"
#import "auth_tool_run.c"
#import "NSApplicationPlus.h"
#import "DiskImageUtilities.m"
#import "AuthorizedTaskManager.m"

#define DISABLE 1
#define ENABLE 0
#define SUCCESS 4

@interface ButtonController : NSObject
{
	
#pragma mark Menu Item Outlets
    IBOutlet	NSMenu				*statusMenu;
	IBOutlet	NSMenuItem			*statusInsomniaItem;
	IBOutlet	NSMenuItem			*hotkeyItem;
	IBOutlet	NSMenuItem			*hibernateItem;
	IBOutlet	NSMenuItem			*betaUpdate;
	IBOutlet	NSMenuItem			*acItem;
	IBOutlet	NSMenuItem			*battItem;
	IBOutlet	NSMenuItem			*loadOnStartItem;
	
#pragma mark Load/Unload Sound/Images
				NSStatusItem		*statusItem;
				NSImage				*loadImage;
				NSImage				*unloadImage;	
				NSSound				*loadSound;
				NSSound				*unloadSound;
	
#pragma mark NSTimers
				NSTimer				*timer;
				NSTimer				*jigglerTimer;
	
#pragma mark Hotkey
	IBOutlet	NSPanel				*hotkeyPanel;
	IBOutlet	ShortcutRecorder	*shortcutRecorder;
				PTHotKey			*globalHotKey;

#pragma mark Misc
				NSString			*insomniaPath;
				int					globalInsomniaState;
				int					hibernation_warning;
				NSPanel				*readmePanel;
}

#pragma mark Menu Item Methods
- (IBAction)insomnia:(id)sender;
- (IBAction)hibernateItem:(id)sender;
- (IBAction)aboutItem:(id)sender;
- (IBAction)soundItem:(id)sender;
- (IBAction)defaultItem:(id)sender;
- (IBAction)openConsole:(id)sender;
- (IBAction)sleepDisplay:(id)sender;
- (IBAction)quitInsomniaX:(id)sender;
- (IBAction)enableBeta:(id)sender;
- (IBAction)readmeItem:(id)sender;

-(IBAction)acItem:(id)sender;
-(IBAction)battItem:(id)sender;
-(IBAction)loadOnStartItem:(id)sender;


#pragma mark Insomnia Methods
- (BOOL)checkInsomnia;
- (void)setInsomniaStatus:(int)state;
- (int)insomniaLoader:(BOOL)state;

#pragma mark Apple Remote Methods
- (AppleRemote*) appleRemote;

#pragma mark Hotkey Methods
- (IBAction) hotkeyItem:(id)sender;
- (IBAction) hotkeyOK:(id)sender;

- (IBAction)sleepSystem:(id)sender;
- (BOOL)sendSleepEvent;
- (int)checkHibernate;


-(void)makeReadme;
-(IBAction)acceptButton:(id)sender;
@end