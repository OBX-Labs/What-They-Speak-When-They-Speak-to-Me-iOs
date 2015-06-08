/*
 *  WTSWTSTMModel.mm
 *  WTSWTSTM
 *
 *  Created by Bruno Nadeau on 10-09-16.
 *  Copyright 2010 Obx Labs. All rights reserved.
 */

#include "WTSWTSTMModel.h"

#import "OKPoEMMProperties.h"

WTSWTSTMModel::WTSWTSTMModel() {
	init(NULL, NULL, 0, 0);
}

WTSWTSTMModel::WTSWTSTMModel(const char* pText, const CCLabelBMFont* pAtlas, int iWidth, int iHeight) {
	init(pText, pAtlas, iWidth, iHeight);
}

WTSWTSTMModel::~WTSWTSTMModel() {
	delete m_pRoot;
}

void WTSWTSTMModel::init(const char* pText, const CCLabelBMFont* pAtlas, int iWidth, int iHeight) {
	//init defaults
	m_pRoot = NULL;
	m_pLeader = NULL;
	m_pLeaderLine = NULL;
	
	//load values from application properties (different for iPad and iPhone/iPod)
    m_iPathOffset = [(NSNumber*)[OKPoEMMProperties objectForKey:PathOffset] intValue];
    m_fSwimVelocity = [(NSNumber*)[OKPoEMMProperties objectForKey:SwimVelocity] intValue];
	m_fSwimCloudSize = [(NSNumber*)[OKPoEMMProperties objectForKey:SwimCloudSize] floatValue];
    m_fFollowVelocity = [(NSNumber*)[OKPoEMMProperties objectForKey:FollowVelocity] floatValue];
    m_fRotationToVelocity = [(NSNumber*)[OKPoEMMProperties objectForKey:RotationToVelocity] floatValue];
    m_fRotationBackVelocity = [(NSNumber*)[OKPoEMMProperties objectForKey:RotationBackVelocity] floatValue];
    m_iPathSpacing = [(NSNumber*)[OKPoEMMProperties objectForKey:PathSpacing] intValue];
    m_iWordSpacing = [(NSNumber*)[OKPoEMMProperties objectForKey:WordSpacing] intValue];
    m_maxPathLength = [(NSNumber*)[OKPoEMMProperties objectForKey:MaxPathLength] intValue];

	NSArray* clrProp = [OKPoEMMProperties objectForKey:TextColorBg];
	m_TextColorBg = ccc4([((NSNumber*)[clrProp objectAtIndex:0]) floatValue]*255,
						 [((NSNumber*)[clrProp objectAtIndex:1]) floatValue]*255,
						 [((NSNumber*)[clrProp objectAtIndex:2]) floatValue]*255,
						 [((NSNumber*)[clrProp objectAtIndex:3]) floatValue]*255);
	
	clrProp = [OKPoEMMProperties objectForKey:TextColorBgHighlight];
	m_TextColorBgHighlight = ccc4([((NSNumber*)[clrProp objectAtIndex:0]) floatValue]*255,
								  [((NSNumber*)[clrProp objectAtIndex:1]) floatValue]*255,
								  [((NSNumber*)[clrProp objectAtIndex:2]) floatValue]*255,
								  [((NSNumber*)[clrProp objectAtIndex:3]) floatValue]*255);
	
	clrProp = [OKPoEMMProperties objectForKey:TextColorFg];
	m_TextColorFg = ccc4([((NSNumber*)[clrProp objectAtIndex:0]) floatValue]*255,
						 [((NSNumber*)[clrProp objectAtIndex:1]) floatValue]*255,
						 [((NSNumber*)[clrProp objectAtIndex:2]) floatValue]*255,
						 [((NSNumber*)[clrProp objectAtIndex:3]) floatValue]*255);
    
    //attributes for reading guide
    m_TextColorNextLine = ccc4(247.0, 153.0, 16.0, 76.5);
    nextLine = 0;
	
	//check if we have a text and an atlas
	//if not we're done
	if (pText == NULL) return;
	if (pAtlas == NULL) return;
	
	//init the text hierarchy and the graphic properties
	initHierarchy(pText, pAtlas);
	initGraphics(iWidth, iHeight);
}

