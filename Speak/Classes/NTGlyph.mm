/*
 *  NTGlyph.mm
 *  WTSWTSTM
 *
 *  Created by Bruno Nadeau on 10-09-15.
 *  Copyright 2010 Obx Labs. All rights reserved.
 *
 */

#include "NTGlyph.h"
#include "NtTextGroup.h"

NTGlyph::NTGlyph() {
	init('\0'); //default null character
}

NTGlyph::NTGlyph(const char& c) {
	init(c);
}

NTGlyph::~NTGlyph() {
	[m_pSprite release];
}

void NTGlyph::init(unsigned short c) {
	m_usChar = c;                   //set the character
	m_pSprite = NULL;               //no sprite yet
	m_SpriteOffset = CGPointZero;	//default offset
	m_iState = UNKNOWN;             //unknown state
	m_fKerning = 0;                 //no kerning
	
	m_fTargetRotation = 0;          //degree
	m_fRotationVelocity = 90;       //degree per second
	m_fNextTargetRotation = 0;      //next target
	m_fNextRotationVelocity = 90;   //next velocity
	
	m_fTargetPositionX = 0;         //target x
	m_fTargetPositionY = 0;         //target y
	m_fTargetPositionVelocity = 0;  //velocity to reach target
	m_bTargetPositionLock = false;  //lock target until reached
	
	m_bLed = false;                 //is glyph led (on the focused line)
}

void NTGlyph::fadeTo(ccColor4B color, const int& speed) {
	if (m_TargetColor.a == color.a && m_TargetColor.r == color.r &&
		m_TargetColor.g == color.g && m_TargetColor.b == color.b)
		return;

    //set the target color
	m_TargetColor = color;
	
    //calculate fade speed
	m_FadeSpeed[0] = (color.r - m_pSprite.color.r)*speed;
	if (m_FadeSpeed[0] < 0) m_FadeSpeed[0] *= -1;
	m_FadeSpeed[1] = (color.g - m_pSprite.color.g)*speed;
    if (m_FadeSpeed[1] < 0) m_FadeSpeed[1] *= -1;
	m_FadeSpeed[2] = (color.b - m_pSprite.color.b)*speed;
	if (m_FadeSpeed[2] < 0) m_FadeSpeed[2] *= -1;
	m_FadeSpeed[3] = (color.a - m_pSprite.opacity)*speed;
	if (m_FadeSpeed[3] < 0) m_FadeSpeed[3] *= -1;
}

void NTGlyph::swimTo(const CGFloat& targetX, const CGFloat& targetY, const CGFloat& velocity, const CGFloat& cloudSize) {
	//if motion isn't done then wait
	if (m_bTargetPositionLock) return;
	
	//get the window size to limit motion
	CGSize size = [[CCDirector sharedDirector] winSize];
	
	//absolute position of the node
	CGPoint absPosition = [m_pSprite.parent convertToWorldSpace:m_pSprite.position];
	
	//difference between target and position
	CGPoint targetDiff = ccp(targetX - absPosition.x, targetY - absPosition.y);
	
	//generate multiplier for some randomness
	CGFloat multiplier = CCRANDOM_0_1();
	
	// new targets are always in the direction of the parent's center
	CGPoint destDiff = CGPointZero;
	if ((-cloudSize <= targetDiff.x) && (targetDiff.x <= cloudSize))
		destDiff.x = multiplier*2*cloudSize-cloudSize;
	else if (-cloudSize > targetDiff.x)
		destDiff.x = multiplier*-cloudSize;
	else
		destDiff.x = multiplier*cloudSize;
	
	multiplier = CCRANDOM_0_1();
	if ((-cloudSize <= targetDiff.y) && (targetDiff.y <= cloudSize))
		destDiff.y = multiplier*2*cloudSize-cloudSize;
	else if (-cloudSize > targetDiff.y)
		destDiff.y = multiplier*-cloudSize;
	else
		destDiff.y = multiplier*cloudSize;
	
	// make sure the next target is inside the window
	CGRect box = [m_pSprite boundingBox];
	CGPoint absDest = ccp(absPosition.x + destDiff.x, absPosition.y + destDiff.y);
	if (absDest.x-box.size.width/2 <= 0)
		destDiff.x += cloudSize;
	else if (absDest.x+box.size.width/2 >= size.width)
		destDiff.x -= cloudSize;
	
	if (absDest.y-box.size.height/2 <= 0)
		destDiff.y += cloudSize;
	else if (absDest.y+box.size.height/2 >= size.height)
		destDiff.y -= cloudSize;

	//set the next hard target
	moveBy(destDiff.x, destDiff.y, velocity, true);
}

void NTGlyph::moveBy(const CGFloat& targetX, const CGFloat& targetY, const CGFloat& velocity, bool mustReachTarget) {
	//if motion isn't done then wait
	if (m_bTargetPositionLock) return;
	
	//set target
	CGPoint absPosition = [m_pSprite.parent convertToWorldSpace:m_pSprite.position];
	m_fTargetPositionX = absPosition.x + targetX;
	m_fTargetPositionY = absPosition.y + targetY;
	m_fTargetPositionVelocity = velocity;
	
	//set the target lock
	m_bTargetPositionLock = mustReachTarget;
}

void NTGlyph::moveTo(const CGFloat& targetX, const CGFloat& targetY, const CGFloat& velocity, bool mustReachTarget) {
	//if motion isn't done then wait
	if (m_bTargetPositionLock) return;

	//set target
	m_fTargetPositionX = targetX;
	m_fTargetPositionY = targetY;
	m_fTargetPositionVelocity = velocity;
	
	//set the target lock
	m_bTargetPositionLock = mustReachTarget;
}

