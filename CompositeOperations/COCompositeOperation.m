// CompositeOperations
//
// CompositeOperations/COCompositeOperation.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "COCompositeOperation.h"
#import "COCompositeOperation_Private.h"

#import "COQueues.h"

#import "COOperation_Private.h"
#import "COCompositeOperation_Private.h"

#import "COCompositeSerialOperationInternal.h"
#import "COCompositeConcurrentOperationInternal.h"

@interface COCompositeOperation ()
@property (strong, nonatomic) id <COCompositeOperationInternal> internal;
@end


@implementation COCompositeOperation

@synthesize operation = _operation,
            operations = _operations,
            operationQueue = _operationQueue,
            data = _data,
            error = _error;

- (id)init {
    @throw [NSException exceptionWithName:NSGenericException reason:@"Must not run -[COCompositeOperation init]. Use designated initialize -[CompositeOperation initWithConcurrencyType:] instead!" userInfo:nil];
    return nil;
}

- (id)initWithConcurrencyType:(COCompositeOperationConcurrencyType)concurrencyType {
    self = [super init];

    if (self == nil) return nil;

    if (concurrencyType == COCompositeOperationSerial) {
        self.internal = [[COCompositeSerialOperationInternal alloc] initWithCompositeOperation:self];
    } else if (concurrencyType == COCompositeOperationConcurrent) {
        self.internal = [[COCompositeConcurrentOperationInternal alloc] initWithCompositeOperation:self];
    } else {
        NSParameterAssert(NO);
    }

    self.concurrencyType = concurrencyType;

    [self addObserver:self
           forKeyPath:@"isFinished"
              options:NSKeyValueObservingOptionNew
              context:NULL];

    [self addObserver:self
           forKeyPath:@"isCancelled"
              options:NSKeyValueObservingOptionNew
              context:NULL];

    self.finishedOperationsCount = 0;
    
    return self;
}

- (void)initPropertiesForRun {
    [super initPropertiesForRun];

    self.operations = [NSMutableArray array];
    self.allSuboperationsRegistered = NO;

    self.data = nil;
    self.error = nil;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"isFinished"];
    [self removeObserver:self forKeyPath:@"isCancelled"];

    _data = nil;
    _operation = nil;
    _operationQueue = nil;
    _internal = nil;
    _error = nil;
}

#pragma mark
#pragma mark Public API: Inner operations

- (void)run:(COCompositeOperationBlock)operationBlock completionHandler:(COCompletionBlock)completionHandler cancellationHandler:(COCancellationBlockForCompositeOperation)cancellationHandler {
    self.operation = operationBlock;

    __weak COCompositeOperation *weakSelf = self;
    self.completionBlock = ^{
        __strong COCompositeOperation *strongSelf = weakSelf;

        if (strongSelf.isFinished) {
            if (completionHandler) completionHandler(strongSelf.data);

            strongSelf.completionBlock = nil;
        } else if (cancellationHandler) {
            [strongSelf _cancelOperations:NO];

            cancellationHandler(strongSelf, strongSelf.error);
        } else {
            [strongSelf cancel];

            strongSelf.completionBlock = nil;
        }
    };
    
    CORunOperation(self);
}

#pragma mark
#pragma mark Public API: Inner operations

- (void)operation:(COOperation *)operation {
    NSParameterAssert(operation && operation.operation);

    COOperationBlock originalOperationBlock = operation.operation;

#if !OS_OBJECT_USE_OBJC
    dispatch_retain(CODefaultQueue());
#endif

    COOperationBlock operationBlockInQueue = ^(COOperation *op) {
        dispatch_async(CODefaultQueue(), ^{
            // Ensuring isExecuting == YES to not run operations which have been already cancelled on contextOperation level
            if (op.isExecuting == YES && op.contextOperation.isExecuting == YES) {
                originalOperationBlock(op);
            }
        });
    };

    operation.operation = operationBlockInQueue;

#if !OS_OBJECT_USE_OBJC
    COOperation *weakOperation = operation;
    operation.completionBlock = ^{
        __strong COOperation *strongOperation = weakOperation;

        if (strongOperation.isFinished || strongOperation.isCancelled) {
            dispatch_release(CODefaultQueue());

            strongOperation.completionBlock = nil;
        }
    };
#endif

    [self.internal _enqueueSuboperation:operation];
}

- (void)operationWithBlock:(COOperationBlock)operationBlock {
    [self operationInQueue:CODefaultQueue() withBlock:operationBlock];
}

- (void)operationInQueue:(dispatch_queue_t)queue withBlock:(COOperationBlock)operationBlock {
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

    [self.internal _enqueueSuboperation:operation];
}

#pragma mark
#pragma mark Public API: Inner composite operations

- (void)compositeOperation:(COCompositeOperation *)compositeOperation {
    __weak COCompositeOperation *weakCompositeOperation = compositeOperation;

    compositeOperation.completionBlock = ^{
        __strong COCompositeOperation *strongCompositeOperation = weakCompositeOperation;

        if (strongCompositeOperation.isFinished) {
            strongCompositeOperation.completionBlock = nil;
        } else {
            [strongCompositeOperation cancel];
        }
    };

    [self.internal _enqueueSuboperation:compositeOperation];
}

