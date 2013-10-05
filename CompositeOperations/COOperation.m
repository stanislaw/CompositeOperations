#import "SAOperation.h"
#import "SAQueues.h"

static inline NSString * SAKeyPathFromOperationState(_SAOperationState state) {
    switch (state) {
        case SAOperationCancelledState:
            return @"isCancelled";
        case SAOperationSuspendedState:
            return @"isSuspended";
        case SAOperationReadyState:
            return @"isReady";
        case SAOperationExecutingState:
            return @"isExecuting";
        case SAOperationFinishedState:
            return @"isFinished";
        default:
            return @"state";
    }
}

@implementation SAOperation

- (id)init {
    if (self = [super init]) {
        self.numberOfRuns = 0;

        [self initPropertiesForRun];
    }

    return self;
}

- (void)initPropertiesForRun {
    self.state = SAOperationReadyState;
}

- (void)dealloc {
    _operation = nil;
}

#pragma mark
#pragma mark Properties

- (NSString *)stateKey {
    return SAKeyPathFromOperationState(self.state);
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)setState:(_SAOperationState)state {
    @synchronized(self) {
        NSString *oldStateKey = self.stateKey;
        NSString *newStateKey = SAKeyPathFromOperationState(state);

        [self willChangeValueForKey:newStateKey];
        [self willChangeValueForKey:oldStateKey];
        _state = state;
        [self didChangeValueForKey:oldStateKey];
        [self didChangeValueForKey:newStateKey];
    }
}

- (BOOL)isReady {
    return self.state == SAOperationReadyState && super.isReady;
}

- (BOOL)isExecuting {
    return self.state == SAOperationExecutingState;
}

- (BOOL)isFinished {
    return self.state == SAOperationFinishedState;
}

#pragma mark
#pragma mark Main / Start / Run / Finish / Cancel

- (void)main {
    if (self.operation) self.operation(self);
}

- (void)start {
    if (self.isReady) {
        self.numberOfRuns++;

        self.state = SAOperationExecutingState;

        if (self.isCancelled || self.contextOperation.isCancelled) {
            [self finish];
        } else {
            [self main];
        }
    }
}

- (void)run:(SAOperationBlock)operationBlock {
    self.operation = operationBlock;

    SARunOperation(self);
}

- (void)runInQueue:(dispatch_queue_t)queue operation:(SAOperationBlock)operationBlock {
#if !OS_OBJECT_USE_OBJC
    dispatch_retain(queue);
#endif

    SAOperationBlock operationBlockInQueue = ^(SAOperation *op) {
        dispatch_async(queue, ^{
            if (op.isExecuting == YES) {
                operationBlock(op);
            }
        });
    };

    self.operation = operationBlockInQueue;

#if !OS_OBJECT_USE_OBJC
    SAOperation *weakSelf = self;
    self.completionBlock = ^{
        __strong SAOperation *strongSelf = weakSelf;

        if (strongSelf.isFinished || strongSelf.isCancelled) {
            dispatch_release(queue);

            strongSelf.completionBlock = nil;
        }
    };
#endif
    
    [self start];
}

- (void)run:(SAOperationBlock)operationBlock completionHandler:(SACompletionBlock)completionHandler cancellationHandler:(SACancellationBlockForOperation)cancellationHandler {
    self.operation = operationBlock;

    __weak SAOperation *weakSelf = self;
    self.completionBlock = ^{
        __strong SAOperation *strongSelf = weakSelf;

        if (strongSelf.isFinished) {
            if (completionHandler) completionHandler();

            strongSelf.completionBlock = nil;
        } else if (cancellationHandler) {
            cancellationHandler();
            strongSelf.completionBlock = nil;
        }
    };
    
    SARunOperation(self);
}

- (void)finish {
    if (self.isCancelled == NO) {
        self.state = SAOperationFinishedState;
    }
}

- (BOOL)isCancelled {
    return self.state == SAOperationCancelledState;
}

- (void)cancel {
    @synchronized(self) {
        if (self.isFinished == NO && self.isCancelled == NO && self.isSuspended == NO) {
            self.state = SAOperationCancelledState;

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
    return self.state == SAOperationSuspendedState;
}

- (void)suspend {
    if (self.isFinished == NO && self.isCancelled == NO && self.isSuspended == NO) {
        self.state = SAOperationSuspendedState;
    }
}

- (void)resume {
    if (self.isSuspended == NO || self.isFinished || self.isCancelled) return;

    // -resume reruns operation if it has no context. Context does a rerun otherwise
    if (self.numberOfRuns > 0 && self.contextOperation == nil) {
        [self reRun];
    } else {
        self.state = SAOperationReadyState;
    }
}

#pragma mark
#pragma mark Resolution

- (void)resolveWithResolver:(id <SAOperationResolver>)operationResolver {
    [operationResolver resolveOperation:self];
}

- (void)resolveWithResolver:(id <SAOperationResolver>)operationResolver usingResolutionStrategy:(id)resolutionStrategy fallbackHandler:(SACompletionBlock)fallbackHandler {
    [operationResolver resolveOperation:self usingResolutionStrategy:resolutionStrategy fallbackHandler:fallbackHandler];
}

#pragma mark
#pragma mark NSObject

- (NSString *)description {
    NSString *description = [NSString stringWithFormat:@"%@ (state = %@, numberOfRuns = %u)", super.description, self.stateKey, (unsigned)self.numberOfRuns];

    return description;
}

- (NSString *)debugDescription {
    return self.description;
}

@end
