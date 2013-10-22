// CompositeOperations
//
// CompositeOperations/COCascadeOperation.h
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import <Foundation/Foundation.h>

#import "COTypedefs.h"

#import "COCompositeOperation.h"
#import "COTransactionalOperation.h"

#import "COOperationQueue.h"

@class COCascadeOperation;

@interface COCascadeOperation : COAbstractCompositeOperation

@property (copy) COCascadeOperationBlock operation;

// Public API: Cascade operation
- (void)run:(COCascadeOperationBlock)operationBlock __attribute__((unavailable("must run cascade operation with 'run:completionHandler:cancellationHandler:' instead.")));
- (void)runInQueue:(dispatch_queue_t)queue operation:(COOperationBlock)operationBlock __attribute__((unavailable("must run cascade operation with 'run:completionHandler:cancellationHandler:' instead.")));

- (void)run:(COCascadeOperationBlock)operationBlock completionHandler:(COCompletionBlock)completionHandler cancellationHandler:(COCancellationBlockForCascadeOperation)cancellationHandler;

@end

