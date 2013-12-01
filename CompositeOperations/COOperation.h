// CompositeOperations
//
// CompositeOperations/COOperation.h
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import <Foundation/Foundation.h>
#import "COTypedefs.h"

@interface COOperation : NSOperation

@property (copy) COOperationBlock operation;
@property (strong) id operationQueue;

@property (readonly) BOOL isReady;
@property (readonly) BOOL isExecuting;
@property (readonly) BOOL isFinished;
@property (readonly) BOOL isCancelled;
@property (readonly) BOOL isSuspended;

- (void)run:(COOperationBlock)operationBlock;
- (void)runInQueue:(dispatch_queue_t)queue operation:(COOperationBlock)operationBlock;
- (void)run:(COOperationBlock)operationBlock completionHandler:(COCompletionBlock)completionHandler cancellationHandler:(COCancellationBlockForOperation)cancellationHandler;

- (void)start;
- (void)finish;
- (void)cancel;

// Rerunning
- (void)reRun;
- (void)awake;

// Suspending
- (void)suspend;
- (void)resume;

// Resolution
- (void)resolveWithOperation:(COOperation *)operation;

@end
