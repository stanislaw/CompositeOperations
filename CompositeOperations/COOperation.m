#import "COOperation.h"
#import "COOperation_Private.h"

#import "COQueues.h"

@implementation COOperation

- (id)init {
    if (self = [super init]) {
        self.numberOfRuns = 0;

        [self initPropertiesForRun];
    }

    return self;
}

- (void)initPropertiesForRun {
    self.state = COOperationReadyState;
}

- (void)dealloc {
    _operation = nil;
}

#pragma mark
#pragma mark Properties

- (BOOL)isConcurrent {
    return YES;
}

- (void)setState:(COOperationState)state {
    @synchronized(self) {
        NSString *oldStateKey = COKeyPathFromOperationState(self.state);
        NSString *newStateKey = COKeyPathFromOperationState(state);

        [self willChangeValueForKey:newStateKey];
        [self willChangeValueForKey:oldStateKey];
        _state = state;
        [self didChangeValueForKey:oldStateKey];
        [self didChangeValueForKey:newStateKey];
    }
}

- (BOOL)isReady {
    return self.state == COOperationReadyState && super.isReady;
}

- (BOOL)isExecuting {
    return self.state == COOperationExecutingState;
}

- (BOOL)isFinished {
    return self.state == COOperationFinishedState;
}

#pragma mark
#pragma mark Main / Start / Run / Finish / Cancel

- (void)main {
    if (self.operation) self.operation(self);
}

- (void)start {
    if (self.isReady) {
        self.numberOfRuns++;

        self.state = COOperationExecutingState;

        if (self.isCancelled || self.contextOperation.isCancelled) {
            [self finish];
        } else {
            [self main];
        }
    }
}

- (void)run:(COOperationBlock)operationBlock {
    self.operation = operationBlock;

    CORunOperation(self);
}

- (void)runInQueue:(dispatch_queue_t)queue operation:(COOperationBlock)operationBlock {
#if !OS_OBJECT_USE_OBJC
    dispatch_retain(queue);
#endif

    COOperationBlock operationBlockInQueue = ^(COOperation *op) {
        dispatch_async(queue, ^{
            if (op.isExecuting == YES) {
                operationBlock(op);
            }
        });
    };

    self.operation = operationBlockInQueue;

#if !OS_OBJECT_USE_OBJC
    COOperation *weakSelf = self;
    self.completionBlock = ^{
        __strong COOperation *strongSelf = weakSelf;

        if (strongSelf.isFinished || strongSelf.isCancelled) {
            dispatch_release(queue);

            strongSelf.completionBlock = nil;
        }
    };
#endif
    
    [self start];
}

- (void)run:(COOperationBlock)operationBlock completionHandler:(COCompletionBlock)completionHandler cancellationHandler:(COCancellationBlockForOperation)cancellationHandler {
    self.operation = operationBlock;

    __weak COOperation *weakSelf = self;
    self.completionBlock = ^{
        __strong COOperation *strongSelf = weakSelf;

        if (strongSelf.isFinished) {
            if (completionHandler) completionHandler();

            strongSelf.completionBlock = nil;
        } else if (cancellationHandler) {
            cancellationHandler();
            strongSelf.completionBlock = nil;
        }
    };
    
    CORunOperation(self);
}

- (void)finish {
    if (self.isCancelled == NO) {
        self.state = COOperationFinishedState;
    }
}

- (BOOL)isCancelled {
    return self.state == COOperationCancelledState;
}

- (void)cancel {
    @synchronized(self) {
        if (self.isFinished == NO && self.isCancelled == NO && self.isSuspended == NO) {
            self.state = COOperationCancelledState;

            if (self.contextOperation == nil && self.completionBlock) self.completionBlock();
        }
    }
}

#pragma mark
#pragma mark reRun / awake

- (void)reRun {
    [self initPropertiesForRun];

    [self start];
}

- (void)awake {
    [self reRun];
}

#pragma mark
#pragma mark Suspend / Resume

- (BOOL)isSuspended {
    return self.state == COOperationSuspendedState;
}

- (void)suspend {
    if (self.isFinished == NO && self.isCancelled == NO && self.isSuspended == NO) {
        self.state = COOperationSuspendedState;
    }
}

- (void)resume {
    if (self.isSuspended == NO || self.isFinished || self.isCancelled) return;

    // -resume reruns operation if it has no context. Context does a rerun otherwise
    if (self.numberOfRuns > 0 && self.contextOperation == nil) {
        [self reRun];
    } else {
        self.state = COOperationReadyState;
    }
}

#pragma mark
#pragma mark Resolution

- (void)resolveWithResolver:(id <COOperationResolver>)operationResolver {
    [operationResolver resolveOperation:self];
}

- (void)resolveWithResolver:(id <COOperationResolver>)operationResolver usingResolutionStrategy:(id)resolutionStrategy fallbackHandler:(COCompletionBlock)fallbackHandler {
    [operationResolver resolveOperation:self usingResolutionStrategy:resolutionStrategy fallbackHandler:fallbackHandler];
}

#pragma mark
#pragma mark NSObject

- (NSString *)description {
    NSString *description = [NSString stringWithFormat:@"%@ (state = %@, numberOfRuns = %u)", super.description, COKeyPathFromOperationState(self.state), (unsigned)self.numberOfRuns];

    return description;
}

- (NSString *)debugDescription {
    return self.description;
}

@end
