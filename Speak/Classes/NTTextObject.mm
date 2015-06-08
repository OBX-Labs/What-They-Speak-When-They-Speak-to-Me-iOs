/*
 *  NTTextObject.mm
 *  WTSWTSTM
 *
 *  Created by Bruno Nadeau on 10-09-15.
 *  Copyright 2010 Obx Labs. All rights reserved.
 *
 */

#include "NTTextObject.h"
#include "NTTextGroup.h"

NTTextObject::NTTextObject() {
	m_pParent = NULL;
}

NTTextObject::~NTTextObject() {
}

bool NTTextObject::isDescendantOf(NTTextGroup* obj)
{
	if (obj == NULL) return false;
	
	//move up the hierarchy to see if we find the passed object
	NTTextGroup* pParent = parent();
	while(pParent != NULL) {
		if (pParent == obj) return true;
		pParent = pParent->parent();
	}
	return false;
}