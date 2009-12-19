//
//  OpenGLManipulatingController.mm
//  OpenGLEditor
//
//  Created by Filip Kunc on 8/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "OpenGLManipulatingController.h"


@implementation OpenGLManipulatingController

@synthesize currentManipulator, selectedCount, model, lastSelectedIndex;

- (id)init
{
	self = [super init];
	if (self)
	{
		selectionCenter = new Vector3D();
		selectionRotation = new Quaternion();
		selectionEuler = new Vector3D();
		selectionScale = new Vector3D(1, 1, 1);
		toggleWhenSelecting = NO;
		selectedCount = 0;
		lastSelectedIndex = -1;
		currentManipulator = ManipulatorTypeDefault;
		modelTransform = new Matrix4x4();
		modelPosition = new Vector3D();
		modelRotation = new Quaternion();
		modelScale = new Vector3D(1, 1, 1);
	}
	return self;
}

- (void)dealloc
{
	delete selectionCenter;
	delete selectionRotation;
	delete selectionEuler;
	delete selectionScale;
	delete modelTransform;
	delete modelPosition;
	delete modelRotation;
	delete modelScale;
	[super dealloc];
}

- (void)setPosition:(Vector3D)aPosition rotation:(Quaternion)aRotation scale:(Vector3D)aScale
{
	*modelPosition = aPosition;
	*modelRotation = aRotation;
	*modelScale = aScale;
	modelTransform->TranslateRotateScale(aPosition, aRotation, aScale);
}

- (float)selectionX
{
	return [self selectionValueAtIndex:0];
}

- (float)selectionY
{
	return [self selectionValueAtIndex:1];
}

- (float)selectionZ
{
	return [self selectionValueAtIndex:2];
}

- (void)setSelectionX:(float)value
{
	[self setSelectionValue:value atIndex:0];
}

- (void)setSelectionY:(float)value
{
	[self setSelectionValue:value atIndex:1];
}

- (void)setSelectionZ:(float)value
{
	[self setSelectionValue:value atIndex:2];
}

- (float)selectionValueAtIndex:(NSUInteger)index
{
	switch (currentManipulator)
	{
		case ManipulatorTypeTranslation:
			return (*selectionCenter)[index];
		case ManipulatorTypeRotation:
			return (*selectionEuler)[index] * RAD_TO_DEG;
		case ManipulatorTypeScale:
			return (*selectionScale)[index];
		case ManipulatorTypeDefault:
		default:
			return 0.0f;
	}
}

- (void)setSelectionValue:(float)value atIndex:(NSUInteger)index
{
	switch (currentManipulator)
	{
		case ManipulatorTypeTranslation:
		{
			Vector3D offset = Vector3D();
			offset[index] = value - (*selectionCenter)[index];
			[self moveSelectedByOffset:offset];
		}break;
		case ManipulatorTypeRotation:
		{
			(*selectionEuler)[index] = value * DEG_TO_RAD;
			if (selectedCount == 1)
			{
				selectionRotation->FromEulerAngles(*selectionEuler);
				if (lastSelectedIndex > -1)
					[model setRotation:*selectionRotation atIndex:lastSelectedIndex];
			}
			else
			{
				Quaternion offset = Quaternion();
				offset.FromEulerAngles(*selectionEuler);
				offset = offset * selectionRotation->Conjugate();
				[self rotateSelectedByOffset:offset];
			}
		}break;
		case ManipulatorTypeScale:
		{
			if (selectedCount == 1)
			{
				(*selectionScale)[index] = value;
				if (lastSelectedIndex > -1)
					[model setScale:*selectionScale atIndex:lastSelectedIndex];
			}
			else
			{
				Vector3D offset = Vector3D();
				offset[index] = value - (*selectionScale)[index];
				[self scaleSelectedByOffset:offset];
			}
		}break;
		default:
			break;
	}
}

- (void)setCurrentManipulator:(enum ManipulatorType)value
{
	[self willChangeSelection];
	currentManipulator = value;
	[self didChangeSelection];
}

- (void)updateSelection
{
	[self willChangeSelection];
	selectedCount = 0;
	*selectionCenter = Vector3D();
	lastSelectedIndex = -1;
	for (int i = 0; i < [model count]; i++)
	{
		if ([model isSelectedAtIndex:i])
		{
			selectedCount++;
			*selectionCenter += [model positionAtIndex:i];
			lastSelectedIndex = i;
		}
	}
	*selectionRotation = Quaternion();
	*selectionScale = Vector3D(1, 1, 1);
	if (selectedCount > 0)
	{
		*selectionCenter /= (float)selectedCount;
		if (selectedCount == 1 && lastSelectedIndex > -1)
		{
			*selectionRotation = [model rotationAtIndex:lastSelectedIndex];
			*selectionScale = [model scaleAtIndex:lastSelectedIndex];
		}
	}
	else
	{
		*selectionCenter = Vector3D();
	}
	selectionRotation->ToEulerAngles(*selectionEuler);
	selectionCenter->Transform(*modelTransform);
	[self didChangeSelection];
}

