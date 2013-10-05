//
//  SACompositeOperation.h
//  SACompositeOperationsApp
//
//  Created by Stanislaw Pankevich on 5/14/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "COOperation.h"

@protocol COCompositeOperation <NSObject>
- (void)enqueueSuboperation:(COOperation *)subOperation;

- (void)performCheckpointRoutine;
- (void)performAwakeRoutine;
- (void)performResumeRoutine;

- (void)subOperationWasFinished:(COOperation *)subOperation;
- (void)subOperationWasCancelled:(COOperation *)subOperation;
@end

@interface COAbstractCompositeOperation : COOperation

// Public API: Inner operations
- (void)operation:(COOperationBlock)operationBlock;
- (void)operationInQueue:(dispatch_queue_t)queue operation:(COOperationBlock)operationBlock;

// Public API: Inner composite operations
- (void)transactionalOperation:(COTransactionalOperationBlock)operationBlock;
- (void)cascadeOperation:(COCascadeOperationBlock)operationBlock;

// Shared data
@property (strong) id sharedData;
- (void)modifySharedData:(COModificationBlock)modificationBlock;

@end

@interface COAbstractCompositeOperation () <COCompositeOperation>

@property (strong) NSMutableArray *operations;
@property BOOL allSuboperationsRegistered;

- (void)_teardown;

- (void)_registerSuboperation:(COOperation *)subOperation;
- (void)_runSuboperation:(COOperation *)subOperation;
- (void)_runSuboperationAtIndex:(NSUInteger)indexOfSuboperationToRun;

- (void)_cancelSuboperations:(BOOL)runCompletionBlocks;

@end
