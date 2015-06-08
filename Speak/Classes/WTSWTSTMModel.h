/*
 *  WTSWTSTMModel.h
 *  WTSWTSTM
 *
 *  Created by Bruno Nadeau on 10-09-16.
 *  Copyright 2010 Obx Labs. All rights reserved.
 */

#ifndef WTSWTSTMMODEL_H
#define WTSWTSTMMODEL_H

#import "cocos2d.h"

#include "NTTextGroup.h"
#include "NTGlyph.h"
#include <string>
#include <list>

//
// WTSWTSTM Model.
// This is the main model that handles the text for the application.
//
class WTSWTSTMModel {

private:
	NTTextGroup* m_pRoot;				//root of the text
	NTGlyph* m_pLeader;					//the selected leader (if any)
	NTTextGroup* m_pLeaderLine;			//the line group of the leader (if any)
	list<CGPoint> m_pPath;				//the path
	unsigned int m_maxPathLength;       //max number of points in the path
    
	int m_iPathOffset;					//number of path points to skip before the text (space for the finger)
	float m_fSwimVelocity;				//velocity of the swim behavior
	float m_fSwimCloudSize;				//size of the swim clouds
	float m_fFollowVelocity;			//velocity of the follow behavior
	float m_fRotationToVelocity;		//angular velocity to rotate to the path slope
	float m_fRotationBackVelocity;		//angular velocity to rotate back to rest state 
	int m_iPathSpacing;					//spacing between path points
	int m_iWordSpacing;					//spacing between words
	ccColor4B m_TextColorBg;			//color of text in the background
	ccColor4B m_TextColorBgHighlight;	//color of highlighted text in the background (first letter)
	ccColor4B m_TextColorFg;			//color of text in the foreground
    
    //for reading guide
    ccColor4B m_TextColorNextLine;		//color of the first letter of the next line
    int nextLine;                       //index of the next line
	
private:
	//init the model with a text string, a bitmap font atlas, and size of environment
	void init(const char* text, const CCLabelBMFont* atlas, int iWidth, int iHeight);
	
	//init the text hierarchy
	void initHierarchy(const char* pText, const CCLabelBMFont* pAtlas);
	
	//init the graphical properties of the text
	void initGraphics(unsigned int width, unsigned int height);
	
	//util function to tokenize a string
	void tokenize(const string& str,
				  vector<string>& tokens,
				  const string& delimiters = " ");
	
	//sets the led property for the children glyphs of a line
	void setLedGlyphs(NTTextGroup* pLineGroup, bool led);
	
public:
	//default constructor
	WTSWTSTMModel();
	
	//constructor
	WTSWTSTMModel(const char* text, const CCLabelBMFont* atlas, int iWidth, int iHeight);
	
	//destructor
	virtual ~WTSWTSTMModel();
	
	//get reference to path
	list<CGPoint>& path() { return m_pPath; }
    
    //get the max path length
    unsigned int maxPathLength() { return m_maxPathLength; }
    
    //clear the path
    void clearPath();
	
	//get a pointer to the text root
	NTTextGroup* root() { return m_pRoot; }
	
	//set the leader glyph
	NTGlyph* setLeaderAt(float x, float y);
    
	//set the leader glyph
	NTGlyph* setLeader(NTGlyph* pGlyph);

    //set the next leader glyph for guide
	NTGlyph* setNextLeader();
	
	//update the model for an elapsed time (in seconds)
	void update(float dt);
	
	//find the closest glyph to a point
	NTGlyph* closestGlyphTo(float x, float y);
};

#endif //WTSWTSTMMODEL_H