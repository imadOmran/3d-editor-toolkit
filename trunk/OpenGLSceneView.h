//
//  OpenGLSceneView.h
//  OpenGLEditor
//
//  Created by Filip Kunc on 6/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MathDeclaration.h"
#import "Camera.h"
#import "OpenGLSelecting.h"
#import "Manipulator.h"
#import "OpenGLManipulating.h"

@interface OpenGLSceneView : NSOpenGLView 
{
	id<OpenGLManipulating> displayed;
	id<OpenGLManipulating> manipulated;
	
	Vector3D *selectionOffset;
	Camera *camera;
	NSPoint lastPoint;
	NSPoint currentPoint;
	BOOL isManipulating;
	BOOL isSelecting;
	Manipulator *defaultManipulator;
	Manipulator *translationManipulator;
	Manipulator *rotationManipulator;
	Manipulator *scaleManipulator;
	Manipulator *currentManipulator;
}

@property (readwrite, assign) id<OpenGLManipulating> displayed;
@property (readwrite, assign) id<OpenGLManipulating> manipulated;
@property (readwrite, assign) enum ManipulatorType currentManipulator;

- (void)drawGridWithSize:(int)size step:(int)step;
- (NSRect)currentRect;
- (void)beginOrtho;
- (void)endOrtho;

- (void)selectWithX:(double)x 
				  y:(double)y
			  width:(double)width 
			 height:(double)height
		  selecting:(id<OpenGLSelecting>)selecting 
		nearestOnly:(BOOL)nearestOnly
		selectionMode:(enum OpenGLSelectionMode)selectionMode;

- (void)selectWithPoint:(NSPoint)point 
			  selecting:(id<OpenGLSelecting>)selecting
		  selectionMode:(enum OpenGLSelectionMode)selectionMode;

- (void)selectWithRect:(NSRect)rect 
			 selecting:(id<OpenGLSelecting>)selecting
		 selectionMode:(enum OpenGLSelectionMode)selectionMode;

- (Vector3D)positionInSpaceByPoint:(NSPoint)point;
- (void)drawSelectionPlaneWithIndex:(int)index;
- (Vector3D)positionFromAxis:(Axis)axis point:(NSPoint)point;
- (Vector3D)positionFromRotatedAxis:(Axis)axis point:(NSPoint)point rotation:(Quaternion)rotation;
- (Vector3D)positionFromPlaneAxis:(PlaneAxis)plane point:(NSPoint)point;
- (Vector3D)translationFromPoint:(NSPoint)point;
- (Vector3D)scaleFromPoint:(NSPoint)point lastPosition:(Vector3D *)lastPosition;
- (Quaternion)rotationFromPoint:(NSPoint)point lastPosition:(Vector3D *)lastPosition;

- (IBAction)redraw:(id)sender;

@end