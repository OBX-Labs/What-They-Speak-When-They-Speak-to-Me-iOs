//
//  WTSWTSTMScene.m
//  WTSWTSTM
//
//  Created by Bruno Nadeau on 10-09-13.
//  Copyright 2010 Obx Labs. All rights reserved.
//

// Import the interfaces
#import "WTSWTSTMScene.h"
#import <OBXKit/AppDelegate.h>
#import "WTSWTSTMModel.h"


#import "OKPoEMMProperties.h"
#import "OKTextManager.h"

#define DEBUG_DRAW_BOXES NO

// WTSWTSTM implementation
@implementation WTSWTSTM

+(id) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	WTSWTSTM *layer = [WTSWTSTM node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		
		//get the path color from the plist
        NSArray* clrProp = [OKPoEMMProperties objectForKey:PathColor];
		pathColor = new float[4];
		for(int i = 0; i < 4; i++)
			pathColor[i] = [((NSNumber*)[clrProp objectAtIndex:i]) floatValue];
		
		//get the letter spacing from the plist
        pathSpacing = [(NSNumber*)[OKPoEMMProperties objectForKey:PathSpacing] intValue];
		
		//get the width of the path
		pathWidth = [(NSNumber*)[OKPoEMMProperties objectForKey:PathWidth] floatValue] * [[CCDirector sharedDirector] contentScaleFactor];
        
		//get the max path length from the plist
		//maxPathLength = [(NSNumber*)[WTSWTSTMProperties objectForKey:WTSMaxPathLength] intValue];
			
		//compute the rate at which the path fades
		//pathFade = pathColor[3]/maxPathLength;

		//get the background color from the plist
        clrProp = [OKPoEMMProperties objectForKey:BgColor];
		bgColor = new float[4];
		for(int i = 0; i < 4; i++)
			bgColor[i] = [((NSNumber*)[clrProp objectAtIndex:i]) floatValue];

		//set background color
		glClearColor(bgColor[0], bgColor[1], bgColor[2], bgColor[3]);

        // ask director the the window size
        CGSize size = [[CCDirector sharedDirector] winSize];
        
        NSString *path;
        NSString *text;

        if(![OKPoEMMProperties objectForKey:TextFile]) {
            path = [OKTextManager textPathForFile:[OKPoEMMProperties objectForKey:TextFile] inPackage:[OKPoEMMProperties objectForKey:Text]];
        } else {
            path = [OKTextManager textPathForFile:[OKPoEMMProperties objectForKey:TextFile] inPackage:[OKPoEMMProperties objectForKey:Text]];
        }
                
        //read the text file
        NSError* err = nil;
        NSStringEncoding* encoding = nil;
        text = [NSString stringWithContentsOfFile:path usedEncoding:encoding error:&err];

        if(!text) text = @" "; // failsafe
        
		//create the label for the text
		NSString *cleanText = [[text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                               componentsJoinedByString:@""];

        NSString *fontName = [OKPoEMMProperties objectForKey:FontFile];
        
        // Check if the app supports retina fonts
        if([OKPoEMMProperties doesSupportsRetinaFonts])
        {
            // check if it exists
            if([OKTextManager fontFileExists:[fontName stringByAppendingString:@"@2x"] ofType:@"fnt"]) fontName = [fontName stringByAppendingString:@"@2x"];
        }
        
		NSString *fntFile = [OKTextManager fontPathForFile:fontName ofType:@"fnt"];
                
        if(![OKPoEMMProperties objectForKey:FontFile]) {
            
            if([OKPoEMMProperties isiPad])
                fntFile = ([OKPoEMMProperties isRetina] ? @"gilsanbo36@2x" : @"gilsanbo36");
            else
                fntFile = ([OKPoEMMProperties isRetina] ? @"gilsanbo18@2x" : @"gilsanbo18");
            
            [OKPoEMMProperties setObject:fntFile forKey:FontFile];
            fntFile = [OKTextManager fontPathForFile:[OKPoEMMProperties objectForKey:FontFile] ofType:@"fnt"];
        }
        
        //TFLog(@"Using font file: %@", fntFile);
		CCLabelBMFont *label = [CCLabelBMFont labelWithString:cleanText
													  fntFile:fntFile];
		
		//create the model
        const char* debugC;
        if([text canBeConvertedToEncoding:NSISOLatin1StringEncoding]){
            debugC = [text cStringUsingEncoding:NSISOLatin1StringEncoding];
        } else if([text canBeConvertedToEncoding:NSUTF8StringEncoding]) {
            debugC = [text cStringUsingEncoding:NSUTF8StringEncoding];
        } else {
            //That should not happen.
            debugC = (const char*)[text dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES];
        }
		model = new WTSWTSTMModel(debugC, label, size.width, size.height);
		skippedFirstUpdate = YES; //skip the first update, this fixed a flicker problem on older iOS versions
        
        //delete debugC;
        
		//add the text to the scene
		//the positions of the letters are handled in the model and the update method
		[self addChild:label];
					
        // register to receive targeted touch events
        [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self
														 priority:10
												  swallowsTouches:YES];
		
		// schedule a repeating callback on every frame
        [self scheduleUpdate];
		
#ifdef DEBUG
		debugDrawBoxes = DEBUG_DRAW_BOXES; //flag to draw debug boxes
#endif
	}
	return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// clean up model
	delete model;
	
	// clean up path color
	delete pathColor;
	
	// clean up background color
	delete bgColor;
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

// draw frame (overlay)
-(void)draw
{
	//draw the touch path
	[self drawPath];
	
#ifdef DEBUG
	//draw debug layer
	if (debugDrawBoxes) [self drawDebug];
#endif
}

- (void)drawPath
{
	//get a reference to path
	list<CGPoint>& path = model->path();
    
    //make sure we have enough points
	int pathSize = path.size();
	if (pathSize < 3) return;
	
	//setup opengl to draw lines
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_LINE_SMOOTH);
	glHint (GL_LINE_SMOOTH_HINT, GL_NICEST);
    glLineWidth(pathWidth);
	
	//init variables
	list<CGPoint>::iterator it = path.begin();
	start = *it++;
	ctrl = *it++;
	bSkipCurve = FALSE;
	
	//draw path
    float pathFade = pathColor[3]/model->maxPathLength();
	for (int i = pathSize; it != model->path().end(); it++, i--) {
		glColor4f(pathColor[0], pathColor[1], pathColor[2], pathColor[3] - i*pathFade);  
		ccDrawLine(start, *it);

		if (!bSkipCurve)
			ccDrawQuadBezier(start, ctrl, *it, pathSpacing/2);

		start = ctrl;
		ctrl = *it;
		bSkipCurve = !bSkipCurve;
	}
	
	//reset blend function
	glBlendFunc(CC_BLEND_SRC, CC_BLEND_DST);	
}

