// CompositeOperations
//
// CompositeOperations/COCompositeOperation.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "COCompositeOperation.h"

#import "COQueues.h"

#import "COOperation_Private.h"
#import "COCompositeOperation_Private.h"

@implementation COCompositeOperation

@synthesize operationBlock = _operationBlock,
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

    self.concurrencyType = concurrencyType;

    self.lazyCopy = NO;
    
    self.result = [NSMutableArray array];

    [self _initializeZOperationAndCompletionBlock];

    return self;
}

- (void)dealloc {
    _data = nil;
    _operationBlock = nil;
    _operationQueue = nil;
    _zOperation = nil;
    _error = nil;
}

#pragma mark
#pragma mark Public API: Inner operations

- (void)run:(COCompositeOperationBlock)operationBlock completionHandler:(COCompositeOperationCompletionBlock)completionHandler cancellationHandler:(COCompositeOperationCancellationBlock)cancellationHandler {

    self.completionHandler = completionHandler;
    self.cancellationHandler = cancellationHandler;

    self.operationBlock = operationBlock;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self start];
    });
}

#pragma mark
#pragma mark Public API: Inner operations

- (void)operationInQueue:(dispatch_queue_t)queue operation:(COOperation *)operation {
    NSParameterAssert(operation && operation.operationBlock);

    if (queue) {
        COOperationBlock originalOperationBlock = operation.operationBlock;

        #if !OS_OBJECT_USE_OBJC
        dispatch_retain(queue);
        #endif

        COOperationBlock operationBlockInQueue = ^(COOperation *_operation) {
            dispatch_async(queue, ^{
                originalOperationBlock(_operation);
            });

            #if !OS_OBJECT_USE_OBJC
            dispatch_release(queue);
            #endif
        };

        operation.operationBlock = operationBlockInQueue;
    }

    COOperationBlock originalOperationBlock = operation.operationBlock;

    COOperationBlock operationBlockAdaptedToCompositeOperation = ^(COOperation *_operation) {
        NSUInteger isThereCancelledDependency = [_operation.dependencies indexOfObjectPassingTest:^BOOL(NSOperation *operation, NSUInteger idx, BOOL *stop) {
            if (operation.isCancelled) {
                *stop = YES;
                return YES;
            } else {
                return NO;
            }
        }];

        if (isThereCancelledDependency == NSNotFound) {
            originalOperationBlock(_operation);
        } else {
            [self cancel];
            [_operation reject];
        }
    };

    operation.operationBlock = operationBlockAdaptedToCompositeOperation;

    [self _registerDependency:operation];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.operationQueue addOperation:operation];
    });
}

- (void)operation:(COOperation *)operation {
    [self operationInQueue:CODefaultQueue() operation:operation];
}

- (void)operationWithBlock:(COOperationBlock)operationBlock {
    [self operationInQueue:CODefaultQueue() withBlock:operationBlock];
}

- (void)operationInQueue:(dispatch_queue_t)queue withBlock:(COOperationBlock)operationBlock {
    COOperation *operation = [COOperation new];

    operation.operationBlock = operationBlock;

    [self operationInQueue:queue operation:operation];
}


#pragma mark
#pragma mark Public API: Inner composite operations

- (void)compositeOperation:(COCompositeOperation *)compositeOperation {
    [self operationInQueue:nil operation:compositeOperation];
}

- (void)compositeOperation:(COCompositeOperationConcurrencyType)concurrencyType withBlock: (COCompositeOperationBlock)operationBlock {
    COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:concurrencyType];

    compositeOperation.operationBlock = operationBlock;

    [self operationInQueue:nil operation:compositeOperation];
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
    if (self.isLazyCopy) {
        [self lazyMain];

        return;
    }

    if (self.operationBlock) {
        NSAssert(self.operationQueue, nil);

        self.operationBlock(self);

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.operationQueue addOperation:self.zOperation];
        });
    } else {
        [self finish];
    }
}

- (void)lazyMain {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.concurrencyType == COCompositeOperationSerial) {
            NSUInteger indexOfFirstOperationToRun = [self.zOperation.dependencies indexOfObjectPassingTest:^BOOL(NSOperation *operation, NSUInteger idx, BOOL *stop) {
                if (operation.isReady) {
                    *stop = YES;
                    return YES;
                } else {
                    return NO;
                }
            }];

            NSAssert(indexOfFirstOperationToRun != NSNotFound, nil);

            id operation = [self.zOperation.dependencies objectAtIndex:indexOfFirstOperationToRun];

            [self.operationQueue addOperation:operation];
        } else {
            NSIndexSet *indexesOfOperationsToRun = [self.zOperation.dependencies indexesOfObjectsPassingTest:^BOOL(NSOperation *operation, NSUInteger idx, BOOL *stop) {
                if (operation.isReady) {
                    return YES;
                } else {
                    return NO;
                }
            }];

            NSAssert(indexesOfOperationsToRun.count > 0, nil);

            [self.zOperation.dependencies enumerateObjectsAtIndexes:indexesOfOperationsToRun options:0 usingBlock:^(id operation, NSUInteger idx, BOOL *stop) {
                [self.operationQueue addOperation:operation];
            }];
        }

        [self.operationQueue addOperation:self.zOperation];
    });
}

