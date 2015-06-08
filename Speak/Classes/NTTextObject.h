/*
 *  NTTextObject.h
 *  WTSWTSTM
 *
 *  Created by Bruno Nadeau on 10-09-15.
 *  Copyright 2010 Obx Labs. All rights reserved.
 */

#ifndef NTTEXTOBJECT_H
#define NTTEXTOBJECT_H

class NTTextGroup;

//
// Generic text object class.
//
class NTTextObject {
	NTTextGroup* m_pParent; //parent text object
	
public:
	//constructoir
	NTTextObject();
	
	//destructor
	virtual ~NTTextObject();
	
	//get the parent
	NTTextGroup* parent() { return m_pParent; }
	
	//set the parent
	void setParent(NTTextGroup* parent) { m_pParent = parent; }
	
	//check if the object is a descendant of another text object
	bool isDescendantOf(NTTextGroup* obj);
};

#endif //NTTEXTOBJECT_H