#ifdef DEBUG
- (void)drawDebug {
	//iterator through hierarchy and update frame
	vector<NTTextObject*>& lines = model->root()->children();
	for(unsigned int i = 0; i < lines.size(); i++) {
		NTTextGroup* pLineGroup = (NTTextGroup*)lines.at(i);
		vector<NTTextObject*>& words = pLineGroup->children();
		for(unsigned int j = 0; j < words.size(); j++) {
			NTTextGroup* pWordGroup = (NTTextGroup*)words.at(j);
			
			//get the bounding box
			CGRect box = pWordGroup->boundingBox();
			CGPoint center = ccp(CGRectGetMidX(box), CGRectGetMidY(box));

			//draw the box
			glEnable(GL_LINE_SMOOTH);
			glColor4ub(255, 0, 255, 255);
			glLineWidth(1);
			CGPoint vertices[] = { ccp(box.origin.x,box.origin.y),
								   ccp(box.origin.x,box.origin.y+box.size.height),
								   ccp(box.origin.x+box.size.width,box.origin.y+box.size.height),
								   ccp(box.origin.x+box.size.width,box.origin.y) };
			ccDrawPoly(vertices, 4, YES);
			
			glColor4ub(0, 255, 255, 255);
			ccDrawPoint(center);
		}
	}		
}
#endif

// update on every frame
- (void)update:(ccTime)dt
{
    //create the model
    if (!skippedFirstUpdate) {
        skippedFirstUpdate = true;
        return;
    }
    
	//update the model
	model->update(dt);
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	//if the path is not empty then we already started
	if (!model->path().empty()) return NO;

	//save the touch start time to detect swipe
	touchBeganTime = touch.timestamp;
	
	//get the absolute location of the touch
	CGPoint location = [touch locationInView: [touch view]];
	CGPoint convertedLocation = [[CCDirector sharedDirector] convertToGL:location];
	
	//find the leader (on or closest glyph)
	bool bGuide = [[NSUserDefaults standardUserDefaults] boolForKey:@"isPerformance"];
    NTGlyph* pLeader = NULL;
    if (bGuide)
        pLeader = model->setNextLeader();
    else
        pLeader = model->setLeaderAt(convertedLocation.x, convertedLocation.y);
	
	//if we didn't find a leader then forget the touch
	if (pLeader == NULL) return NO;
	
	//init path
	model->path().clear();
	model->path().push_back(convertedLocation);
	
	//accept only if path does not already exists
	return YES;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	//get the absolution location of the touch
	CGPoint location = [touch locationInView: [touch view]];
	CGPoint convertedLocation = [[CCDirector sharedDirector] convertToGL:location];
	
	//add point
	CGPoint lastPoint = model->path().back();
	CGPoint lastDiff = CGPointMake(convertedLocation.x-lastPoint.x, convertedLocation.y-lastPoint.y);
	float distance = sqrtf(lastDiff.x*lastDiff.x + lastDiff.y*lastDiff.y);
	
	// add interpolating points up until the current point over the distance from the last path point
	int pts = (int)(distance/pathSpacing);
	for (int i = 0; i < pts; i++) {
		//limit the number of points in the path
        
		if (model->path().size() >= model->maxPathLength()) {
			model->path().pop_front();
			model->path().pop_front();
			model->path().pop_front();
			model->path().pop_front();
		}
		
		//add the new point to the path
		model->path().push_back(CGPointMake((int)(lastDiff.x/distance*pathSpacing*(i+1) + lastPoint.x),
											(int)(lastDiff.y/distance*pathSpacing*(i+1) + lastPoint.y)));
	}
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{	
	//clean up path
	model->clearPath();
	
	//reset leader
	model->setLeader(NULL);
}

- (void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	//clean up path
	model->path().clear();
	
	//reset leader
	model->setLeader(NULL);
}
	
@end
