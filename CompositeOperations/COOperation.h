#import <Foundation/Foundation.h>
#import "COTypedefs.h"
#import "COOperationResolver.h"

@interface COOperation : NSOperation

@property (copy) COOperationBlock operation;
@property (strong) id operationQueue;

@property (readonly) BOOL isReady;
@property (readonly) BOOL isExecuting;
@property (readonly) BOOL isFinished;
@property (readonly) BOOL isCancelled;
@property (readonly) BOOL isSuspended;

@property NSUInteger numberOfRuns;

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
- (void)resolveWithResolver:(id <COOperationResolver>)operationResolver;
- (void)resolveWithResolver:(id <COOperationResolver>)operationResolver usingResolutionStrategy:(id)resolutionStrategy fallbackHandler:(COCompletionBlock)fallbackHandler;

@end
