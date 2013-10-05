#import <Foundation/Foundation.h>
#import "COTypedefs.h"
#import "COOperationResolver.h"

typedef enum {
    COOperationCancelledState   = -2,
    COOperationSuspendedState   = -1,
    COOperationReadyState       = 0,
    COOperationExecutingState   = 1,
    COOperationFinishedState    = 2,
} _COOperationState;

@interface COOperation : NSOperation

// Core
@property (copy) COOperationBlock operation;

@property (strong) id operationQueue;

@property (readonly) BOOL isReady;
@property (readonly) BOOL isExecuting;
@property (readonly) BOOL isFinished;
@property (readonly) BOOL isCancelled;
@property (readonly) BOOL isSuspended;

@property NSUInteger numberOfRuns;

- (void)main;

- (void)run:(COOperationBlock)operationBlock;
- (void)runInQueue:(dispatch_queue_t)queue operation:(COOperationBlock)operationBlock;
- (void)run:(COOperationBlock)operationBlock completionHandler:(COCompletionBlock)completionHandler cancellationHandler:(COCancellationBlockForOperation)cancellationHandler;

- (void)start;
- (void)finish;
- (void)cancel;

// Context operation
@property (strong) COOperation *contextOperation;

// Rerunning
- (void)reRun;
- (void)awake;

// Suspending
- (void)suspend;
- (void)resume;

// Resolution
- (void)resolveWithResolver:(id <COOperationResolver>)operationResolver;
- (void)resolveWithResolver:(id <COOperationResolver>)operationResolver usingResolutionStrategy:(id)resolutionStrategy fallbackHandler:(COCompletionBlock)fallbackHandler;

// NSObject
- (NSString *)description;
- (NSString *)debugDescription;

@end


@interface COOperation ()

@property (nonatomic) _COOperationState state;
@property (nonatomic, readonly) NSString *stateKey;

- (void)initPropertiesForRun;

@end