void NTGlyph::updatePosition(float dt) {
	//difference to target
	CGPoint absPosition = [m_pSprite.parent convertToWorldSpace:m_pSprite.position];
	float diffX = m_fTargetPositionX-absPosition.x;
	float diffY = m_fTargetPositionY-absPosition.y;
	float diff = sqrtf(diffX*diffX + diffY*diffY);
	
	//motion for the amount of time spent since last frame
	float delta = m_fTargetPositionVelocity * dt;
	
	//if we reached position, then unlock target if needed
	if (diff < delta) {
		m_pSprite.position = ccp(m_pSprite.position.x + m_fTargetPositionX - absPosition.x,
								 m_pSprite.position.y + m_fTargetPositionY - absPosition.y);
		m_bTargetPositionLock = false;
	}
	//else rotate towards target
	else {
		m_pSprite.position = ccp(m_pSprite.position.x + (diffX/diff)*delta,
								 m_pSprite.position.y + (diffY/diff)*delta);
	}
}

void NTGlyph::followTo(const CGPoint& target, const float& velocity)
{
	//follow has priority so it can override the target lock
	if (m_bTargetPositionLock) m_bTargetPositionLock = false;
	
	//set the next hard target
	moveTo(target.x, target.y, velocity, false);
}

void NTGlyph::rotateTo(const float& angle, const float& velocity) {
	//limit angle to -180 to 180
	float newAngle = angle;
	while(newAngle > 180) newAngle -= 360;
	while(newAngle < -180) newAngle += 360;
	
	//if we hit rotation target then we can process this one
	if (m_pSprite.rotation == m_fTargetRotation) {
		m_fTargetRotation = newAngle;
		m_fRotationVelocity = velocity;
		m_fNextTargetRotation = angle;
		m_fNextRotationVelocity = velocity;
	}
	//if we are rotating, then save for after we reach target
	else {
		m_fNextTargetRotation = newAngle;
		m_fNextRotationVelocity = velocity;
	}
}

void NTGlyph::updateRotation(float dt) {
	//check if we need to rotate
	if (m_pSprite.rotation == m_fTargetRotation) return;
	
	//difference to target
	float diff = m_fTargetRotation-m_pSprite.rotation;
	
	//limit angle to -180 to 180
	while(diff > 180) diff -= 360;
	while(diff < -180) diff += 360;
	
	//find the direction we are going in
	int direction = diff > 0 ? 1 : -1;
	
	//rotation for the amount of time spent since last frame
	float delta = m_fRotationVelocity * dt;
	
	//if we reached rotation, then check if we have
	//a request to another angle to process
	if (diff*direction < delta) {
		m_pSprite.rotation = m_fTargetRotation;
		
		//queue next rotation
		rotateTo(m_fNextTargetRotation, m_fNextRotationVelocity);
	}
	//else rotate towards target
	else {
		m_pSprite.rotation += delta*direction;
	}
}

void NTGlyph::update(float dt) {
	//update position
	updatePosition(dt);
	
	//update rotation
	updateRotation(dt);
	
	//update color/alpha
	updateColor(dt);
}

void NTGlyph::updateColor(float dt) {
	int diff;
	float delta;
	int direction;
	
	ccColor3B newColor = m_pSprite.color;
	
	//red
	diff = m_TargetColor.r - m_pSprite.color.r;
	if (diff != 0) {
		delta = m_FadeSpeed[0] * dt;
		if (delta < 1) delta = 1;
		direction = diff < 0 ? -1 : 1;
		
		if (diff*direction < delta)
			newColor.r = m_TargetColor.r;
		else
			newColor.r += delta*direction;
	}

	//green
	diff = m_TargetColor.g - m_pSprite.color.g;
	if (diff != 0) {
		delta = m_FadeSpeed[1] * dt;
		if (delta < 1) delta = 1;
		direction = diff < 0 ? -1 : 1;
		
		if (diff*direction < delta)
			newColor.g = m_TargetColor.g;
		else
			newColor.g += delta*direction;
	}

	//blue
	diff = m_TargetColor.b - m_pSprite.color.b;
	if (diff != 0) {
		delta = m_FadeSpeed[2] * dt;
		if (delta < 1) delta = 1;
		direction = diff < 0 ? -1 : 1;
		
		if (diff*direction < delta)
			newColor.b = m_TargetColor.b;
		else
			newColor.b += delta*direction;
	}
	
	[m_pSprite setColor:newColor];
	
	//alpha
	diff = m_TargetColor.a - m_pSprite.opacity;
	if (diff != 0) {
		delta = m_FadeSpeed[3] * dt;
		if (delta < 1) delta = 1;
		
		direction = diff < 0 ? -1 : 1;
		
		if (diff*direction < delta)
			m_pSprite.opacity = m_TargetColor.a;
		else
			m_pSprite.opacity += delta*direction;
	}
}

void NTGlyph::setSprite(CCSprite* sprite) {
	//same one, nothing to do
	if (m_pSprite == sprite) return;
	
	//set sprite
	[m_pSprite release];
	m_pSprite = sprite;	
	[m_pSprite retain];
	
	//keep track of the original sprite offset
	m_SpriteOffset.y = [sprite position].y;
}

void NTGlyph::runBackground() {
	//if already in background then do nothing
	if (m_iState == BACKGROUND) return;
	
	//reorder glyph
	[m_pSprite.parent reorderChild:m_pSprite z:0];
	
	//set state
	m_iState = BACKGROUND;
}

void NTGlyph::runForeground() {
	//if already in foreground then do nothing
	if (m_iState == FOREGROUND) return;
	
	//reorder glyph
	[m_pSprite.parent reorderChild:m_pSprite z:10];
	
	//set state
	m_iState = FOREGROUND;
}
