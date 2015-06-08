/*
 *  NTTextGroup.h
 *  WTSWTSTM
 *
 *  Created by Bruno Nadeau on 10-09-15.
 *  Copyright 2010 Obx Labs. All rights reserved.
 *
 */

#ifndef NTTEXTGROUP_H
#define NTTEXTGROUP_H

#include "NTTextObject.h"

#include <vector>
using namespace std;

//
// Text group object to group other text object together.
//
class NTTextGroup : public NTTextObject {

private:
	//children text object
	vector<NTTextObject*> m_pChildren;
	
public:
	//constructor
	NTTextGroup();
	
	//destructor
	virtual ~NTTextGroup();
	
	//get a reference to the children
	vector<NTTextObject*>& children() { return m_pChildren; }
	
	//add a child
	void addChild(NTTextObject* pChild);
	
	//get the bounding box of the group
	CGRect boundingBox();
	
	//get the center of the group
	CGPoint center();
};

#endif //NTTEXTGROUP_H