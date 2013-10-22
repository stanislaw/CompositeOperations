// CompositeOperations
//
// CompositeOperations/COCompositeOperation.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "COCompositeOperation.h"

#import "COQueues.h"

#import "COOperation_Private.h"
#import "COCascadeOperation.h"
#import "COTransactionalOperation.h"
#import "COTypedefs.h"

@implementation COAbstractCompositeOperation

@synthesize operation = _operation,
            operations = _operations,
            operationQueue = _operationQueue,
            sharedData = _sharedData;

- (id)init {
    self = [super init];

    if (self) {
        [self addObserver:self
               forKeyPath:@"isFinished"
                  options:NSKeyValueObservingOptionNew
                  context:NULL];

        [self addObserver:self
               forKeyPath:@"isCancelled"
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    }

    return self;
}

- (void)initPropertiesForRun {
    [super initPropertiesForRun];

    self.operations = [NSMutableArray array];
    self.allSuboperationsRegistered = NO;

    self.sharedData = nil;
}

- (void)dealloc {
    _sharedData = nil;
    _operation = nil;
    _operationQueue = nil;

    [self removeObserver:self forKeyPath:@"isFinished"];
    [self removeObserver:self forKeyPath:@"isCancelled"];
}

#pragma mark
#pragma mark Public API: Inner operations

- (void)operation:(COOperationBlock)operationBlock {
    [self operationInQueue:CODefaultQueue() operation:operationBlock];
}

- (void)operationInQueue:(dispatch_queue_t)queue operation:(COOperationBlock)operationBlock {
    @synchronized(self) {
        COOperation *operation = [COOperation new];

#if !OS_OBJECT_USE_OBJC
        dispatch_retain(queue);
#endif

        COOperationBlock operationBlockInQueue = ^(COOperation *op) {
            dispatch_async(queue, ^{
                // Ensuring isExecuting == YES to not run operations which have been already cancelled on contextOperation level
                if (op.isExecuting == YES && op.contextOperation.isExecuting == YES) {
                    operationBlock(op);
                }
            });
        };

        operation.operation = operationBlockInQueue;

#if !OS_OBJECT_USE_OBJC
        COOperation *weakOperation = operation;
        operation.completionBlock = ^{
            __strong COOperation *strongOperation = weakOperation;

            if (strongOperation.isFinished || strongOperation.isCancelled) {
                dispatch_release(queue);

                strongOperation.completionBlock = nil;
            }
        };
#endif
        
        [self enqueueSuboperation:operation];
    }
}

#pragma mark
#pragma mark Public API: Inner composite operations

- (void)cascadeOperation:(COCascadeOperationBlock)operationBlock {
    @synchronized(self) {
        COCascadeOperation *cascadeOperation = [COCascadeOperation new];

        cascadeOperation.operation = operationBlock;

        __weak COCascadeOperation *weakCascadeOperation = cascadeOperation;
        cascadeOperation.completionBlock = ^{
            __strong COCascadeOperation *strongCascadeOperation = weakCascadeOperation;

            if (strongCascadeOperation.isFinished) {
            } else {
                [strongCascadeOperation cancel];
            }

            strongCascadeOperation.completionBlock = nil;
        };

        [self enqueueSuboperation:cascadeOperation];
    }
}

- (void)transactionalOperation:(COTransactionalOperationBlock)operationBlock {
    COTransactionalOperation *transactionalOperation = [COTransactionalOperation new];

    transactionalOperation.operation = operationBlock;

    __weak COTransactionalOperation *weakTransactionalOperation = transactionalOperation;
    transactionalOperation.completionBlock = ^{
        __strong COTransactionalOperation *strongTransactionalOperation = weakTransactionalOperation;

        if (strongTransactionalOperation.isFinished) {
        } else {
            [strongTransactionalOperation cancel];
        }

        strongTransactionalOperation.completionBlock = nil;
    };
    
    [self enqueueSuboperation:transactionalOperation];
}

#pragma mark
#pragma mark Public API: Shared data

- (void)modifySharedData:(COModificationBlock)modificationBlock {
    @synchronized(self) {
        modificationBlock(self.sharedData);
    }
}

#pragma mark
#pragma mark SAOperation

- (void)main {
    self.operation(self);

    self.allSuboperationsRegistered = YES;

    [self performCheckpointRoutine];
}

- (void)cancel {
    @synchronized(self) {
        if (self.isFinished == NO && self.isCancelled == NO && self.isSuspended == NO) {
            [self _cancelSuboperations:YES];

            self.state = COOperationCancelledState;
        }
    }
}

#pragma mark
#pragma mark SAOperation: Rerun / Awake

- (void)awake {
    if (self.isCancelled == NO && self.isFinished == NO) {
        if (self.numberOfRuns == 0) {
            [self reRun];
        } else {
            self.state = COOperationExecutingState;

            [self performAwakeRoutine];
        }
    }
}

#pragma mark
#pragma mark SAOperation: Suspend / Resume

- (void)suspend {
    @synchronized(self) {
        if (self.isFinished == NO && self.isCancelled == NO && self.isSuspended == NO) {
            [[self.operations copy] makeObjectsPerformSelector:@selector(suspend)];

            [super suspend];
        }
    }
}

- (void)resume {
    if (self.isSuspended == NO) return;

    @synchronized(self) {
        if (self.numberOfRuns > 0) {
            self.state = COOperationExecutingState;

            [self.operations makeObjectsPerformSelector:@selector(resume)];

            [self performResumeRoutine];
        } else {
            self.state = COOperationReadyState;
        }
    }
}

#pragma mark
#pragma mark <SACompositeOperation>

- (void)enqueueSuboperation:(COOperation *)subOperation {}

- (void)performCheckpointRoutine {}
- (void)performAwakeRoutine {}
- (void)performResumeRoutine {}

- (void)subOperationWasCancelled:(COOperation *)subOperation {
    self.completionBlock();
}

- (void)subOperationWasFinished:(COOperation *)subOperation {}

#pragma mark
#pragma mark Private methods

- (void)_teardown {    
    for (COOperation *operation in self.operations) {
        operation.contextOperation = nil;
    }

    self.operations = nil;
}

- (void)_enqueueSuboperation:(COOperation *)subOperation {
    // 
}

- (void)_registerSuboperation:(COOperation *)subOperation {
    subOperation.contextOperation = self;
    subOperation.operationQueue = self.operationQueue;

    @synchronized(self) {
        [self.operations addObject:subOperation];
    }
}

- (void)_runSuboperation:(COOperation *)subOperation {
    [subOperation addObserver:self
                forKeyPath:@"isFinished"
                   options:NSKeyValueObservingOptionNew
                   context:NULL];

    [subOperation addObserver:self
                forKeyPath:@"isCancelled"
                   options:NSKeyValueObservingOptionNew
                   context:NULL];

    CORunOperation(subOperation);
}

- (void)_runSuboperationAtIndex:(NSUInteger)indexOfSuboperationToRun {
    COOperation *operation = [self.operations objectAtIndex:indexOfSuboperationToRun];

    [self _runSuboperation:operation];
}

- (void)_cancelSuboperations:(BOOL)runCompletionBlocks {
    @synchronized(self) {
        [[self.operations copy] enumerateObjectsUsingBlock:^(COOperation *operation, NSUInteger idx, BOOL *stop) {
            if (operation.isCancelled == NO && operation.isFinished == NO) {
                if (operation.isReady == NO) {
                    [operation removeObserver:self forKeyPath:@"isFinished"];
                    [operation removeObserver:self forKeyPath:@"isCancelled"];
                }

                [operation cancel];

                if (operation.completionBlock && runCompletionBlocks) operation.completionBlock();
            }
        }];
    }
}

#pragma mark
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    @synchronized(self) {
        if ([object isEqual:self]) {
            [self _teardown];
        } else {
            [object removeObserver:self forKeyPath:@"isFinished"];
            [object removeObserver:self forKeyPath:@"isCancelled"];

            COOperation *operation = (COOperation *)object;

            if ([keyPath isEqual:@"isFinished"]) {
                [self subOperationWasFinished:operation];
            } else if ([keyPath isEqual:@"isCancelled"]) {
                [self subOperationWasCancelled:operation];
            }
        }
    }
}

@end
