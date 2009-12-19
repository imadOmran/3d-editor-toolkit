//
//  MyDocument.m
//  OpenGLEditor
//
//  Created by Filip Kunc on 6/29/09.
//  Copyright __MyCompanyName__ 2009 . All rights reserved.
//

#import "MyDocument.h"
#import "ItemManipulationState.h"

@implementation MyDocument

- (id)init
{
    self = [super init];
    if (self) 
	{
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
		items = [[ItemCollection alloc] init];
		itemsController = [[OpenGLManipulatingController alloc] init];
		meshController = [[OpenGLManipulatingController alloc] init];
		
		[itemsController setModel:items];
		manipulated = itemsController;
    }
    return self;
}

- (void)dealloc
{
	[meshController release];
	[itemsController release];
	[items release];
	[super dealloc];
}

- (void)awakeFromNib
{
	[editModePopUp selectItemWithTag:0];
	[view setManipulated:manipulated];
	[view setDisplayed:itemsController];
	[view setDelegate:self];
}

- (id<OpenGLManipulating>)manipulated
{
	return manipulated;
}

- (void)setManipulated:(id<OpenGLManipulating>)value
{
	manipulated = value;
	[manipulated setCurrentManipulator:[view currentManipulator]];
	[view setManipulated:value];
	[view setNeedsDisplay:YES];
}

- (void)addItem:(Item *)item withName:(NSString *)name
{
	NSLog(@"item vertexCount = %i", [[item mesh] vertexCount]);
	NSLog(@"item triangleCount = %i", [[item mesh] triangleCount]);
	NSLog(@"adding %@", name);
	
	NSUndoManager *undo = [self undoManager];
	MyDocument *doc = [undo prepareWithInvocationTarget:self];
	[doc removeItem:item withName:name];
	if (![undo isUndoing])
		[undo setActionName:[NSString stringWithFormat:@"Add %@", name]];
	
	[items addItem:item];
	[itemsController changeSelection:NO];
	[items setSelected:YES atIndex:[items count] - 1];
	[itemsController updateSelection];
	[view setNeedsDisplay:YES];
}

- (void)removeItem:(Item *)item withName:(NSString *)name
{
	NSLog(@"removing %@", name);
	
	NSUndoManager *undo = [self undoManager];
	MyDocument *doc = [undo prepareWithInvocationTarget:self];
	[doc addItem:item withName:name];
	if (![undo isUndoing])
		[undo setActionName:[NSString stringWithFormat:@"Remove %@", name]];
	
	[items removeItem:item];
	[itemsController changeSelection:NO];
	[itemsController updateSelection];
	[view setNeedsDisplay:YES];
}

- (void)applyWithCurrentManipulations:(NSMutableArray *)currentManipulations 
					 oldManipulations:(NSMutableArray *)oldManipulations
{
	NSLog(@"applyManipulations:");
	
	for (ItemManipulationState *currentState in currentManipulations)
	{
		Item *item = [items itemAtIndex:[currentState itemIndex]];
		[currentState applyManipulationToItem:item];
	}
	
	NSUndoManager *undo = [self undoManager];
	MyDocument *doc = (MyDocument *)[undo prepareWithInvocationTarget:self];
	[doc applyWithCurrentManipulations:oldManipulations
					  oldManipulations:currentManipulations];
	if (![undo isUndoing])
		[undo setActionName:@"Manipulations"];
	[itemsController updateSelection];
	[view setNeedsDisplay:YES];
}

- (void)revertManipulations:(NSMutableArray *)oldManipulations
{
	NSLog(@"revertManipulations:");
	
	NSMutableArray *currentManipulations = [[NSMutableArray alloc] init];
	
	for (ItemManipulationState *oldState in oldManipulations)
	{
		Item *item = [items itemAtIndex:[oldState itemIndex]];
		ItemManipulationState *currentState = [[ItemManipulationState alloc] initWithItem:item 
																					index:[oldState itemIndex]];
		[oldState applyManipulationToItem:item];
		[currentManipulations addObject:currentState];
	}
	
	NSUndoManager *undo = [self undoManager];
	MyDocument *doc = (MyDocument *)[undo prepareWithInvocationTarget:self];
	[doc applyWithCurrentManipulations:currentManipulations
					  oldManipulations:oldManipulations];
	if (![undo isUndoing])
		[undo setActionName:@"Manipulations"];	
	[itemsController updateSelection];
	[view setNeedsDisplay:YES];
}

- (void)manipulationStarted
{
	NSLog(@"manipulationStarted");
	
	NSMutableArray *itemManipulations = [[NSMutableArray alloc] init];
	
	for (uint i = 0; i < [items count]; i++)
	{
		Item *item = [items itemAtIndex:i];
		ItemManipulationState *itemState = [[ItemManipulationState alloc] initWithItem:item index:i];
		[itemManipulations addObject:itemState];
	}
	
	NSUndoManager *undo = [self undoManager];
	MyDocument *doc = [undo prepareWithInvocationTarget:self];
	[doc revertManipulations:itemManipulations];
	if (![undo isUndoing])
		[undo setActionName:@"Manipulations"];
}

- (void)manipulationEnded
{
	NSLog(@"manipulationEnded");
}

