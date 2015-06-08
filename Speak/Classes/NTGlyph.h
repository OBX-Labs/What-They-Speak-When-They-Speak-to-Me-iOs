/*
 *  NTGlyph.h
 *  WTSWTSTM
 *
 *  Created by Bruno Nadeau on 10-09-15.
 *  Copyright 2010 Obx Labs. All rights reserved.
 *
 */

#ifndef NTGLYPH_H
#define NTGLYPH_H

#include "NTTextObject.h"
#import "cocos2d.h"

#define UNKNOWN	   0
#define FOREGROUND 1
#define BACKGROUND 2

//
// Glyph class representing a character.
//
// XXX: This one is a bit of a mess mostly because it's a C++
//      class but it needs to reference Obj-C entities like the
//      CCSprite class from Cocos2D. Because we can have an Obj-C
//      class that extends from a C++ class, the next best thing
//      would be to have the NTGlyph with only C++ code, and a
//      C++ class for each type of visual representation. In this
//      case we would have a base NTGlyph, and a NTCCGlyph that uses
//      elements from Cocos2D (CC).
//
class NTGlyph : public NTTextObject {

private:
	unsigned short m_usChar; //unicode char
	
	CCSprite* m_pSprite;	 //pointer to the cocos sprite tied to this glyph
	CGPoint m_SpriteOffset;	 //original offset of the sprite (use for alignment)
	float m_fKerning;		 //kerning value (this should not be here, it has a use specific to WTSWTSTM)
	
	int m_iState; //BACKGROUND is default, FOREGROUND when dragged
	
	//position properties
	float m_fTargetPositionX;
	float m_fTargetPositionY;
	float m_fTargetPositionVelocity;
	bool m_bTargetPositionLock;
	
	//rotation properties
	float m_fTargetRotation;
	float m_fRotationVelocity;
	float m_fNextTargetRotation;
	float m_fNextRotationVelocity;
	
	//color properties
	ccColor4B m_TargetColor;
	signed short m_FadeSpeed[4];
	
	//true if the glyph is on the leader's line
	bool m_bLed;
	
private:
	//init the glyph with a given character
	void init(unsigned short c);
	
	//update the position
	void updatePosition(float dt);
	
	//update the rotation
	void updateRotation(float dt);
	
	//update the color
	void updateColor(float dt);
	
public:
	//default constructor
	NTGlyph();
	
	//constructor
	NTGlyph(const char& c);
	
	//destructor
	virtual ~NTGlyph();
	
    //get the unicode char
    unsigned short character() { return m_usChar; }
    
	//get a pointer to the sprite tied to this glyph
	CCSprite* sprite() { return m_pSprite; }
	
	//set the pointer to the sprite
	void setSprite(CCSprite* sprite);
	
	//get kerning
	float kerning() { return m_fKerning; }
	
	//set kerning
	void setKerning(float k) { m_fKerning = k; }
	
	//get the sprite offset
	const CGPoint& spriteOffset() { return m_SpriteOffset; }
	
	//update the swim action
	void swimTo(const CGFloat& targetX, const CGFloat& targetY, const CGFloat& velocity, const CGFloat& cloudSize);	
	
	//set the next target for the glyph to move to
	void moveBy(const CGFloat& targetX, const CGFloat& targetY, const CGFloat& velocity, bool mustReachTarget);
	
	//set the next target for the glyph to move to
	void moveTo(const CGFloat& targetX, const CGFloat& targetY, const CGFloat& velocity, bool mustReachTarget);
	
	//set the glyph to run in background mode
	void runBackground();
	
	//update the follow action
	void followTo(const CGPoint& target, const float& velocity);
	
	//set the glyph to run in foreground mode
	void runForeground();

	//rotate to a given angle at a given velocity
	void rotateTo(const float& angle, const float& velocity);
	
	//update the glyph
	void update(float dt);

	//set the alpha to fade to
	void fadeTo(ccColor4B color, const int& speed);
	
	//set as on leader line or not
	void setLed(bool l) { m_bLed = l; }
	
	//check if on leader line
	bool isLed() { return m_bLed; }
						
};

#endif //NTGLYPH_H