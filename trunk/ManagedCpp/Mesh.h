/*
 *  Mesh.h
 *  OpenGLEditor
 *
 *  Created by Filip Kunc on 10/23/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#pragma once

#include <windows.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <vector>
#include "../PureCpp/MathCore/MathDeclaration.h"
#include "../PureCpp/Enums.h"
#include "../PureCpp/MeshHelpers.h"
using namespace std;

using namespace System;
using namespace System::Drawing;
using namespace System::Diagnostics;

namespace ManagedCpp
{
	public ref class Mesh
	{
	private:
		vector<Vector3D> *vertices;
		vector<Triangle> *triangles;
		vector<Edge> *edges;
		vector<CocoaBool> *selected;
		vector<CocoaBool> *markedVertices;
		Color color;
		enum MeshSelectionMode selectionMode;
	public:
		Mesh();
		~Mesh();

		property MeshSelectionMode SelectionMode { MeshSelectionMode get(); void set(MeshSelectionMode value); }
		property uint Count { uint get(); }
		property uint VertexCount { uint get(); }
		property uint TriangleCount { uint get(); }
		property uint EdgeCount { uint get(); }
		
		Vector3D GetVertex(uint index);
		Triangle GetTriangle(uint index);
		Edge GetEdge(uint index);
		CocoaBool IsVertexUsed(uint index);
		CocoaBool IsVertexMarked(uint index);
		void SetVertexMarked(CocoaBool isMarked, uint index);
		void SetEdgeMarked(CocoaBool isMarked, uint index);
		void SetTriangleMarked(CocoaBool isMarked, uint index);
		void AddVertex(Vector3D vertex);
		void AddTriangle(Triangle triangle);
		void AddTriangle(uint index1, uint index2, uint index3);
		void AddQuad(uint index1, uint index2, uint index3, uint index4);
		void AddEdge(uint index1, uint index2);
		void RemoveVertex(uint index);
		void RemoveTriangle(uint index);
		void RemoveEdge(uint index);
		void DrawFast();
		void DrawFill(Vector3D scale);
		void DrawWire(Vector3D scale, CocoaBool isSelected);
		void Draw(Vector3D scale, CocoaBool isSelected);
		void Draw(uint index, CocoaBool forSelection, ViewMode mode);
		void MakeCube();
		void MakeCylinder(uint steps);
		void MakeSphere(uint steps);
		void MakeEdges();
		void MakeMarkedVertices();
		void RemoveNonUsedVertices();
		void RemoveDegeneratedTriangles();
		void RemoveSelectedVertices();
		void FastMergeVertex(uint firstIndex, uint secondIndex);
		void FastMergeSelectedVertices();
		void MergeSelectedVertices();
		void Transform(Matrix4x4 matrix);
		void Merge(Mesh ^mesh);
		void GetTriangleVertices(Vector3D *triangleVertices, Triangle triangle);
		void SplitTriangle(uint index);
		void SplitEdge(uint index);
		void SplitSelectedEdges();
		void SplitSelectedTriangles();
		void TurnEdge(uint index);
		void TurnSelectedEdges();
		void MergeVertexPairs();
		void MergeSelected();
		void SplitSelected();
		void FlipSelectedTriangles();
		void FlipAllTriangles();
		void FlipTriangle(uint index);
		void DidSelect();
		void GetSelectionCenter(Vector3D *center, Quaternion *rotation, Vector3D *scale);
		void MoveSelected(Vector3D offset);
		void RotateSelected(Quaternion offset);
		void ScaleSelected(Vector3D offset);
		CocoaBool IsSelected(uint index);
		void SetSelected(CocoaBool isSelected, uint index);
		void CloneSelected();
		void RemoveSelected();
	};
}