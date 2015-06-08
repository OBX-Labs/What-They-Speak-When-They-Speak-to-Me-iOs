/*
 *  NTTextGroup.mm
 *  WTSWTSTM
 *
 *  Created by Bruno Nadeau on 10-09-15.
 *  Copyright 2010 Obx Labs. All rights reserved.
 *
 */

#include "NTTextGroup.h"
#include "NTGlyph.h"
#import "cocos2d.h"

NTTextGroup::NTTextGroup() {
}

NTTextGroup::~NTTextGroup() {
	//delete children
	for(unsigned int i = 0; i < m_pChildren.size(); i++)
		delete m_pChildren[i];
	//clear vector
	m_pChildren.clear();
}

void NTTextGroup::addChild(NTTextObject* pChild) {
	if (pChild == NULL) return;
	
	//TODO make sure the child isn't already in the list
	m_pChildren.push_back(pChild);
	
	//set the child's parent
	pChild->setParent(this);
}

CGRect NTTextGroup::boundingBox() {
	//go through children and get the union of their bounding boxes
	NTGlyph* pChild;
	CCSprite* sprite;
	CGRect targetBox = CGRectNull;
	for(unsigned int i = 0; i < m_pChildren.size(); i++)
	{
		pChild = (NTGlyph*)m_pChildren.at(i);
		sprite = pChild->sprite();
		
		CGRect childBox = [sprite boundingBox];
		CGPoint absPos = [sprite.parent convertToWorldSpace: sprite.position];
		CGRect absChildBox = CGRectMake(absPos.x - childBox.size.width/2, absPos.y-childBox.size.height/2,
										childBox.size.width, childBox.size.height);
		targetBox = CGRectUnion(targetBox, absChildBox);
	}
	
	return targetBox;
}

CGPoint NTTextGroup::center() {
	//go through children and get the center position
    NTGlyph* pChild;
	CCSprite* sprite;
	CGPoint centerPt = CGPointZero;
	CGPoint absPos;
	
	unsigned int numChildren = m_pChildren.size();
	for(unsigned int i = 0; i < numChildren; i++)
	{
		pChild = (NTGlyph*)m_pChildren.at(i);
		sprite = pChild->sprite();
		
		absPos = [sprite.parent convertToWorldSpace: sprite.position];
		
		centerPt.x += absPos.x;
		centerPt.y += absPos.y;
	}
	
	centerPt.x /= numChildren;
	centerPt.y /= numChildren;
	return centerPt;
}