- (void)compositeOperation:(COCompositeOperationConcurrencyType)concurrencyType withBlock: (COCompositeOperationBlock)operationBlock {
    COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:concurrencyType];

    compositeOperation.operation = operationBlock;

    __weak COCompositeOperation *weakCompositeOperation = compositeOperation;
    
    compositeOperation.completionBlock = ^{
        __strong COCompositeOperation *strongCompositeOperation = weakCompositeOperation;

        if (strongCompositeOperation.isFinished) {
            strongCompositeOperation.completionBlock = nil;
        } else {
            [strongCompositeOperation cancel];
        }
    };

    [self.internal _enqueueSuboperation:compositeOperation];
}

#pragma mark
#pragma mark Public API: Data

- (void)safelyAccessData:(COModificationBlock)modificationBlock {
    @synchronized(self) {
        self.data = modificationBlock(self.data);
    }
}

#pragma mark
#pragma mark COOperation

- (void)main {
    self.operation(self);

    @synchronized(self) {
        self.allSuboperationsRegistered = YES;
        [self.internal _performCheckpointRoutineIncrementingNumberOfFinishedOperations:NO];
    }
}

- (void)cancel {
    @synchronized(self) {
        if (self.isFinished == NO && self.isCancelled == NO && self.isSuspended == NO) {
            [self _cancelOperations:YES];

            self.state = COOperationStateCancelled;
        }
    }
}

#pragma mark
#pragma mark COOperation: Rerun / Awake

- (void)awake {
    if (self.isCancelled == NO && self.isFinished == NO) {
        if (self.numberOfRuns == 0) {
            [self reRun];
        } else {
            self.state = COOperationStateExecuting;

            [self.internal _performAwakeRoutine];
        }
    }
}

#pragma mark
#pragma mark COOperation: Suspend / Resume

- (void)suspend {
    if (self.isFinished == NO && self.isCancelled == NO && self.isSuspended == NO) {
        @synchronized(self) {
            [self.operations makeObjectsPerformSelector:@selector(suspend)];

            [super suspend];
        }
    }
}

- (void)resume {
    if (self.isSuspended == NO) return;

    if (self.numberOfRuns > 0) {
        self.state = COOperationStateExecuting;

        [self.operations makeObjectsPerformSelector:@selector(resume)];

        [self.internal _performResumeRoutine];
    } else {
        self.state = COOperationStateReady;
    }
}

#pragma mark
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self]) {
        [self _teardown];
    } else {        
        @synchronized(self) {
            [object removeObserver:self forKeyPath:@"isFinished"];
            [object removeObserver:self forKeyPath:@"isCancelled"];
        }

        COOperation *operation = (COOperation *)object;

        if ([keyPath isEqual:@"isFinished"]) {
            [self _operationWasFinished:operation];
        } else if ([keyPath isEqual:@"isCancelled"]) {
            [self _operationWasCancelled:operation];
        }
    }
}

#pragma mark
#pragma mark <NSCopying>

- (id)copyWithZone:(NSZone *)zone {
    return nil;
}

#pragma mark
#pragma mark Private (level 0)

- (void)_cancelOperations:(BOOL)runCompletionBlocks {
    @synchronized(self) {
        [self.operations enumerateObjectsUsingBlock:^(COOperation *operation, NSUInteger idx, BOOL *stop) {
            if (operation.isCancelled == NO && operation.isFinished == NO) {
                if (operation.isReady == NO) {
                    [operation removeObserver:self forKeyPath:@"isFinished"];
                    [operation removeObserver:self forKeyPath:@"isCancelled"];
                }

                [operation cancel];

                if (runCompletionBlocks && operation.completionBlock) {
                    operation.completionBlock();
                }
            }
        }];

    }
}

#pragma mark
#pragma mark Private (level 1)

- (void)_teardown {
    for (COOperation *operation in self.operations) {
        operation.contextOperation = nil;
    }

    // TODO: this fixes the issue when -main calls -_performCheckpointRoutineIncrementingNumberOfFinishedOperations at the moment after some of operations cancelled the whole composite operation (self), when instead -isCancelled state it also re-triggers -finish
    self.completionBlock = nil;

    self.operations = nil;
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
    COOperation *operation;

    @synchronized(self) {
        operation = [self.operations objectAtIndex:indexOfSuboperationToRun];
    }

    [self _runSuboperation:operation];
}

- (void)_operationWasCancelled:(COOperation *)subOperation {
    // TODO: cancelled when operation is suspended
    @synchronized(self) {
        self.error = subOperation.error;
        [self.completionBlock invoke];
    }
}

- (void)_operationWasFinished:(COOperation *)subOperation {
    [self.internal _performCheckpointRoutineIncrementingNumberOfFinishedOperations:YES];
}

#pragma mark
#pragma mark <NSObject>

- (NSString *)description {
    NSString *concurrencyString = self.concurrencyType == COCompositeOperationConcurrent ? @"Concurrent" : @"Serial";

    NSString *description = [NSString stringWithFormat:@"<%@[%@]: %p> (state = %@; numberOfRuns = %lu; operations = %@)", NSStringFromClass([self class]), concurrencyString, self, COKeyPathFromOperationState(self.state), (unsigned long)self.numberOfRuns, self.operations.count > 0 ? self.operations : nil];

    return description;
}

@end
