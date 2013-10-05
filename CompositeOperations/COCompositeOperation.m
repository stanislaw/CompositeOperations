//
//  SACompositeOperation.m
//  SACompositeOperationsApp
//
//  Created by Stanislaw Pankevich on 5/14/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import "SACompositeOperation.h"

#import "SAQueues.h"

#import "SACascadeOperation.h"
#import "SATransactionalOperation.h"
#import "SATypedefs.h"

@implementation SAAbstractCompositeOperation

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

- (void)operation:(SAOperationBlock)operationBlock {
    [self operationInQueue:SADefaultQueue() operation:operationBlock];
}

- (void)operationInQueue:(dispatch_queue_t)queue operation:(SAOperationBlock)operationBlock {
    @synchronized(self) {
        SAOperation *operation = [SAOperation new];

#if !OS_OBJECT_USE_OBJC
        dispatch_retain(queue);
#endif

        SAOperationBlock operationBlockInQueue = ^(SAOperation *op) {
            dispatch_async(queue, ^{
                // Ensuring isExecuting == YES to not run operations which have been already cancelled on contextOperation level
                if (op.isExecuting == YES && op.contextOperation.isExecuting == YES) {
                    operationBlock(op);
                }
            });
        };

        operation.operation = operationBlockInQueue;

#if !OS_OBJECT_USE_OBJC
        SAOperation *weakOperation = operation;
        operation.completionBlock = ^{
            __strong SAOperation *strongOperation = weakOperation;

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

- (void)cascadeOperation:(SACascadeOperationBlock)operationBlock {
    @synchronized(self) {
        SACascadeOperation *cascadeOperation = [SACascadeOperation new];

        cascadeOperation.operation = operationBlock;

        __weak SACascadeOperation *weakCascadeOperation = cascadeOperation;
        cascadeOperation.completionBlock = ^{
            __strong SACascadeOperation *strongCascadeOperation = weakCascadeOperation;

            if (strongCascadeOperation.isFinished) {
            } else {
                [strongCascadeOperation cancel];
            }

            strongCascadeOperation.completionBlock = nil;
        };

        [self enqueueSuboperation:cascadeOperation];
    }
}

- (void)transactionalOperation:(SATransactionalOperationBlock)operationBlock {
    SATransactionalOperation *transactionalOperation = [SATransactionalOperation new];

    transactionalOperation.operation = operationBlock;

    __weak SATransactionalOperation *weakTransactionalOperation = transactionalOperation;
    transactionalOperation.completionBlock = ^{
        __strong SATransactionalOperation *strongTransactionalOperation = weakTransactionalOperation;

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

- (void)modifySharedData:(SAModificationBlock)modificationBlock {
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

            self.state = SAOperationCancelledState;
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
            self.state = SAOperationExecutingState;

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
            self.state = SAOperationExecutingState;

            [self.operations makeObjectsPerformSelector:@selector(resume)];

            [self performResumeRoutine];
        } else {
            self.state = SAOperationReadyState;
        }
    }
}

#pragma mark
#pragma mark <SACompositeOperation>

- (void)enqueueSuboperation:(SAOperation *)subOperation {}

- (void)performCheckpointRoutine {}
- (void)performAwakeRoutine {}
- (void)performResumeRoutine {}

- (void)subOperationWasCancelled:(SAOperation *)subOperation {
    self.completionBlock();
}

- (void)subOperationWasFinished:(SAOperation *)subOperation {}

#pragma mark
#pragma mark Private methods

- (void)_teardown {    
    for (SAOperation *operation in self.operations) {
        operation.contextOperation = nil;
    }

    self.operations = nil;
}

- (void)_enqueueSuboperation:(SAOperation *)subOperation {
    // 
}

- (void)_registerSuboperation:(SAOperation *)subOperation {
    subOperation.contextOperation = self;
    subOperation.operationQueue = self.operationQueue;

    @synchronized(self) {
        [self.operations addObject:subOperation];
    }
}

- (void)_runSuboperation:(SAOperation *)subOperation {
    [subOperation addObserver:self
                forKeyPath:@"isFinished"
                   options:NSKeyValueObservingOptionNew
                   context:NULL];

    [subOperation addObserver:self
                forKeyPath:@"isCancelled"
                   options:NSKeyValueObservingOptionNew
                   context:NULL];

    SARunOperation(subOperation);
}

- (void)_runSuboperationAtIndex:(NSUInteger)indexOfSuboperationToRun {
    SAOperation *operation = [self.operations objectAtIndex:indexOfSuboperationToRun];

    [self _runSuboperation:operation];
}

- (void)_cancelSuboperations:(BOOL)runCompletionBlocks {
    @synchronized(self) {
        [[self.operations copy] enumerateObjectsUsingBlock:^(SAOperation *operation, NSUInteger idx, BOOL *stop) {
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

            SAOperation *operation = (SAOperation *)object;

            if ([keyPath isEqual:@"isFinished"]) {
                [self subOperationWasFinished:operation];
            } else if ([keyPath isEqual:@"isCancelled"]) {
                [self subOperationWasCancelled:operation];
            }
        }
    }
}

@end
