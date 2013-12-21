// CompositeOperations
//
// CompositeOperations/COCompositeOperation.h
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import <Foundation/Foundation.h>

#import "COOperation.h"
#import "COTypedefs.h"

@interface COCompositeOperation : COOperation

- (id)initWithConcurrencyType:(COCompositeOperationConcurrencyType)concurrencyType;

@property (copy, nonatomic) COCompositeOperationBlock operationBlock;

@property (copy, nonatomic) COCompositeOperationCompletionBlock completionHandler;
@property (copy, nonatomic) COCompositeOperationCancellationBlock cancellationHandler;

@property (nonatomic, getter = isLazyCopy) BOOL lazyCopy;

- (void)run:(COCompositeOperationBlock)operationBlock __attribute__((unavailable("must run composite operation with 'run:completionHandler:cancellationHandler:' instead.")));
- (void)runInQueue:(dispatch_queue_t)queue operation:(COCompositeOperationBlock)operationBlock __attribute__((unavailable("must run composite operation with 'run:completionHandler:cancellationHandler:' instead.")));

// Public API: main runner
- (void)run:(COCompositeOperationBlock)operationBlock completionHandler:(COCompositeOperationCompletionBlock)completionHandler cancellationHandler:(COCompositeOperationCancellationBlock)cancellationHandler;

// Public API: Inner operations
- (void)operation:(COOperation *)operation;
- (void)operationWithBlock:(COOperationBlock)operationBlock;
- (void)operationInQueue:(dispatch_queue_t)queue withBlock:(COOperationBlock)operationBlock;

// Public API: Inner composite operations
- (void)compositeOperation:(COCompositeOperation *)compositeOperation;
- (void)compositeOperation:(COCompositeOperationConcurrencyType)concurrencyType withBlock: (COCompositeOperationBlock)operationBlock;

// Shared data
@property (strong, nonatomic) id data;
- (void)safelyAccessData:(COModificationBlock)modificationBlock;

@end
