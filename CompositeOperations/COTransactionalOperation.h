// CompositeOperations
//
// CompositeOperations/COTransactionalOperation.h
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import <Foundation/Foundation.h>

#import "COTypedefs.h"

#import "COCompositeOperation.h"

#import "COCascadeOperation.h"

@class COTransactionalOperation;
@class COOperation;

@interface COTransactionalOperation : COAbstractCompositeOperation

@property (copy) COTransactionalOperationBlock operation;

// Public API: Transactional operation
- (void)run:(COTransactionalOperationBlock)operationBlock __attribute__((unavailable("must run transactional operation with 'run:completionHandler:cancellationHandler:' instead.")));
- (void)runInQueue:(dispatch_queue_t)queue operation:(COOperationBlock)operationBlock __attribute__((unavailable("must run transactional operation with 'run:completionHandler:cancellationHandler:' instead.")));

- (void)run:(COTransactionalOperationBlock)operationBlock completionHandler:(COCompletionBlock)completionHandler cancellationHandler:(COCancellationBlockForTransactionalOperation)cancellationHandler;

@end



