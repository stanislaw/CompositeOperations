// CompositeOperations
//
// CompositeOperations/COOperation.h
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import <Foundation/Foundation.h>
#import "COTypedefs.h"

@interface COOperation : NSOperation

@property (copy) COOperationBlock operationBlock;

@property (strong) id operationQueue;

@property (readonly) BOOL isReady;
@property (readonly) BOOL isExecuting;
@property (readonly) BOOL isFinished;

- (void)run:(COOperationBlock)operationBlock;
- (void)runInQueue:(dispatch_queue_t)queue operation:(COOperationBlock)operationBlock;
- (void)run:(COOperationBlock)operationBlock completionHandler:(COOperationCompletionBlock)completionHandler cancellationHandler:(COOperationCancellationBlock)cancellationHandler;

- (void)start;

- (void)cancel;
- (void)cancelWithError:(NSError *)error;

- (void)finish;
- (void)finishWithResult:(id)result;

// Resolution
- (void)resolveWithOperation:(COOperation *)operation;

@property (copy) NSString *name;

@end