void WTSWTSTMModel::initHierarchy(const char* pText, const CCLabelBMFont* pAtlas) {
	//create the root
	m_pRoot = new NTTextGroup();
	
	//copy the text string and split into lines
	string strText(pText);
	vector<string> lines;
	tokenize(strText, lines, "\r\n");
	
	//glyph counter to link with sprites
	unsigned int gCount = 0;
	
	//pointer to the last glyph to calculate kerning
	NTGlyph* lastGlyph = NULL;
	
	//parse text to hierarchy
	for(unsigned int i = 0; i < lines.size(); i++) {
		//create the group for the line
		NTTextGroup* pLineGroup = new NTTextGroup();
		
		//get the line
		string strLine = lines.at(i);
		
		//parse into words
		vector<string> words;
		tokenize(strLine, words, " ");
		for(unsigned int j = 0; j < words.size(); j++) {
			//create the group for the word
			NTTextGroup* pWordGroup = new NTTextGroup();
			
			//get the word
			string strWord = words.at(j);

			//parse into glyphs
			for(unsigned int k = 0; k < strWord.length(); k++) {
				//create the glyph
				NTGlyph* pGlyph = new NTGlyph(strWord[k]);
				
				//linked the sprite with the glyph
				pGlyph->setSprite((CCSprite*)[pAtlas getChildByTag:gCount++]);
				
				//calculate kerning based on last glyph position
				if (lastGlyph != NULL) {
                    lastGlyph->setKerning(pGlyph->sprite().position.x - lastGlyph->sprite().position.x -
										  CGRectGetWidth(lastGlyph->sprite().textureRect) - 1);
                }
				
				//keep track of last glyph
				lastGlyph = pGlyph;
				
				//add the glyph to the word
				pWordGroup->addChild(pGlyph);
			}
            
			//add the word to the line
			pLineGroup->addChild(pWordGroup);
		}
		
		//add the line to the root
		m_pRoot->addChild(pLineGroup);
	}
}

void WTSWTSTMModel::initGraphics(unsigned int width, unsigned int height) {
	//iterator through hierarchy and place words around
	vector<NTTextObject*>& lines = m_pRoot->children();
	for(unsigned int i = 0; i < lines.size(); i++) {
		NTTextGroup* pLineGroup = (NTTextGroup*)lines.at(i);
		vector<NTTextObject*>& words = pLineGroup->children();
		for(unsigned int j = 0; j < words.size(); j++) {
			NTTextGroup* pWordGroup = (NTTextGroup*)words.at(j);
			
			//compuate a random offset for the word
			float offsetX = width*CCRANDOM_0_1();
			float offsetY = height*CCRANDOM_0_1();
			
			//position of the first glyph
			bool bFoundFirst = false;
			float firstX = 0;
			float firstY = 0;
			
			//go through glypphs and set their properties
			vector<NTTextObject*>& glyphs = pWordGroup->children();
			for(unsigned int k = 0; k < glyphs.size(); k++) {
				//get the glyph
				NTGlyph* pGlyph = (NTGlyph*)glyphs.at(k);
				
				//get the sprite tied to the glyph
				CCSprite* sprite = pGlyph->sprite();
				
				//get the glyph's position
				float gX = [pGlyph->sprite() position].x;
				float gY = [pGlyph->sprite() position].y;					

				//if we haven't found the first glyph yet
				//then save its position
				if (!bFoundFirst) {
					firstX = gX;
					firstY = gY;
					bFoundFirst = true;
				}
				
				//calculate the new position
				CGPoint newPos = [sprite.parent convertToNodeSpace:ccp(offsetX + gX-firstX, offsetY + gY-firstY)];
				[pGlyph->sprite() setPosition:newPos];
				[pGlyph->sprite() setOpacity:0];
				[pGlyph->sprite() setColor:ccc3(m_TextColorBg.r, m_TextColorBg.g, m_TextColorBg.b)];
				
				//set the glyph's rotation (random)
				[pGlyph->sprite() setRotation:(360*CCRANDOM_0_1() - 180)];
				pGlyph->runBackground();
			}
		}
	}
}

