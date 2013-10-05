#import <Foundation/Foundation.h>
#import "SATypedefs.h"
#import "SAOperationResolver.h"

typedef enum {
    SAOperationCancelledState   = -2,
    SAOperationSuspendedState   = -1,
    SAOperationReadyState       = 0,
    SAOperationExecutingState   = 1,
    SAOperationFinishedState    = 2,
} _SAOperationState;

@interface SAOperation : NSOperation

// Core
@property (copy) SAOperationBlock operation;

@property (strong) id operationQueue;

@property (readonly) BOOL isReady;
@property (readonly) BOOL isExecuting;
@property (readonly) BOOL isFinished;
@property (readonly) BOOL isCancelled;
@property (readonly) BOOL isSuspended;

@property NSUInteger numberOfRuns;

- (void)main;

- (void)run:(SAOperationBlock)operationBlock;
- (void)runInQueue:(dispatch_queue_t)queue operation:(SAOperationBlock)operationBlock;
- (void)run:(SAOperationBlock)operationBlock completionHandler:(SACompletionBlock)completionHandler cancellationHandler:(SACancellationBlockForOperation)cancellationHandler;

- (void)start;
- (void)finish;
- (void)cancel;

// Context operation
@property (strong) SAOperation *contextOperation;

// Rerunning
- (void)reRun;
- (void)awake;

// Suspending
- (void)suspend;
- (void)resume;

// Resolution
- (void)resolveWithResolver:(id <SAOperationResolver>)operationResolver;
- (void)resolveWithResolver:(id <SAOperationResolver>)operationResolver usingResolutionStrategy:(id)resolutionStrategy fallbackHandler:(SACompletionBlock)fallbackHandler;

// NSObject
- (NSString *)description;
- (NSString *)debugDescription;

@end


@interface SAOperation ()

@property (nonatomic) _SAOperationState state;
@property (nonatomic, readonly) NSString *stateKey;

- (void)initPropertiesForRun;

@end