#pragma mark
#pragma mark <NSCopying>

- (id)copyWithZone:(NSZone *)zone {
    NSAssert(self.operationBlock, nil);
    NSAssert(self.operationQueue, nil);

    COCompositeOperation *compositeOperation = [[[self class] alloc] initWithConcurrencyType:self.concurrencyType];;

    compositeOperation.operationBlock = self.operationBlock;
    compositeOperation.completionHandler = self.completionHandler;
    compositeOperation.cancellationHandler = self.cancellationHandler;

    compositeOperation.operationQueue = self.operationQueue;
    compositeOperation.name = self.name;

    for (id operation in self.dependencies) {
        [compositeOperation addDependency:operation];
    }

    return compositeOperation;
}

- (instancetype)lazyCopy {
    COCompositeOperation *compositeOperation = [self copy];

    NSAssert(self.zOperation, nil);

    compositeOperation.lazyCopy = YES;

    NSAssert(compositeOperation.zOperation, nil);
    
    for (id operation in self.zOperation.dependencies) {
        id copyOfOperation;

        if ([operation respondsToSelector:@selector(lazyCopy)]) {
            copyOfOperation = [operation lazyCopy];
        } else if ([operation respondsToSelector:@selector(copyWithZone:)]) {
            copyOfOperation = [operation copy];
        } else {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Expected composite operation to have copyable dependency operations" userInfo:@{ @"Failing operation": operation }];
        }

        [compositeOperation.zOperation addDependency:copyOfOperation];
    }

    return compositeOperation;
}

#pragma mark
#pragma mark <NSObject>

- (NSString *)description {
    NSString *concurrencyString = self.concurrencyType == COCompositeOperationConcurrent ? @"Concurrent" : @"Serial";

    NSMutableArray *descriptionComponents = [NSMutableArray array];

    [descriptionComponents addObject:[NSString stringWithFormat:@"state = %@; isCancelled = %@", COKeyPathFromOperationState(self.state), self.isCancelled ? @"YES" : @"NO" ]];

    if (self.name) {
        [descriptionComponents addObject:[NSString stringWithFormat:@"name = '%@'", self.name]];
    }

    NSString *description = [NSString stringWithFormat:@"<%@[%@]: %p> (%@)", NSStringFromClass([self class]), concurrencyString, self, [descriptionComponents componentsJoinedByString:@"; "]];

    return description;
}

- (NSString *)debugDescription {
    // TODO

    return self.description;
}

#pragma mark
#pragma mark Private (level 0)

- (void)_registerDependency:(COOperation *)operation {
    operation.operationQueue = self.operationQueue;

    if (self.concurrencyType == COCompositeOperationSerial) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.zOperation.dependencies.count > 0) {
                COOperation *lastOperation = self.zOperation.dependencies.lastObject;

                [operation addDependency:lastOperation];
            }

            [self.zOperation addDependency:operation];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.zOperation addDependency:operation];
        });
    }
}

- (void)_initializeZOperationAndCompletionBlock {
    __weak COCompositeOperation *weakSelf = self;
    self.zOperation = [NSBlockOperation blockOperationWithBlock:^{
        __strong COCompositeOperation *strongSelf = weakSelf;

        NSAssert(strongSelf.zOperation, nil);
        NSAssert(strongSelf.zOperation.dependencies, nil);

        NSUInteger isThereCancelledDependency = [strongSelf.zOperation.dependencies indexOfObjectPassingTest:^BOOL(COOperation *operation, NSUInteger idx, BOOL *stop) {
            if (operation.isCancelled) {
                strongSelf.error = operation.error;

                *stop = YES;
                return YES;
            } else {
                return NO;
            }
        }];

        if (isThereCancelledDependency == NSNotFound) {
            [strongSelf finish];
        } else {
            [strongSelf reject];
        }
    }];

    self.completionBlock = ^{
        __strong COCompositeOperation *strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (strongSelf.isCancelled == NO) {
                if (strongSelf.completionHandler) {
                    strongSelf.completionHandler([strongSelf.result copy]);
                }
            } else if (strongSelf.cancellationHandler) {
                strongSelf.cancellationHandler(strongSelf, strongSelf.error);
            }

            [strongSelf _teardown];
        });
    };
}

- (void)_teardown {
    self.completionBlock = nil;

    self.operationQueue = nil;
    self.zOperation = nil;
}

@end
