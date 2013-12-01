// CompositeOperations
//
// CompositeOperations/COOperation.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "COOperation.h"
#import "COOperation_Private.h"

#import "COQueues.h"

static inline int COStateTransitionIsValid(COOperationState fromState, COOperationState toState, BOOL inContext) {
    switch (fromState) {
        case COOperationStateReady:
            return YES;
        case COOperationStateExecuting:
            switch (toState) {
                case COOperationStateReady:
                    return YES;
                case COOperationStateCancelled:
                    return YES;
                case COOperationStateFinished:
                    return YES;
                case COOperationStateSuspended:
                    return YES;
                case COOperationStateExecuting:
                    return YES;
                default:
                    return -1;
            }

        case COOperationStateSuspended:
            switch (toState) {
                case COOperationStateReady:
                    return YES;
                case COOperationStateExecuting:
                    return YES;
                case COOperationStateFinished:
                    return YES;
                case COOperationStateCancelled:
                    return NO;
                default:
                    return -1;
            }

        case COOperationStateCancelled:
            switch (toState) {
                case COOperationStateReady:
                    return inContext;
                case COOperationStateExecuting:
                    return -1;
                case COOperationStateFinished:
                    return YES;
                default:
                    return -1;
            }

        case COOperationStateFinished:
            return -1;
        default:
            return -1;
    }
}

@implementation COOperation

- (id)init {
    if (self = [super init]) {
        self.numberOfRuns = 0;

        [self initPropertiesForRun];
    }

    return self;
}

- (void)initPropertiesForRun {
    self.state = COOperationStateReady;
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
    if (COStateTransitionIsValid(self.state, state, !!self.contextOperation) == NO) {
        return;
    }
    
    @synchronized(self) {
        if (COStateTransitionIsValid(self.state, state, !!self.contextOperation) == NO) {
            return;
        }

        if (COStateTransitionIsValid(self.state, state, !!self.contextOperation) == -1) {
            NSString *errMessage = [NSString stringWithFormat:@"%@: transition from %@ to %@ is invalid", self, COKeyPathFromOperationState(self.state), COKeyPathFromOperationState(state)];

            @throw [NSException exceptionWithName:NSGenericException reason:errMessage userInfo:nil];
        };

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
    return self.state == COOperationStateReady && super.isReady;
}

- (BOOL)isExecuting {
    return self.state == COOperationStateExecuting;
}

- (BOOL)isCancelled {
    return self.state == COOperationStateCancelled;
}

- (BOOL)isFinished {
    return self.state == COOperationStateFinished;
}

#pragma mark
#pragma mark Main / Start / Run / Finish / Cancel

- (void)main {
    if (self.operation) self.operation(self);
}

- (void)start {
    if (self.isReady) {
        self.numberOfRuns++;

        self.state = COOperationStateExecuting;

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
    void (^originalCompletionBlock)(void) = self.completionBlock;

    COOperation *weakSelf = self;
    self.completionBlock = ^{
        __strong COOperation *strongSelf = weakSelf;

        if (strongSelf.isFinished || strongSelf.isCancelled) {
            [originalCompletionBlock invoke];

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
    self.state = COOperationStateFinished;
}

- (void)cancel {
    self.state = COOperationStateCancelled;

    if (self.isCancelled) {
        if (self.completionBlock) self.completionBlock();
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
    return self.state == COOperationStateSuspended;
}

- (void)suspend {
    if (self.isFinished == NO && self.isCancelled == NO && self.isSuspended == NO) {
        self.state = COOperationStateSuspended;
    }
}

- (void)resume {
    if (self.isSuspended == NO || self.isFinished || self.isCancelled) return;

    // -resume reruns operation if it has no context. Context does a rerun otherwise
    if (self.numberOfRuns > 0 && self.contextOperation == nil) {
        [self reRun];
    } else {
        self.state = COOperationStateReady;
    }
}

#pragma mark
#pragma mark Resolution

- (void)resolveWithOperation:(COOperation *)operation {

    void (^originalCompletionBlock)(void) = operation.completionBlock;

    __weak COOperation *weakOperation = operation;

    operation.completionBlock = ^{
        __strong COOperation *strongOperation = weakOperation;

        if (strongOperation.isFinished) {
            [originalCompletionBlock invoke];

            [self finish];

            strongOperation.completionBlock = nil;
        } else if (strongOperation.isCancelled) {
            [originalCompletionBlock invoke];

            [self cancel];

            strongOperation.completionBlock = nil;
        }
    };

    CORunOperation(operation);
}

#pragma mark
#pragma mark <NSCopying>

- (id)copyWithZone:(NSZone *)zone {
    COOperation *operation = [[[self class] alloc] init];

    operation.operation = self.operation;

    return operation;
}

#pragma mark
#pragma mark <NSObject>

- (NSString *)description {
    NSString *description = [NSString stringWithFormat:@"%@ (debugLabel = %@; state = %@; numberOfRuns = %lu)", super.description, self.debugLabel, COKeyPathFromOperationState(self.state), (unsigned long)self.numberOfRuns];

    return description;
}

@end
