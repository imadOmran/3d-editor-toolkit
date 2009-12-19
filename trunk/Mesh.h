//
//  Mesh.h
//  OpenGLEditor
//
//  Created by Filip Kunc on 7/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MathDeclaration.h"
#import "OpenGLManipulatingController.h"
#import <vector>
using namespace std;

typedef struct {
	NSUInteger vertexIndices[3];
} Triangle;

Triangle MakeTriangle(NSUInteger index1, NSUInteger index2, NSUInteger index3);

@interface Mesh : NSObject <OpenGLManipulatingModel>
{
	vector<Vector3D> *vertices;
	vector<Triangle> *triangles;
	vector<BOOL> *selectedIndices;
}

- (Vector3D)vertexAtIndex:(NSUInteger)anIndex;
- (Triangle)triangleAtIndex:(NSUInteger)anIndex;
- (void)addVertex:(Vector3D)aVertex;
- (void)addTriangle:(Triangle)aTriangle;
- (void)draw;
- (void)makeCube;

@end