- (void)willChangeSelection
{
	[self willChangeValueForKey:@"selectionX"];
	[self willChangeValueForKey:@"selectionY"];
	[self willChangeValueForKey:@"selectionZ"];	
}

- (void)didChangeSelection
{
	[self didChangeValueForKey:@"selectionX"];
	[self didChangeValueForKey:@"selectionY"];
	[self didChangeValueForKey:@"selectionZ"];	
}

- (Vector3D)selectionCenter
{
	return *selectionCenter;
}

- (void)setSelectionCenter:(Vector3D)value
{
	[self willChangeSelection];
	*selectionCenter = value;
	[self didChangeSelection];
}

- (Quaternion)selectionRotation
{
	return *selectionRotation;
}

- (void)setSelectionRotation:(Quaternion)value
{
	[self willChangeSelection];
	*selectionRotation = value;
	selectionRotation->ToEulerAngles(*selectionEuler);
	[self didChangeSelection];
}

- (Vector3D)selectionScale
{
	return *selectionScale;
}

- (void)setSelectionScale:(Vector3D)value
{
	[self willChangeSelection];
	*selectionScale = value;
	[self didChangeSelection];
}

- (void)moveSelectedByOffset:(Vector3D)offset
{
	Vector3D transformedOffset = offset;
	Matrix4x4 m, r, s;
	Quaternion inverseRotation = modelRotation->Conjugate();
	
	Vector3D inverseScale = *modelScale;
	for (int i = 0; i < 3; i++)
		inverseScale[i] = 1.0f / inverseScale[i];
	
	inverseRotation.ToMatrix(r);
	s.Scale(inverseScale);
	m = s * r;
	transformedOffset.Transform(m);
	
	for (int i = 0; i < [model count]; i++)
	{
		if ([model isSelectedAtIndex:i])
			[model moveByOffset:transformedOffset atIndex:i];
	}
	
	[self setSelectionCenter:*selectionCenter + offset];
}

- (void)rotateSelectedByOffset:(Quaternion)offset
{
	if ([self selectedCount] > 1)
	{
		Vector3D rotationCenter = *selectionCenter;
		rotationCenter.Transform(modelTransform->Inverse());
		for (int i = 0; i < [model count]; i++)
		{
			if ([model isSelectedAtIndex:i])
			{
				Vector3D itemPosition = [model positionAtIndex:i];
				itemPosition -= rotationCenter;
				itemPosition.Transform(offset);
				itemPosition += rotationCenter;
				[model setPosition:itemPosition atIndex:i];
				[model rotateByOffset:offset atIndex:i];
			}
		}
		[self setSelectionRotation:offset * (*selectionRotation)];
	}
	else if (lastSelectedIndex > -1)
	{
		[model rotateByOffset:offset atIndex:lastSelectedIndex];
		[self setSelectionRotation:[model rotationAtIndex:lastSelectedIndex]];
	}	
}

- (void)scaleSelectedByOffset:(Vector3D)offset
{
	if ([self selectedCount] > 1)
	{
		Vector3D rotationCenter = *selectionCenter;
		rotationCenter.Transform(modelTransform->Inverse());
		for (int i = 0; i < [model count]; i++)
		{
			if ([model isSelectedAtIndex:i])
			{
				Vector3D itemPosition = [model positionAtIndex:i];
				itemPosition -= rotationCenter;
				itemPosition.x *= 1.0f + offset.x;
				itemPosition.y *= 1.0f + offset.y;
				itemPosition.z *= 1.0f + offset.z;
				itemPosition += rotationCenter;
				[model setPosition:itemPosition atIndex:i];
				[model scaleByOffset:offset atIndex:i];
			}
		}
	}
	else if (lastSelectedIndex > -1)
	{
		[model scaleByOffset:offset atIndex:lastSelectedIndex];
	}
	[self setSelectionScale:*selectionScale + offset];
}

- (void)draw
{
	glPushMatrix();
	glMultMatrixf(modelTransform->m);
	for (int i = 0; i < [model count]; i++)
	{
		[model drawAtIndex:i];
	}
	glPopMatrix();
}

- (NSUInteger)selectableCount
{
	return [model count];
}

- (void)drawForSelectionAtIndex:(NSUInteger)index
{
	glPushMatrix();
	glMultMatrixf(modelTransform->m);
	[model drawAtIndex:index];
	glPopMatrix();
}

- (void)selectObjectAtIndex:(NSUInteger)index
{
	if (toggleWhenSelecting)
		[model setSelected:![model isSelectedAtIndex:index] atIndex:index];
	else
		[model setSelected:YES atIndex:index];
	[self updateSelection];
}

- (void)changeSelection:(BOOL)isSelected
{
	for (int i = 0; i < [model count]; i++)
		[model setSelected:isSelected atIndex:i];
	[self updateSelection];
}

- (void)invertSelection
{
	for (int i = 0; i < [model count]; i++)
		[model setSelected:![model isSelectedAtIndex:i] atIndex:i];
	[self updateSelection];
}

@end
