//
//  AppDelegate.m
//  Speak
//
//  Created by Christian Gratton on 2013-04-24.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "AppDelegate.h"
#import "WTSWTSTMScene.h"

#import "OKPoEMM.h"
#import "OKPreloader.h"
#import "OKTextManager.h"
#import "OKAppProperties.h"
#import "OKPoEMMProperties.h"
#import "OKInfoViewProperties.h"
#import "Appirater.h"

#import "TestFlight.h"

#define IS_IPAD_2 (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) // Or more
#define IS_IPHONE_5 (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && [[UIScreen mainScreen] bounds].size.height == 568.0f)
#define SHOULD_MULTISAMPLE (IS_IPAD_2 || IS_IPHONE_5)

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //seed the randomizer
    srandom(time(NULL));
    
    #warning comment when building for store
    //[TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
    
    // TestFlight
    //[TestFlight takeOff:@"bf45fd34-632d-4449-81d6-1a804ae2f1b4"];
    
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"fLaunch"])
        [self setDefaultValues];
    
    // NEW
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Get Screen Bounds
    CGRect sBounds = [[UIScreen mainScreen] bounds];
    CGRect sFrame = CGRectMake(sBounds.origin.x, sBounds.origin.y, sBounds.size.height, sBounds.size.width); // Invert height and width to componsate for portrait launch (these values will be set to determine behaviors/dimensions in EAGLView)
    
    // Set app properties
    [OKAppProperties initWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"OKAppProperties.plist"] andOptions:launchOptions];
    [OKPoEMMProperties initWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"OKPoEMMProperties.plist"]];
    
    // Load texts
    BOOL canLoad = YES;
    // Get the id of the last text the user read
    NSString *textKey = [[NSUserDefaults standardUserDefaults] stringForKey:Text];
    
    // Checks if we had a loaded text
    if(textKey != nil)
    {
        //save default key, just in case
        NSString* defaultTextKey = [[OKTextManager sharedInstance] getDefaultPackage];
        
        // Fixes the bug where net.obxlabs.Know.jlewis.Know is replaced by net.obxlabs.Know.jlewis.67 when list is downloaded
        // but no poem is selected. This finds the default poem and returns the right key.
        // LowercaseString for appName because speak's package ID sets "wts" and not "Speak" like the app name
        NSString *appName = [OKAppProperties objectForKey:@"Name"];
        NSString *master = [NSString stringWithFormat:@"net.obxlabs.%@.jlewis.wts", [appName lowercaseString]];
        if([textKey isEqualToString:master])
            textKey = [[OKTextManager sharedInstance] getDefaultPackage];
        
        //load the text
        if (![[OKTextManager sharedInstance] loadTextFromPackage:textKey atIndex:0]) {
            // try loading custom text
            if(![[OKTextManager sharedInstance] loadCustomTextFromPackage:textKey]) {
                if(![[OKTextManager sharedInstance] loadTextFromPackage:defaultTextKey atIndex:0]) {
                    NSLog(@"Error: could not load any text for package %@ and default package %@. Clearing cache and starting from new.", textKey, defaultTextKey);
                    
                    // Deletes existing file (last hope)
                    [OKTextManager clearCache];
                    
                    // Load new (original)
                    if(![[OKTextManager sharedInstance] loadTextFromPackage:@"net.obxlabs.speak.jlewis.wts" atIndex:0]) {
                        // Epic fail
                        NSLog(@"Error: Epic fail.");
                        canLoad = NO;
                    }
                }
            }
        }
    } else {
        // Set default text
        if(![[OKTextManager sharedInstance] loadTextFromPackage:@"net.obxlabs.speak.jlewis.wts" atIndex:0]) {
            NSLog(@"Error: could not load default package. Probably missing some objects (fonts).");
        }
    }
    
    // Show the preloader
    OKPreloader *preloader = [[OKPreloader alloc] initWithFrame:sFrame forApp:self loadOnAppear:canLoad];
    
    // If we can't load a text, show a warning to the user
    if(!canLoad)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"System Error" message:@"It would appear that all app files were corrupted. Please delete and re-install the app and try again." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [alert show];
    }
    
    // Add to window
    [self.window setRootViewController:preloader];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void) setDefaultValues
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"exhibition_preference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"guide_preference"];
    
    /* There seems to be an issue with the Bundle Version being 7.0.4 instead of 3.0.0 so I set the default value instead of getting the current one
     [[NSUserDefaults standardUserDefaults] setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"version_preference"];
     */
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"fLaunch"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) loadOKPoEMMInFrame:(CGRect)frame
{
    // Try to use CADisplayLink director
	// if it fails (SDK < 3.1) use the default director
	if( ! [CCDirector setDirectorType:kCCDirectorTypeDisplayLink] )
		[CCDirector setDirectorType:kCCDirectorTypeDefault];
	
    // Does the app support @2x fonts?
    [[OKAppProperties sharedInstance] setSupportsRetinaFonts:YES];
    
	// Get the shared director
	CCDirector *director = [CCDirector sharedDirector];
    
	// To enable Hi-Res mode
	[director setContentScaleFactor:[[OKAppProperties sharedInstance] scale]];
	
	//
	// Create the EAGLView manually
	//  Pixel format: RGBA8 (multisampling seem to have issues with RGB565 on older iOS version)
	//	Depth format of 0 bit. Use 16 or 24 bit for 3d effects, like CCPageTurnTransition
    //  Multisampling: for iOS 4.0.0 and above.
	//
	EAGLView *glView = [EAGLView viewWithFrame:frame
								   pixelFormat:kEAGLColorFormatRGBA8    //kEAGLColorFormatRGB565
								   depthFormat:0						// GL_DEPTH_COMPONENT16_OES
							preserveBackbuffer:NO
									sharegroup:nil
								 multiSampling:YES // Because we are deploying to 6.0+//[WTSWTSTMProperties osGreaterOrEqualThan:@"4.0.0"]
							   numberOfSamples:4];
	
	// attach the openglView to the director
	[director setOpenGLView:glView];
	
	//
	// VERY IMPORTANT:
	// If the rotation is going to be controlled by a UIViewController
	// then the device orientation should be "Portrait".
	//
	[director setDeviceOrientation:kCCDeviceOrientationPortrait];
    [director setAnimationInterval:1.0/60];
	[director setDisplayFPS:NO];
    
    // Initilaize OKPoEMM (EAGLView, OKInfoView, OKRegistration... wrapper)
    self.poemm = [[OKPoEMM alloc] initWithFrame:frame EAGLView:glView isExhibition:[[NSUserDefaults standardUserDefaults] boolForKey:@"exhibition_preference"]];
    [self.window setRootViewController:self.poemm];
    
    // Asked for performance version
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"guide_preference"]) {
        [self.poemm promptForPerformance];
    } else {
        // If ever performance was disabled, make sure we leave the current state of exhibition
        [self.poemm setisExhibition:[[NSUserDefaults standardUserDefaults] boolForKey:@"exhibition_preference"]];
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isPerformance"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
        
	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
	// You can change anytime.
	if ([OKAppProperties isiPad] || [OKAppProperties isRetina])
		[CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
	else
		[CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA4444];
	
	// Sets 2D projection
	[director setProjection:CCDirectorProjection2D];
	
	// Turn off multiple touches
	[glView setMultipleTouchEnabled:NO];
    
    //run scene, run!
	[director runWithScene: [WTSWTSTM scene]];
    
	//if the app launched from a push, show list of poems right away instead
    if([[OKAppProperties sharedInstance] wasPushed])
        [self.poemm openMenuAtTab:MenuGuestPoetsTab];
    
    //Appirater after eaglview is started and a few seconds after to let everything get in motion
    [self performSelector:@selector(manageAppirater) withObject:nil afterDelay:10.0f];
}

- (void)applicationWillResignActive:(UIApplication *)application {
	[[CCDirector sharedDirector] pause];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	[[CCDirector sharedDirector] resume];
    
    // Asked for performance version
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"guide_preference"]) {
        [self.poemm promptForPerformance];
    } else {
        // If ever performance was disabled, make sure we leave the current state of exhibition
        [self.poemm setisExhibition:[[NSUserDefaults standardUserDefaults] boolForKey:@"exhibition_preference"]];
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isPerformance"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[[CCDirector sharedDirector] purgeCachedData];
}

