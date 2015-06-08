//
//  OKPoEMMProperties.h
//  OKPoEMM
//
//  Created by Christian Gratton on 2013-02-18.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "OKAppProperties.h"

#define PI		3.1415592653589793
#define TWO_PI	6.2831853071795864

// Properties name constants of static parameters (plist)
// These values can be used throughout different poemm apps, they should not change
extern NSString* const Text; // current package
extern NSString* const Title;
extern NSString* const Default;
extern NSString* const TextFile;
extern NSString* const TextVersion;
extern NSString* const AuthorImage;
extern NSString* const FontFile;
extern NSString* const FontOutlineFile;
extern NSString* const FontTessellationFile;

// This will be unique to each poemm app, you will need to create a unique property for each different value that appears in the plist

// WTSWTSTMScene.mm
extern NSString* const BgColor;
extern NSString* const PathColor;
extern NSString* const PathWidth;
// WTSWTSTMModel.mm
extern NSString* const PathOffset;
extern NSString* const SwimCloudSize;
extern NSString* const WordSpacing;
extern NSString* const TextColorBg;
extern NSString* const TextColorBgHighlight;
extern NSString* const TextColorFg;
extern NSString* const FollowVelocity;
extern NSString* const MaxPathLength;
extern NSString* const PathSpacing;
extern NSString* const RotationBackVelocity;
extern NSString* const RotationToVelocity;
extern NSString* const SwimVelocity;

// Property name constant of dynamic paramaters
extern NSString* const Orientation;
extern NSString* const UprightAngle;

@interface OKPoEMMProperties : OKAppProperties

// Get the device orientation
+ (UIDeviceOrientation) orientation;

// Keep track of the device orientation (only the ones supported by the app)
+ (void) setOrientation:(UIDeviceOrientation)aOrientation;

// Get the upright angle which is recomputed when the orientation is set
+ (int) uprightAngle;

+ (void) initWithContentsOfFile:(NSString *)aPath;

+ (id) objectForKey:(id)aKey;

+ (void) setObject:(id)aObject forKey:(id)aKey;

// Fills the properties with a loaded package dictionary (Properties-iPhone, Properties-iPhone-Retina, Properties-iPhone-568h, Properties-iPad, Properties-iPad-Retina)
+ (void) fillWith:(NSDictionary*)aTextDict;

+ (void) listProperties;

@end