- (IBAction)addCube:(id)sender
{
	Item *cube = [[Item alloc] init];
	[[cube mesh] makeCube];
	[self addItem:cube withName:@"Cube"];
}

- (IBAction)addCylinder:(id)sender
{
	itemWithSteps = ItemWithStepsCylinder;
	[addItemWithStepsSheetController beginSheetWithProtocol:self];
}

- (IBAction)addSphere:(id)sender
{
	itemWithSteps = ItemWithStepsSphere;
	[addItemWithStepsSheetController beginSheetWithProtocol:self];
}

- (void)addItemWithSteps:(uint)steps
{
	Item *item = [[Item alloc] init];
	switch (itemWithSteps)
	{
		case ItemWithStepsCylinder:
			[[item mesh] makeCylinderWithSteps:steps];
			[self addItem:item withName:@"Cylinder"];
			break;
		case ItemWithStepsSphere:
			[[item mesh] makeSphereWithSteps:steps];
			[self addItem:item withName:@"Sphere"];
			break;
		default:
			break;
	}
}

- (void)editMeshWithMode:(enum MeshSelectionMode)mode
{
	NSInteger index = [itemsController lastSelectedIndex];
	if (index > -1)
	{
		Item *item = [items itemAtIndex:index];
		[[item mesh] setSelectionMode:mode];
		[meshController setModel:[item mesh]];
		[meshController setPosition:[item position] 
						   rotation:[item rotation] 
							  scale:[item scale]];
		[self setManipulated:meshController];
	}
}

- (void)editItems
{
	Mesh *mesh = (Mesh *)[meshController model];
	[mesh setSelectionMode:MeshSelectionModeVertices];
	[itemsController setModel:items];
	[itemsController setPosition:Vector3D()
						rotation:Quaternion()
						   scale:Vector3D(1, 1, 1)];
	[self setManipulated:itemsController];
}

- (IBAction)changeEditMode:(id)sender
{
	EditMode mode = (EditMode)[[editModePopUp selectedItem] tag];
	switch (mode)
	{
		case EditModeItems:
			[self editItems];
			break;
		case EditModeVertices:
			[self editMeshWithMode:MeshSelectionModeVertices];
			break;
		case EditModeTriangles:
			[self editMeshWithMode:MeshSelectionModeTriangles];
			break;
		case EditModeEdges:
			[self editMeshWithMode:MeshSelectionModeEdges];
			break;
		default:
			break;
	}
}

- (IBAction)changeCameraMode:(id)sender
{
	CameraMode mode = (CameraMode)[[cameraModePopUp selectedItem] tag];
	[view setCameraMode:mode];
}

- (IBAction)mergeSelected:(id)sender
{
	if (manipulated == itemsController)
	{
		[items mergeSelectedItems];
		[itemsController updateSelection];
	}
	else
	{
		Mesh *mesh = (Mesh *)[meshController model];
		[mesh mergeSelected];
	}
	[view setNeedsDisplay:YES];
}

- (IBAction)splitSelected:(id)sender
{
	if (manipulated == meshController)
	{
		Mesh *mesh = (Mesh *)[meshController model];
		[mesh splitSelected];
	}
	[view setNeedsDisplay:YES];
}

- (IBAction)cloneSelected:(id)sender
{
	[manipulated cloneSelected];
	[view setNeedsDisplay:YES];
}

- (IBAction)deleteSelected:(id)sender
{
	[manipulated removeSelected];
	[view setNeedsDisplay:YES];
}

- (IBAction)turnSelectedEdges:(id)sender
{
	if (manipulated == meshController)
	{
		Mesh *mesh = (Mesh *)[meshController model];
		if ([mesh selectionMode] == MeshSelectionModeEdges)
			[mesh turnSelectedEdges];
	}
	[view setNeedsDisplay:YES];
}

- (IBAction)mergeVertexPairs:(id)sender
{
	if (manipulated == meshController)
	{
		Mesh *mesh = (Mesh *)[meshController model];
		if ([mesh selectionMode] == MeshSelectionModeVertices)
			[mesh mergeVertexPairs];
	}
	[view setNeedsDisplay:YES];
}

- (IBAction)changeManipulator:(id)sender
{
	ManipulatorType newManipulator = (ManipulatorType)[sender tag];
	[[self manipulated] setCurrentManipulator:newManipulator];
	[view setCurrentManipulator:newManipulator];
}

- (IBAction)selectAll:(id)sender
{
	[[self manipulated] changeSelection:YES];
	[view setNeedsDisplay:YES];
}

- (IBAction)invertSelection:(id)sender
{
	[[self manipulated] invertSelection];
	[view setNeedsDisplay:YES];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	return [NSKeyedArchiver archivedDataWithRootObject:items];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	ItemCollection *newItems = nil;
	@try
	{
		newItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	}
	@catch (NSException *e)
	{
		if (outError)
		{
			NSDictionary *d = 
			[NSDictionary dictionaryWithObject:@"The data is corrupted."
										forKey:NSLocalizedFailureReasonErrorKey];
			
			*outError = [NSError errorWithDomain:NSOSStatusErrorDomain 
											code:unimpErr
										userInfo:d];
		}
		return NO;
	}
	[newItems retain];
	[items release];
	items = newItems;
	[itemsController setModel:items];
	[itemsController updateSelection];
	[self setManipulated:itemsController];
	return YES;
}

@end