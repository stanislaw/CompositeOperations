//
//  SACompositeOperation.h
//  SACompositeOperationsApp
//
//  Created by Stanislaw Pankevich on 5/14/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SAOperation.h"

@protocol SACompositeOperation <NSObject> 
- (void)enqueueSuboperation:(SAOperation *)subOperation;

- (void)performCheckpointRoutine;
- (void)performAwakeRoutine;
- (void)performResumeRoutine;

- (void)subOperationWasFinished:(SAOperation *)subOperation;
- (void)subOperationWasCancelled:(SAOperation *)subOperation;
@end

@interface SAAbstractCompositeOperation : SAOperation

// Public API: Inner operations
- (void)operation:(SAOperationBlock)operationBlock;
- (void)operationInQueue:(dispatch_queue_t)queue operation:(SAOperationBlock)operationBlock;

// Public API: Inner composite operations
- (void)transactionalOperation:(SATransactionalOperationBlock)operationBlock;
- (void)cascadeOperation:(SACascadeOperationBlock)operationBlock;

// Shared data
@property (strong) id sharedData;
- (void)modifySharedData:(SAModificationBlock)modificationBlock;

@end

@interface SAAbstractCompositeOperation () <SACompositeOperation>

@property (strong) NSMutableArray *operations;
@property BOOL allSuboperationsRegistered;

- (void)_teardown;

- (void)_registerSuboperation:(SAOperation *)subOperation;
- (void)_runSuboperation:(SAOperation *)subOperation;
- (void)_runSuboperationAtIndex:(NSUInteger)indexOfSuboperationToRun;

- (void)_cancelSuboperations:(BOOL)runCompletionBlocks;

@end