void WTSWTSTMModel::clearPath()
{
    //clear the path
    m_pPath.clear();
    //then reset the max length in case it was extended
    m_maxPathLength = [(NSNumber*)[OKPoEMMProperties objectForKey:MaxPathLength] intValue];
}

void WTSWTSTMModel::tokenize(const string& str,
							 vector<string>& tokens,
							 const string& delimiters)
{
	// Skip delimiters at beginning.
	string::size_type lastPos = str.find_first_not_of(delimiters, 0);
	// Find first "non-delimiter".
	string::size_type pos     = str.find_first_of(delimiters, lastPos);
	
	while (string::npos != pos || string::npos != lastPos)
	{
		// Found a token, add it to the vector.
		tokens.push_back(str.substr(lastPos, pos - lastPos));
		// Skip delimiters.  Note the "not_of"
		lastPos = str.find_first_not_of(delimiters, pos);
		// Find next "non-delimiter"
		pos = str.find_first_of(delimiters, lastPos);
	}
}

NTGlyph* WTSWTSTMModel::setLeaderAt(float x, float y)
{
    //find the leader
    return setLeader(closestGlyphTo(x, y));
}

NTGlyph* WTSWTSTMModel::setLeader(NTGlyph* pGlyph) {
  	//same leader nothing to do
	if (m_pLeader == pGlyph) return pGlyph;
	
	//clear previous leader
	setLedGlyphs(m_pLeaderLine, false);
	m_pLeader = NULL;
	m_pLeaderLine = NULL;
    
	//if the new leader is null, we only need to clear
	if ((pGlyph == NULL) || (pGlyph->parent() == NULL))
		return pGlyph;
	
	//find and set the parent line of the leader glyph
	m_pLeaderLine = pGlyph->parent()->parent();
	if (m_pLeaderLine == NULL)
		return pGlyph;
    
	//set the leader
	m_pLeader = pGlyph;
	setLedGlyphs(m_pLeaderLine, true);
    
    return pGlyph;
}

NTGlyph* WTSWTSTMModel::setNextLeader()
{
    //get the next leader
    vector<NTTextObject*>& lines = m_pRoot->children();
    NTTextGroup* pLineGroup = (NTTextGroup*)lines.at(nextLine);
    vector<NTTextObject*>& words = pLineGroup->children();
    NTTextGroup* pWordGroup = (NTTextGroup*)words.at(0);
    vector<NTTextObject*>& glyphs = pWordGroup->children();
    NTGlyph* pGlyph = (NTGlyph*)glyphs.at(0);
    
	//same leader nothing to do
	if (m_pLeader == pGlyph) return NULL;
	
	//clear previous leader
	setLedGlyphs(m_pLeaderLine, false);
	m_pLeader = NULL;
	m_pLeaderLine = NULL;
    
	//if the new leader is null, we only need to clear
	if ((pGlyph == NULL) || (pGlyph->parent() == NULL))
		return NULL;
	
	//find and set the parent line of the leader glyph
	m_pLeaderLine = pGlyph->parent()->parent();
	if (m_pLeaderLine == NULL)
		return NULL;
    
 
    nextLine++;
    if(nextLine == lines.size()) nextLine = 0;
    
	//set the leader
	m_pLeader = pGlyph;
	setLedGlyphs(m_pLeaderLine, true);
}

void WTSWTSTMModel::setLedGlyphs(NTTextGroup* pLineGroup, bool led) {
	if (pLineGroup == NULL) return;
	
	NTTextGroup* pWordGroup;
	NTGlyph* pGlyph;
	
    //go through the group's glyphs and set their 'led' property
	vector<NTTextObject*>& words = pLineGroup->children();
	for(unsigned int j = 0; j < words.size(); j++) {
		pWordGroup = (NTTextGroup*)words.at(j);
		vector<NTTextObject*>& glyphs = pWordGroup->children();
		for(unsigned int k = 0; k < glyphs.size(); k++) {
			pGlyph = (NTGlyph*)glyphs.at(k);
			pGlyph->setLed(led);
		}
	}
}

