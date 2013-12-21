// CompositeOperations
//
// CompositeOperations/COOperation.h
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import <Foundation/Foundation.h>
#import "COTypedefs.h"

@interface COOperation : NSOperation

@property (copy, nonatomic) COOperationBlock operationBlock;

@property (copy, nonatomic) COOperationCompletionBlock completionHandler;
@property (copy, nonatomic) COOperationCancellationBlock cancellationHandler;

@property (strong, nonatomic) id operationQueue;

@property (readonly) BOOL isReady;
@property (readonly) BOOL isExecuting;
@property (readonly) BOOL isFinished;

- (void)run:(COOperationBlock)operationBlock;
- (void)runInQueue:(dispatch_queue_t)queue operation:(COOperationBlock)operationBlock;
- (void)run:(COOperationBlock)operationBlock completionHandler:(COOperationCompletionBlock)completionHandler cancellationHandler:(COOperationCancellationBlock)cancellationHandler;

- (void)start;

- (void)finish;
- (void)finishWithResult:(id)result;

- (void)reject;
- (void)rejectWithError:(NSError *)error;

// Resolution
- (void)resolveWithOperation:(COOperation *)operation;

@property (copy, nonatomic) NSString *name;

- (instancetype)lazyCopy;

@end
