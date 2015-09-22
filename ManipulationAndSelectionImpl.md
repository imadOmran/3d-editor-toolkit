# Manipulation and Selection implementation #

Manipulators are able to define translation, rotation and scale of Item objects. Manipulators are made of ManipulatorWidget objects which represents each selectable part of manipulator, like arrows, circles, planes, etc.
Each ManipulatorWidget defines its Axis, Axis can be X, Y, Z or Center. Center is used only in scaling.
Manipulator object takes care only of collection of widgets and their drawing. Manipulator doesn't care about mouse dragging and retrieving 3d translation, rotation, scale. This code is written in OpenGLSceneView. Retrieving 3d position in space is done via gluUnproject. First step is to draw some large plane, and then unproject 2d mouse position from that plane. Second step is deciding what manipulator is active and which widget is selected. If is selected for example, arrow widget, then we need to take care only of one component (X, Y, Z) of retrieved position.

```
- (Vector3D)positionFromAxis:(Axis)axis point:(NSPoint)point
{
    const float size = 4000.0f;
    DrawPlane(camera->GetAxisX(), camera->GetAxisY(), size);
  
    Vector3D position = [self positionInSpaceByPoint:point];
    Vector3D result = [manipulated selectionCenter];
    result[axis] = position[axis];
    return result;
}  
```

This code is from OpenGLSceneView.mm, for Windows developers is used this code:

```
Vector3D OpenGLSceneView::GetPositionOnAxis(Axis axis, PointF point)
{
    const float size = 4000.0f;
    DrawPlane(camera->GetAxisX(), camera->GetAxisY(), size);

    Vector3D position = this->GetPositionInSpace(point);
    Vector3D result = manipulated->SelectionCenter;
    result[axis] = position[axis];
    return result;
}
```

Manipulator also implements OpenGLSelecting protocol (interface), which is needed for OpenGLSceneView to know what is selectable.

```
@protocol OpenGLSelecting

- (uint)selectableCount;
- (void)drawForSelectionAtIndex:(uint)index;
- (void)selectObjectAtIndex:(uint)index withMode:(enum OpenGLSelectionMode)selectionMode;

@optional
- (void)willSelect;
- (void)didSelect;

@end
```

This protocol is very benevolent, so I use many completely different implementations, most straightforward is ItemCollection and Manipulator. But there is also relatively easy implementation for STL `vector<something>` collections like in Mesh. I use this also for selection of vertices, triangles, edges, items, arrows of manipulator, everything.

Implementation of selection is also in OpenGLSceneView, it is done via ancient `glRenderMode(GL_SELECT);` which is very slow on modern GPUs. But it was very easy to implement. OpenGLSelecting protocol is very simple so different implementations on OpenGL or DirectX should be easy to achieve.

# Selection is not enough for manipulation #
So selection of custom objects is done, how about manipulating some collection of items? This is not as easy as implementing OpenGLSelecting protocol. Current protocols and implementation suits more my needs for modeling editor than really customizable framework, but some work is done to simplify whole process.
Manipulation handling is also done in OpenGLSceneView. OpenGLSceneView presumes that you need two objects, displayed and manipulated. Both needs to implement OpenGLManipulating protocol.

```
@protocol OpenGLManipulating <OpenGLSelecting>

@property (readwrite, assign) enum ManipulatorType currentManipulator;
@property (readwrite, assign) Vector3D selectionCenter;
@property (readwrite, assign) Quaternion selectionRotation;
@property (readwrite, assign) Vector3D selectionScale;
@property (readwrite, assign) float selectionX, selectionY, selectionZ;
@property (readonly) uint selectedCount;

- (void)moveSelectedByOffset:(Vector3D)offset;
- (void)rotateSelectedByOffset:(Quaternion)offset;
- (void)scaleSelectedByOffset:(Vector3D)offset;
- (void)updateSelection;
- (void)drawWithMode:(enum ViewMode)mode;
- (void)changeSelection:(BOOL)isSelected;
- (void)invertSelection;
- (void)cloneSelected;
- (void)removeSelected;

@end
```

There is two problems for reusable 3d editor toolkit. First there is no way to force OpenGLSceneView to display something as non-manipulatable objects, and don't implement moveSelectedByOffset, etc. Second thing is that this protocol is pretty big and tedious to implement.
To simplify things a bit I created helper class which implements most of this protocol and provides you two options how to implement the rest.
This class is called OpenGLManipulatingController and can help you with implementation of drawing, selection, key-value-observing, etc.
So basically you always need to implement this protocol:

```
@protocol OpenGLManipulatingModel

- (uint)count;
- (BOOL)isSelectedAtIndex:(uint)index;
- (void)setSelected:(BOOL)selected atIndex:(uint)index;
- (void)drawAtIndex:(uint)index forSelection:(BOOL)forSelection withMode:(enum ViewMode)mode;
- (void)cloneSelected;
- (void)removeSelected;

@optional

- (void)willSelect;
- (void)didSelect;

@end
```

When you look closer, you find that there is also cloneSelected and removeSelected, which doesn't directly falls under manipulation. You can implement them as empty methods. If it is implemented correctly then Cmd+C and Delete works as expected.
Next you need to decide if your class is more

Mesh-like

```
@protocol OpenGLManipulatingModelMesh <OpenGLManipulatingModel>

- (void)getSelectionCenter:(Vector3D *)center 
                  rotation:(Quaternion *)rotation
                     scale:(Vector3D *)scale;

- (void)moveSelectedByOffset:(Vector3D)offset;
- (void)rotateSelectedByOffset:(Quaternion)offset;
- (void)scaleSelectedByOffset:(Vector3D)offset;

@end
```

or Item-like.

```
@protocol OpenGLManipulatingModelItem <OpenGLManipulatingModel>

- (Vector3D)positionAtIndex:(uint)index;
- (Quaternion)rotationAtIndex:(uint)index;
- (Vector3D)scaleAtIndex:(uint)index;
- (void)setPosition:(Vector3D)position atIndex:(uint)index;
- (void)setRotation:(Quaternion)rotation atIndex:(uint)index;
- (void)setScale:(Vector3D)scale atIndex:(uint)index;
- (void)moveByOffset:(Vector3D)offset atIndex:(uint)index;
- (void)rotateByOffset:(Quaternion)offset atIndex:(uint)index;
- (void)scaleByOffset:(Vector3D)offset atIndex:(uint)index;

@end
```

Mesh-like protocol is better when you have collection of interconnected objects, for example triangles and edges in Mesh is very hard to implement as `positionAtIndex:` and `setPosition:atIndex:`.
Item-like protocol is better for simple objects with separated position, rotation and scale. Another advantage for Item-like protocol is that OpenGLManipulatingController automatically computes for you selection center, rotation and scale.