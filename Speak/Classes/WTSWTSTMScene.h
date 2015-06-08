//
//  WTSWTSTMScene.h
//  WTSWTSTM
//
//  Created by Bruno Nadeau on 10-09-13.
//  Copyright 2010 Obx Labs. All rights reserved.
//

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

//define the c++ WTSWTSTMModel
//to use it as an attribute
struct WTSWTSTMModel;
typedef struct WTSWTSTMModel WTSWTSTMModel;

//
// WTSWTSTM Layer used by Cocos2D to manage the core of the app.
//
@interface WTSWTSTM : CCLayer
{
	WTSWTSTMModel* model;    //the model
    BOOL skippedFirstUpdate; 
    
	float* pathColor;		//color of the path
	float pathSpacing;		//spacing of each points in the path
	float pathWidth;		//width of the path lines
	//unsigned int maxPathLength; //max number of points in the path
	float* bgColor;

	//we want to hide the info view right away when
	//the user touches the text, but only the first time
	BOOL hidFirstInfo;
	
	//int tapCount;		//number of consecutive taps
	//NSTimer* tapTimer;  //tap timer
	CGPoint lastTap;	//location of the last tap
	
	NSTimeInterval touchBeganTime; //when the last touch began

	//draw path variables
	CGPoint start;
	CGPoint ctrl;
	//float pathFade;
	BOOL bSkipCurve;
	
#ifdef DEBUG
	BOOL debugDrawBoxes; //true to render boxes around words
#endif
}

// returns a Scene that contains the HelloWorld as the only child
+(id) scene;

//-(void) initModel;

-(void) draw;		//draw the scene
-(void) drawPath;	//draw the path
-(void) update:(ccTime)dt; //update the scene

#ifdef DEBUG
-(void) drawDebug;  //draw the debug layer
#endif

//handle touches
-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event;
-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event;
-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event;
-(void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event;

@end
