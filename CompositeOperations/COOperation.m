// CompositeOperations
//
// CompositeOperations/COOperation.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

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
    return self.state == COOperationStateReady && super.isReady;
}

- (BOOL)isExecuting {
    return self.state == COOperationStateExecuting;
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
        self.state = COOperationStateFinished;
    }
}

- (BOOL)isCancelled {
    return self.state == COOperationStateCancelled;
}

- (void)cancel {
    if (self.isFinished == NO && self.isCancelled == NO && self.isSuspended == NO) {
        self.state = COOperationStateCancelled;

        if (self.contextOperation == nil && self.completionBlock) self.completionBlock();
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
#pragma mark <NSCopying>

- (id)copyWithZone:(NSZone *)zone {
    COOperation *operation = [[[self class] alloc] init];

    operation.operation = self.operation;

    return operation;
}

#pragma mark
#pragma mark <NSObject>

- (NSString *)description {
    NSString *description = [NSString stringWithFormat:@"%@ (state = %@, numberOfRuns = %lu)", super.description, COKeyPathFromOperationState(self.state), (unsigned long)self.numberOfRuns];

    return description;
}

@end