-(void) applicationDidEnterBackground:(UIApplication*)application {
	[[CCDirector sharedDirector] stopAnimation];
}

-(void) applicationWillEnterForeground:(UIApplication*)application {
	[[CCDirector sharedDirector] startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	CCDirector *director = [CCDirector sharedDirector];
	[[director openGLView] removeFromSuperview];
    //[UAirship land];
	[director end];
}

- (void)applicationSignificantTimeChange:(UIApplication *)application {
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
    
}

#pragma mark - Appirater

- (void) manageAppirater
{
    [Appirater appLaunched:YES];
    [Appirater setDelegate:self];
    [Appirater setLeavesAppToRate:YES]; // Just too hard on the memory
    [Appirater setAppId:@"406078727"];
    [Appirater setDaysUntilPrompt:5];
    [Appirater setUsesUntilPrompt:5];
}

-(void)appiraterDidDisplayAlert:(Appirater *)appirater
{
    [[CCDirector sharedDirector] stopAnimation];
}

-(void)appiraterDidDeclineToRate:(Appirater *)appirater
{
    [[CCDirector sharedDirector] startAnimation];
}

-(void)appiraterDidOptToRate:(Appirater *)appirater
{
    [[CCDirector sharedDirector] stopAnimation];
}

-(void)appiraterDidOptToRemindLater:(Appirater *)appirater
{
    [[CCDirector sharedDirector] startAnimation];
}

-(void)appiraterWillPresentModalView:(Appirater *)appirater animated:(BOOL)animated
{
    [[CCDirector sharedDirector] stopAnimation];
}

-(void)appiraterDidDismissModalView:(Appirater *)appirater animated:(BOOL)animated
{
    [[CCDirector sharedDirector] startAnimation];
}

@end
