/*
 *  Item.h
 *  OpenGLEditor
 *
 *  Created by Filip Kunc on 10/23/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#pragma once

#include "../PureCpp/MathCore/MathDeclaration.h"
#include "../PureCpp/Enums.h"
#include "../PureCpp/MeshHelpers.h"
#include "Mesh.h"

namespace ManagedCpp 
{
	public ref class Item
	{
	private:
		Vector3D *position;
		Quaternion *rotation;
		Vector3D *scale;
		Mesh ^mesh;
		CocoaBool selected;
	public:
		Item();
		Item(Vector3D aPosition, Quaternion aRotation, Vector3D aScale);
		~Item();

		property Vector3D Position { Vector3D get(); void set(Vector3D value); }
		property Quaternion Rotation { Quaternion get(); void set(Quaternion value); }
		property Vector3D Scale { Vector3D get(); void set(Vector3D value); }
		
		void Draw(ViewMode mode);
		void MoveBy(Vector3D offset);
		void RotateBy(Quaternion offset);
		void ScaleBy(Vector3D offset);
		
		Item ^ Clone();
	};
}