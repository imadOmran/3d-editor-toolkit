//
//  MyDocument.h
//  OpenGLEditor
//
//  Created by Filip Kunc on 6/29/09.
//  For license see LICENSE.TXT
//


#import <Cocoa/Cocoa.h>
#import "ItemCollection.h"
#import "OpenGLSceneView.h"
#import "AddItemWithStepsSheetController.h"

@interface MyDocument : NSDocument <AddItemWithStepsProtocol, OpenGLSceneViewDelegate>
{
@public // public for unit tests
	BOOL manipulationFinished;
	ItemCollection *items;
	OpenGLManipulatingController *itemsController;
	OpenGLManipulatingController *meshController;
	id<OpenGLManipulating> manipulated;
	IBOutlet OpenGLSceneView *view;
	IBOutlet NSPopUpButton *editModePopUp;
	IBOutlet NSPopUpButton *cameraModePopUp;
	IBOutlet NSPopUpButton *viewModePopUp;
	IBOutlet AddItemWithStepsSheetController *addItemWithStepsSheetController;
	enum ItemWithSteps itemWithSteps;
	
	NSMutableArray *startedManipulations;
}

@property (readwrite, assign) id<OpenGLManipulating> manipulated;
@property (readwrite, assign) float selectionX, selectionY, selectionZ;

- (void)addItem:(Item *)item withName:(NSString *)name;
- (void)removeItem:(Item *)item withName:(NSString *)name;
- (IBAction)addCube:(id)sender;
- (IBAction)addCylinder:(id)sender;
- (IBAction)addSphere:(id)sender;
- (void)editMeshWithMode:(enum MeshSelectionMode)mode;
- (void)editItems;
- (IBAction)changeEditMode:(id)sender;
- (IBAction)changeCameraMode:(id)sender;
- (IBAction)changeManipulator:(id)sender;
- (IBAction)changeViewMode:(id)sender;
- (IBAction)mergeSelected:(id)sender;
- (IBAction)splitSelected:(id)sender;
- (IBAction)mergeVertexPairs:(id)sender;
- (IBAction)cloneSelected:(id)sender;
- (void)undoCloneSelected:(NSMutableArray *)selection;
- (IBAction)flipSelected:(id)sender;
- (IBAction)deleteSelected:(id)sender;
- (void)undoDeleteSelected:(NSMutableArray *)selectedItems;
- (IBAction)selectAll:(id)sender;
- (IBAction)invertSelection:(id)sender;
- (void)readFromTmd:(NSString *)fileName;
- (MyDocument *)prepareUndoWithName:(NSString *)actionName;

@end
