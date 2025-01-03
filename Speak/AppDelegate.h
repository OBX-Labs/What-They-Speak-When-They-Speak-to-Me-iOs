//
//  AppDelegate.h
//  Speak
//
//  Created by Christian Gratton on 2013-04-24.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cocos2d.h"

@class OKPoEMM;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) OKPoEMM *poemm;

- (void) setDefaultValues;
- (void) loadOKPoEMMInFrame:(CGRect)frame;

@end