void WTSWTSTMModel::update(float dt)
{
	//flag true when we found the leader
	//all glyphs after that are in the same line should follow path
	bool bFoundLeader = false;
	CGPoint currPt = CGPointZero;
	CGPoint lastPt = CGPointZero;
	CGPoint ptDiff = CGPointZero;
	float nextStep = 0;
    
    bool bGuide = [[NSUserDefaults standardUserDefaults] boolForKey:@"isPerformance"];
	
	//check the device orientation to move text accordingly
	int upAngle = [OKPoEMMProperties uprightAngle];
	UIDeviceOrientation orientation = [OKPoEMMProperties orientation];
	
	//path iterator
	list<CGPoint>::reverse_iterator it = m_pPath.rbegin();
	for(int i = 0; (i < m_iPathOffset) && (it != m_pPath.rend()); i++) {
		lastPt = *it;
		it++;
	}
	
	//reserve space for variables
	NTTextGroup* pLineGroup = NULL;
	NTTextGroup* pWordGroup = NULL;
	NTGlyph* pGlyph = NULL;
	CGPoint swimTarget;
	
	//iterator through hierarchy and update frame
	vector<NTTextObject*>& lines = m_pRoot->children();
	for(unsigned int i = 0; i < lines.size(); i++) {
		pLineGroup = (NTTextGroup*)lines.at(i);
		vector<NTTextObject*>& words = pLineGroup->children();
		for(unsigned int j = 0; j < words.size(); j++) {
			pWordGroup = (NTTextGroup*)words.at(j);
			vector<NTTextObject*>& glyphs = pWordGroup->children();
			
			//calculate the bounding box for the swim behavior
			//we only need it if the word is not on the leader line
			if (pLineGroup != m_pLeaderLine)
				swimTarget = pWordGroup->center();
			
			for(unsigned int k = 0; k < glyphs.size(); k++) {
				pGlyph = (NTGlyph*)glyphs.at(k);

				//if glyph is not on the leader's line
				if (!pGlyph->isLed()) {
					//update the swim action
					pGlyph->swimTo(swimTarget.x, swimTarget.y,
								   m_fSwimVelocity, m_fSwimCloudSize);
					
					//get the slope of the path and update rotation
					pGlyph->rotateTo(upAngle, m_fRotationBackVelocity + (k%10)*2);
					
					//fade
                    /*if(bGuide && i == nextLine && j==0 && k==0)
                        pGlyph->fadeTo(m_TextColorNextLine, 2);
					else */
                    // In version 3.1.0 Jason has asked to remove the highlight color for the next line
                    if (j==0 && k==0)
						pGlyph->fadeTo(m_TextColorBgHighlight, 1);
					else
						pGlyph->fadeTo(m_TextColorBg, 1);
					
					//run background actions
					pGlyph->runBackground();
				}
				//if it is on the leader path
				else {
					//update move to path action
					if (pGlyph == m_pLeader)
						bFoundLeader = true;
					
					//if we found the leader then follow path
					if (bFoundLeader) {
						
						if (it != m_pPath.rend()) {
							//get the offset to position the sprite above the line
							CGPoint spriteOffset = CGPointZero;
							if (orientation == UIDeviceOrientationLandscapeLeft) {
								spriteOffset = CGPointMake(pGlyph->spriteOffset().y, pGlyph->spriteOffset().x);
							}
							else if (orientation == UIDeviceOrientationLandscapeRight) {
								spriteOffset = CGPointMake(-pGlyph->spriteOffset().y, -pGlyph->spriteOffset().x);
							}
							else if (orientation == UIDeviceOrientationPortrait) {
								spriteOffset = CGPointMake(pGlyph->spriteOffset().x, pGlyph->spriteOffset().y);
							}
							else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
								spriteOffset = CGPointMake(pGlyph->spriteOffset().x, -pGlyph->spriteOffset().y);
							}
							
							//get the difference between the current and last point
							ptDiff = CGPointMake((*it).x-lastPt.x, (*it).y-lastPt.y);
							
							//get the current point based on the last glyph variables
							currPt = CGPointMake(lastPt.x + ptDiff.x/m_iPathSpacing*nextStep + spriteOffset.x,
												 lastPt.y + ptDiff.y/m_iPathSpacing*nextStep + spriteOffset.y);

							//get the next point on the path
							//adjust target to match glyph's zero point					
							pGlyph->followTo(currPt, m_fFollowVelocity);
							
							//advance the nextStep and path point for the next glyph
							nextStep += CGRectGetWidth([pGlyph->sprite() textureRect]) + (int)pGlyph->kerning();
							while((nextStep >= m_iPathSpacing) && (it != m_pPath.rend())) {
								nextStep -= m_iPathSpacing;
								lastPt = *it;
								it++;
							}
							
							//get the slope of the path based on orientation
							float angle = 0;
							if (orientation == UIDeviceOrientationLandscapeLeft) {
								angle = atan2(ptDiff.x, -ptDiff.y);
							}
							else if (orientation == UIDeviceOrientationLandscapeRight) {
								angle = atan2(ptDiff.x, -ptDiff.y);
							}
							else if (orientation == UIDeviceOrientationPortrait) {
								angle = atan2(ptDiff.y, ptDiff.x);
							}
							else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
								angle = atan2(ptDiff.y, ptDiff.x);
							}
														
							//convert from -PI:PI to 0:2PI
							if (angle < 0) angle += TWO_PI;
							
							//limit the rotations to the 1st and 4th quadrants 
							//so that the glyphs are always readable
							if ((angle < PI/3*4) && (angle > PI/3*2)) angle += PI;
							
							//convert to degrees
							angle = CC_RADIANS_TO_DEGREES(angle);
							
							//adjust for orientaion
							angle = -angle + upAngle;
							
							//rotate
							pGlyph->rotateTo(angle, m_fRotationToVelocity);
						}
                        else if (m_pPath.size() >= m_maxPathLength) {
                            //NSLog(@"sorry, no more points on the path");
                            m_maxPathLength++;
                        }
						
						//fade
						pGlyph->fadeTo(m_TextColorFg, 2);

						//run foreground actions
						pGlyph->runForeground();
					}
				}
				
				//update the glyph
				pGlyph->update(dt);
			}
			
			//make space for spaces
			if (bFoundLeader) {
				//advance the nextStep and path point for the next glyph
				nextStep += m_iWordSpacing;
				while(nextStep >= m_iPathSpacing && it != m_pPath.rend()) {
					nextStep -= m_iPathSpacing;
					lastPt = *it;
					it++;
				}
			}
		}
	}	
}

