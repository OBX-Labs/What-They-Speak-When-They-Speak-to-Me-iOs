//
//  OKPoEMMProperties.m
//  OKPoEMM
//
//  Created by Christian Gratton on 2013-02-18.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "OKPoEMMProperties.h"

// Properties name constants of static parameters (plist)
// These values can be used throughout different poemm apps, they should not change
NSString* const Text = @"Text"; // current package
NSString* const Title = @"Title";
NSString* const Default = @"DefaultPoem";
NSString* const TextFile = @"TextFile";
NSString* const TextVersion = @"TextVersion";
NSString* const AuthorImage = @"AuthorImage";
NSString* const FontFile = @"FontFile";
NSString* const FontOutlineFile = @"FontOutlineFile";
NSString* const FontTessellationFile = @"FontTessellationFile";

// This will be unique to each poemm app, you will need to create a unique property for each different value that appears in the plist

// WTSWTSTMScene.mm
NSString* const BgColor = @"BgColor";
NSString* const PathColor = @"PathColor";
NSString* const PathWidth = @"PathWidth";
// WTSWTSTMModel.mm
NSString* const PathOffset = @"PathOffset";
NSString* const SwimCloudSize = @"SwimCloudSize";
NSString* const WordSpacing = @"WordSpacing";
NSString* const TextColorBg = @"TextColorBg";
NSString* const TextColorBgHighlight = @"TextColorBgHighlight";
NSString* const TextColorFg = @"TextColorFg";
NSString* const FollowVelocity = @"FollowVelocity";
NSString* const MaxPathLength = @"MaxPathLength";
NSString* const PathSpacing = @"PathSpacing";
NSString* const RotationBackVelocity = @"RotationBackVelocity";
NSString* const RotationToVelocity = @"RotationToVelocity";
NSString* const SwimVelocity = @"SwimVelocity";

// Property name constant of dynamic paramaters
NSString* const Orientation = @"Orientation";
NSString* const UprightAngle = @"UprightAngle";

@implementation OKPoEMMProperties

+ (UIDeviceOrientation) orientation { return [(NSNumber*)[super objectForKey:Orientation] intValue]; };

+ (void) setOrientation:(UIDeviceOrientation)aOrientation
{
    // If orientation is the same as current, then do nothing
    if([self orientation] == aOrientation) return;
    
    // Only accept certain orientations
    if ((aOrientation != UIDeviceOrientationLandscapeLeft) && (aOrientation != UIDeviceOrientationLandscapeRight) && (aOrientation != UIDeviceOrientationPortrait) && (aOrientation != UIDeviceOrientationPortraitUpsideDown)) return;
    
    // Set the orientation
    [[super sharedInstance].properties setValue:[NSNumber numberWithInt:aOrientation] forKey:Orientation];
    
    // Adjust the UprightAngle to match
    if (aOrientation == UIDeviceOrientationLandscapeLeft)
		[[super sharedInstance].properties setValue:[NSNumber numberWithInt:90] forKey:UprightAngle];
	else if (aOrientation == UIDeviceOrientationLandscapeRight)
		[[super sharedInstance].properties setValue:[NSNumber numberWithInt:-90] forKey:UprightAngle];
	else if (aOrientation == UIDeviceOrientationPortrait)
		[[super sharedInstance].properties setValue:[NSNumber numberWithInt:0] forKey:UprightAngle];
	else if (aOrientation == UIDeviceOrientationPortraitUpsideDown)
		[[super sharedInstance].properties setValue:[NSNumber numberWithInt:180] forKey:UprightAngle];
}

+ (int) uprightAngle { return [(NSNumber*)[super objectForKey:UprightAngle] intValue]; }

+ (void) initWithContentsOfFile:(NSString *)aPath
{        
    // Insert an empty dictionary as an object     
    [OKAppProperties setObject:[[NSMutableDictionary alloc] init] forKey:@"OKPoEMMProperties"];
    
    // Set default orientation to unknown
    [OKPoEMMProperties setOrientation:UIDeviceOrientationUnknown];
}

+ (id) objectForKey:(id)aKey { return [[OKAppProperties objectForKey:@"OKPoEMMProperties"] objectForKey:aKey]; }

+ (void) setObject:(id)aObject forKey:(id)aKey
{
    [[OKAppProperties objectForKey:@"OKPoEMMProperties"] setObject:aObject forKey:aKey];
}

// Fills the properties with a loaded package dictionary (Properties-iPhone, Properties-iPhone-Retina, Properties-iPhone-568h, Properties-iPad, Properties-iPad-Retina)
+ (void) fillWith:(NSDictionary *)aTextDict
{    
    for(NSString *key in [aTextDict allKeys])
    {
        if([key rangeOfString:@"Properties-"].location != NSNotFound)
        {
            // Check if properties of device
            if([key isEqualToString:[NSString stringWithFormat:@"Properties-%@", [OKAppProperties deviceType]]])
            {
                NSDictionary *properties = [aTextDict objectForKey:[NSString stringWithFormat:@"Properties-%@", [OKAppProperties deviceType]]];
                
                for(NSString *propertyKey in [properties allKeys])
                {
                    [OKPoEMMProperties setObject:[properties objectForKey:propertyKey] forKey:propertyKey];
                }
            }
        }
        else
        {
            [OKPoEMMProperties setObject:[aTextDict objectForKey:key] forKey:key];
        }
    }
}

+ (void) listProperties { NSLog(@"listProperties %@", [OKAppProperties objectForKey:@"OKPoEMMProperties"]); }

@end
