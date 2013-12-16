// CompositeOperations
//
// CompositeOperations/COOperation.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "COOperation.h"
#import "COOperation_Private.h"

#import "COQueues.h"

static inline int COStateTransitionIsValid(COOperationState fromState, COOperationState toState) {
    switch (fromState) {
        case COOperationStateReady:
            return YES;

        case COOperationStateExecuting:
            switch (toState) {
                case COOperationStateReady:
                    return -1;
                default:
                    return YES;
            }

        case COOperationStateFinished:
            return -1;

        default:
            return -1;
    }
}

@implementation COOperation

- (id)init {
    self = [super init];

    if (self == nil) return nil;

    _state = COOperationStateReady;

    return self;
}

- (void)dealloc {
    _operationBlock = nil;
}

#pragma mark
#pragma mark Properties

- (BOOL)isConcurrent {
    return YES;
}

- (void)setState:(COOperationState)state {
    if (COStateTransitionIsValid(self.state, state) == NO) {
        return;
    }
    
    @synchronized(self) {
        if (COStateTransitionIsValid(self.state, state) == NO) {
            return;
        }

        if (COStateTransitionIsValid(self.state, state) == -1) {
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
    if (self.state != COOperationStateReady) return NO;

    NSUInteger isThereAnyUnfinishedOperation = [self.dependencies indexOfObjectPassingTest:^BOOL(COOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isFinished == NO) {
            *stop = YES;
            return YES;
        } else {
            return NO;
        }
    }];

    // TODO: Strange NSOperation's behavior!
    //if ((isThereAnyUnfinishedOperation == NSNotFound) && (super.isReady == NO)) {
    //    abort();
    //}

    return isThereAnyUnfinishedOperation == NSNotFound;
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
    if (self.operationBlock) self.operationBlock(self);
}

- (void)start {
    if (self.isReady) {
        self.state = COOperationStateExecuting;

        if (self.isCancelled) {
            [self finish];
        } else {
            [self main];
        }
    }
}

- (void)run:(COOperationBlock)operationBlock {
    self.operationBlock = operationBlock;

    CORunOperation(self);
}

- (void)runInQueue:(dispatch_queue_t)queue operation:(COOperationBlock)operationBlock {
    COOperationBlock operationBlockInQueue = ^(COOperation *op) {

#if !OS_OBJECT_USE_OBJC
        dispatch_retain(queue);
#endif

        dispatch_async(queue, ^{
            if (op.isExecuting == YES) {
                operationBlock(op);
            }
#if !OS_OBJECT_USE_OBJC
            dispatch_release(queue);
#endif
        });
    };

    self.operationBlock = operationBlockInQueue;

    [self start];
}

- (void)run:(COOperationBlock)operationBlock completionHandler:(COOperationCompletionBlock)completionHandler cancellationHandler:(COOperationCancellationBlock)cancellationHandler {
    self.operationBlock = operationBlock;

    __weak COOperation *weakSelf = self;
    self.completionBlock = ^{
        __strong COOperation *strongSelf = weakSelf;

        if (strongSelf.isCancelled == NO) {
            if (completionHandler) completionHandler(strongSelf.data);

            strongSelf.completionBlock = nil;
        } else if (cancellationHandler) {
            cancellationHandler(strongSelf, strongSelf.error);

            strongSelf.completionBlock = nil;
        }
    };
    
    CORunOperation(self);
}

- (void)finish {
    self.state = COOperationStateFinished;
}

- (void)finishWithResult:(id)result {
    self.data = result;

    [self finish];
}

- (void)reject {
    [self cancel];
    [self finish];
}

- (void)rejectWithError:(NSError *)error {
    self.error = error;

    [self reject];
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

            [self finishWithResult:strongOperation.data];

            strongOperation.completionBlock = nil;
        } else if (strongOperation.isCancelled) {
            [originalCompletionBlock invoke];

            self.error = strongOperation.error;

            [self reject];

            strongOperation.completionBlock = nil;
        }
    };
    
    CORunOperation(operation);
}

#pragma mark
#pragma mark <NSCopying>

- (id)copyWithZone:(NSZone *)zone {
    COOperation *operation = [[[self class] alloc] init];

    operation.operationBlock = self.operationBlock;
    operation.operationQueue = self.operationQueue;
    operation.name = self.name;
    
    return operation;
}

#pragma mark
#pragma mark <NSObject>

- (NSString *)description {
    NSMutableArray *descriptionComponents = [NSMutableArray array];

    [descriptionComponents addObject:[NSString stringWithFormat:@"state = %@; isCancelled = %@", COKeyPathFromOperationState(self.state), self.isCancelled ? @"YES" : @"NO" ]];

    if (self.name) {
        [descriptionComponents addObject:[NSString stringWithFormat:@"name = '%@'", self.name]];
    }

    NSString *description = [NSString stringWithFormat:@"%@ (%@)", super.description, [descriptionComponents componentsJoinedByString:@"; "]];

    return description;
}

- (NSString *)debugDescription {

    // TODO
    return self.description;
}

@end