NTGlyph* WTSWTSTMModel::closestGlyphTo(float x, float y)
{
	CGPoint location = CGPointMake(x, y);
	float minDistance = FLT_MAX;
	NTGlyph* pClosest = NULL;
	
	//iterator through hierarchy to find the closest glyph
	vector<NTTextObject*>& lines = m_pRoot->children();
	for(unsigned int i = 0; i < lines.size(); i++) {
		NTTextGroup* pLineGroup = (NTTextGroup*)lines.at(i);
		vector<NTTextObject*>& words = pLineGroup->children();
		for(unsigned int j = 0; j < words.size(); j++) {
			NTTextGroup* pWordGroup = (NTTextGroup*)words.at(j);
			vector<NTTextObject*>& glyphs = pWordGroup->children();
			for(unsigned int k = 0; k < glyphs.size(); k++) {
				NTGlyph* pGlyph = (NTGlyph*)glyphs.at(k);

				//get the glyph's box
				CGRect gBox = [pGlyph->sprite() boundingBox];
				
				//convert location to glyph coordinate
				CGPoint relLocation = [pGlyph->sprite().parent convertToNodeSpace:location];
				
				//check if the location is on the glyph
				if (CGRectContainsPoint(gBox, relLocation))
					return pGlyph;
				
				//check if the glyph is closest than previous ones
				CGPoint diff = CGPointMake(CGRectGetMidX(gBox) - relLocation.x, CGRectGetMidY(gBox) - relLocation.y);
				float dist = sqrtf(diff.x*diff.x + diff.y*diff.y);
				if (dist < minDistance) {
					minDistance = dist;
					pClosest = pGlyph;
				}
			}
		}
	}	
	
	return pClosest;
}
