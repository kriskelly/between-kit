//
//  I3GestureCoordinatorTests.m
//  BetweenKit
//
//  Created by Stephen Fortune on 14/09/2014.
//  Copyright (c) 2014 stephen fortune. All rights reserved.
//

#import <BetweenKit/I3GestureCoordinator.h>
#import <BetweenKit/I3DragArena.h>


SpecBegin(I3GestureCoordinator)

    __block NSMutableOrderedSet *collections;
    __block id dragArena;
    __block id superview;
    __block id panGestureRecognizer;


    beforeEach(^{
    
        dragArena = OCMClassMock([I3DragArena class]);
        superview = OCMClassMock([UIView class]);
        panGestureRecognizer = OCMPartialMock([[UIPanGestureRecognizer alloc] init]);
        collections = [[NSMutableOrderedSet alloc] init];
        
        OCMStub([dragArena superview]).andReturn(superview);
        OCMStub([dragArena collections]).andReturn(collections);
        
    });

    afterEach(^{
        
        dragArena = nil;
        superview = nil;
        panGestureRecognizer = nil;
        collections = nil;
    
    });


    describe(@"inject, setup and tear down dependencies", ^{
        
        
        it(@"should inject dependencies", ^{
        
            I3GestureCoordinator *coordinator = [[I3GestureCoordinator alloc] initWithDragArena:dragArena withGestureRecognizer:panGestureRecognizer];
            
            expect(coordinator.gestureRecognizer).to.equal(panGestureRecognizer);
            expect(coordinator.arena).to.equal(dragArena);
        
        });
    
        it(@"should create a UIPanGestureRecognizer by default", ^{
        
            I3GestureCoordinator *coordinator = [[I3GestureCoordinator alloc] initWithDragArena:dragArena withGestureRecognizer:nil];
            expect(coordinator.gestureRecognizer).to.beInstanceOf([UIPanGestureRecognizer class]);
            
        });
        
        it(@"should setup the gesture recognizer's target and superview correctly", ^{
        
            I3GestureCoordinator *coordinator = [[I3GestureCoordinator alloc] initWithDragArena:dragArena withGestureRecognizer:panGestureRecognizer];
            OCMVerify([panGestureRecognizer addTarget:coordinator action:[OCMArg anySelector]]);
            OCMVerify([superview addGestureRecognizer:panGestureRecognizer]);
            
        });
        
        it(@"should not attach the gesture recognizer to the superview if its already attached", ^{

            [[superview reject] addGestureRecognizer:[OCMArg any]];
            OCMStub([superview gestureRecognizers]).andReturn(@[panGestureRecognizer]);
            I3GestureCoordinator *coordinator __unused = [[I3GestureCoordinator alloc] initWithDragArena:dragArena withGestureRecognizer:panGestureRecognizer];
            OCMVerifyAll(superview);

        });

        
        /** @note Here we use pragma to ignore warnings about weak variables being assigned and
         then released immediately after as this is exactly what we are trying to achieve. In
         order for 'dealloc' to be triggered under ARC we must invoke the ctor by creating a
         weak reference that will unasigned immediately. */
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-unsafe-retained-assign"
        
        
        it(@"should unbind gesture recognizer from coordinator and superview", ^{
            
            OCMStub([superview gestureRecognizers]).andReturn(@[panGestureRecognizer]);
            
            __weak I3GestureCoordinator *coordinator __unused = [[I3GestureCoordinator alloc] initWithDragArena:dragArena withGestureRecognizer:panGestureRecognizer];
            
            OCMVerify([panGestureRecognizer removeTarget:[OCMArg any] action:NULL]);
            OCMVerify([superview removeGestureRecognizer:panGestureRecognizer]);
            
        });
        
        it(@"should not attempt to remove gesture recognizer from superview if it is no longer present", ^{
            
            [[superview reject] removeGestureRecognizer:panGestureRecognizer];
            OCMStub([superview gestureRecognizers]).andReturn(@[]);
            
            __weak I3GestureCoordinator *coordinator __unused = [[I3GestureCoordinator alloc] initWithDragArena:dragArena withGestureRecognizer:panGestureRecognizer];
            
            OCMVerifyAll(superview);
            
        });
        
#pragma clang diagnostic pop
        
    });


    describe(@"starting a drag", ^{

        
        __block I3GestureCoordinator *coordinator;
        __block id collectionView;
        __block id draggingDataSource = OCMProtocolMock(@protocol(I3DragDataSource));

        CGPoint touchPoint = CGPointMake(10, 10);

        
        beforeEach(^{
            
            coordinator = [[I3GestureCoordinator alloc] initWithDragArena:dragArena withGestureRecognizer:panGestureRecognizer];
            collectionView = OCMClassMock([UIView class]);
            draggingDataSource = OCMProtocolMock(@protocol(I3DragDataSource));
            
            OCMStub([panGestureRecognizer locationInView:collectionView]).andReturn(touchPoint);
            OCMStub([panGestureRecognizer state]).andReturn(UIGestureRecognizerStateBegan);

        });
        
        afterEach(^{
            
            coordinator = nil;
            collectionView = nil;
            draggingDataSource = nil;
            
            OCMVerifyAll(draggingDataSource);
            OCMVerifyAll(collectionView);
            OCMVerifyAll(dragArena);
            OCMVerifyAll(panGestureRecognizer);
            
        });
        
        
        it(@"should start drag on a collection in the arena if the point is inside its bounds and the item is draggable", ^{
            
            id draggingCollection = OCMProtocolMock(@protocol(I3Collection));
            
            OCMStub([draggingDataSource canItemBeDraggedAtPoint:touchPoint inCollection:draggingCollection]).andReturn(YES);
            OCMStub([draggingCollection dragDataSource]).andReturn(draggingDataSource);
            OCMStub([draggingCollection collectionView]).andReturn(collectionView);
            OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(YES);
            
            [[dragArena collections] addObject:draggingCollection];
            [coordinator handlePan:coordinator.gestureRecognizer];
            
            expect(coordinator.currentDraggingCollection).to.equal(draggingCollection);
            expect(coordinator.currentDragOrigin).to.equal(touchPoint);
            
            OCMVerifyAll(draggingCollection);
            
        });

        it(@"should assume that a collection is completely un-draggable if there is no data source", ^{

            id undraggableCollection = OCMProtocolMock(@protocol(I3Collection));
            
            OCMStub([undraggableCollection collectionView]).andReturn(collectionView);
            OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(YES);
            
            [[dragArena collections] addObject:undraggableCollection];
            [coordinator handlePan:coordinator.gestureRecognizer];
            
            expect(coordinator.currentDraggingCollection).to.beNil();
            expect(coordinator.currentDragOrigin).to.equal(CGPointZero);
            
            OCMVerifyAll(undraggableCollection);

        });
        
        it(@"should not start dragging on a collection on an item that is not draggable", ^{

            id draggingCollection = OCMProtocolMock(@protocol(I3Collection));

            OCMStub([draggingDataSource canItemBeDraggedAtPoint:touchPoint inCollection:draggingCollection]).andReturn(NO);
            OCMStub([draggingCollection dragDataSource]).andReturn(draggingDataSource);
            OCMStub([draggingCollection collectionView]).andReturn(collectionView);
            OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(YES);
            
            [[dragArena collections] addObject:draggingCollection];
            [coordinator handlePan:coordinator.gestureRecognizer];
            
            expect(coordinator.currentDraggingCollection).to.beNil();
            expect(coordinator.currentDragOrigin).to.equal(CGPointZero);
            
            OCMVerifyAll(draggingCollection);

        });

        it(@"should start dragging on the top-most intersecting collection in the ordered set", ^{
            
            id topDraggingCollection = OCMProtocolMock(@protocol(I3Collection));
            id bottomDraggingCollection = OCMProtocolMock(@protocol(I3Collection));

            OCMStub([draggingDataSource canItemBeDraggedAtPoint:touchPoint inCollection:topDraggingCollection]).andReturn(YES);
            OCMStub([topDraggingCollection dragDataSource]).andReturn(draggingDataSource);
            OCMStub([topDraggingCollection collectionView]).andReturn(collectionView);
            
            [[draggingDataSource reject] canItemBeDraggedAtPoint:touchPoint inCollection:bottomDraggingCollection];
            [[bottomDraggingCollection reject] dragDataSource];
            [[bottomDraggingCollection reject] collectionView];
            
            OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(YES);
            
            [[dragArena collections] addObjectsFromArray:@[topDraggingCollection, bottomDraggingCollection]];
            [coordinator handlePan:coordinator.gestureRecognizer];
            
            expect(coordinator.currentDraggingCollection).to.equal(topDraggingCollection);
            
            OCMVerifyAll(topDraggingCollection);
            OCMVerifyAll(bottomDraggingCollection);

        });
        
        it(@"should not start dragging if the point is outside of the collection view", ^{
            
            id collection = OCMProtocolMock(@protocol(I3Collection));
            
            [[draggingDataSource reject] canItemBeDraggedAtPoint:touchPoint inCollection:collection];
            [[collection reject] dragDataSource];
            
            OCMStub([collection collectionView]).andReturn(collectionView);
            OCMStub([collectionView pointInside:touchPoint withEvent:nil]).andReturn(NO);
            
            [[dragArena collections] addObject:collection];
            [coordinator handlePan:coordinator.gestureRecognizer];
            
            expect(coordinator.currentDraggingCollection).to.beNil();
            expect(coordinator.currentDragOrigin).to.equal(CGPointZero);
            
            OCMVerifyAll(collection);
            
        });

    });


SpecEnd