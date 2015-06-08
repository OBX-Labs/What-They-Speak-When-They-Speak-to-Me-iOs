//
//  OKPoEMM.h
//  OKPoEMM
//
//  Created by Christian Gratton on 2013-02-04.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OKInfoView;

typedef enum
{
    MenuInfoViewTab=0,
    MenuGuestPoetsTab=1,
    MenuCustomTextsTab=2,
    MenuShareTab=3,
} MenuTab;

@interface OKPoEMM : UIViewController <UIAlertViewDelegate>
{
    // Info View
    OKInfoView *infoView;
    
    // Info View Buttons
    UIButton *lB;
    UIButton *rB;
    NSTimeInterval touchBeganTime;
    NSTimer *toggleViewTimer;
    
    // Exhibition
    BOOL isExhibition;
    // Performance
    BOOL hasPrompted;
}

- (id) initWithFrame:(CGRect)aFrame EAGLView:(UIView*)aEAGLView isExhibition:(BOOL)flag;
- (void) openMenuAtTab:(MenuTab)menuTab;
- (void) setisExhibition:(BOOL)flag;
- (void) setIsPerformance:(BOOL)flag;
- (void) promptForPerformance;

@end
