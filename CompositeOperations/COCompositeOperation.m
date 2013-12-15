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

    self.internalCancelled = NO;

    self.registrationStarted = NO;
    self.registrationCompleted = NO;

    self.internalDependencies = [NSMutableArray array];
    
    self.data = nil;
    self.error = nil;

    self.result = [NSMutableArray array];
    
    return self;
}

- (void)dealloc {
    _data = nil;
    _operationBlock = nil;
    _operationQueue = nil;
    _error = nil;
}

#pragma mark
#pragma mark Public API: Inner operations

- (void)run:(COCompositeOperationBlock)operationBlock completionHandler:(COCompositeOperationCompletionBlock)completionHandler cancellationHandler:(COCompositeOperationCancellationBlock)cancellationHandler {
    __weak COCompositeOperation *weakSelf = self;
    self.completionBlock = ^{
        __strong COCompositeOperation *strongSelf = weakSelf;

        dispatch_async(dispatch_get_main_queue(), ^{
            if (strongSelf.isCancelled == NO) {
                if (completionHandler) {
                    completionHandler(strongSelf.result);
                }
            } else if (cancellationHandler) {
                cancellationHandler(strongSelf, strongSelf.error);
            }
        });

        strongSelf.completionBlock = nil;
    };

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
                if (self.isCancelled) {
                    [_operation cancel];
                } else {
                    originalOperationBlock(_operation);
                }

    #if !OS_OBJECT_USE_OBJC
                dispatch_release(queue);
    #endif  
            });
        };

        operation.operationBlock = operationBlockInQueue;
    }

    COOperation *weakOperation = operation;
    operation.completionBlock = ^{
        __strong COOperation *strongOperation = weakOperation;

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.concurrencyType == COCompositeOperationConcurrent) {
                [self internalStart];
            } else {
                if (strongOperation.isCancelled) {
                    self.internalCancelled = YES;

                    if (strongOperation.error) {
                        self.error = strongOperation.error;
                    }
                } else {
                    if (strongOperation.data) {
                        [self.result addObject:strongOperation.data];
                    }
                }

                NSUInteger indexOfFinishedOperation = [self.internalDependencies indexOfObject:strongOperation];

                if (indexOfFinishedOperation == self.internalDependencies.count - 1) {
                    [self internalStart];
                } else if (self.registrationCompleted) {
                    COOperation *nextOperation = [self.internalDependencies objectAtIndex:indexOfFinishedOperation + 1];
                    NSAssert([nextOperation.dependencies containsObject:strongOperation], nil);

                    if (nextOperation.isReady) {
                        [nextOperation start];
                    }
                } else {
                    //
                }
            }
        });

        strongOperation.completionBlock = nil;
    };


    [self _registerDependency:operation];

    dispatch_async(dispatch_get_main_queue(), ^{
        [operation start];
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

- (BOOL)isReady {
    return (self.registrationStarted == NO) && super.isReady;
}

- (BOOL)isInternalReady {
    if (self.isFinished) return NO;
    if (self.registrationStarted == NO) return NO;
    if (self.registrationCompleted == NO) return NO;

    NSUInteger isThereAnyUnfinishedOperation = [self.internalDependencies indexOfObjectPassingTest:^BOOL(COOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isFinished == NO) {
            *stop = YES;
            return YES;
        } else {
            return NO;
        }
    }];

    if (isThereAnyUnfinishedOperation != NSNotFound) return NO;

    isThereAnyUnfinishedOperation = [self.dependencies indexOfObjectPassingTest:^BOOL(COOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isFinished == NO) {
            *stop = YES;
            return YES;
        } else {
            return NO;
        }
    }];

    return isThereAnyUnfinishedOperation == NSNotFound;
}

- (BOOL)isCancelled {
    return super.isCancelled || self.internalCancelled;
}

- (void)start {
    if (self.isReady) {
        self.registrationStarted = YES;

        self.operationBlock(self);

        dispatch_async(dispatch_get_main_queue(), ^{
            self.registrationCompleted = YES;

            [self internalStart];
        });
    }
}

- (void)internalStart {
    if (self.internalReady) {
        self.state = COOperationStateExecuting;

        [self main];
    }
}

- (void)main {
    [self.dependencies enumerateObjectsUsingBlock:^(COOperation *operation, NSUInteger idx, BOOL *stop) {
        NSAssert(operation.isFinished, @"Expected %@ to have dependency finished: %@", self, operation);
    }];

    if (self.isInternalCancelled && super.isCancelled == NO) {
        [self cancel];
    } else {
        [self finish];
    }
}

#pragma mark
#pragma mark <NSCopying>

- (id)copyWithZone:(NSZone *)zone {
    COCompositeOperation *compositeOperation = [[[self class] alloc] initWithConcurrencyType:self.concurrencyType];;

    compositeOperation.operationBlock = self.operationBlock;
    compositeOperation.operationQueue = self.operationQueue;
    compositeOperation.name = self.name;

    return compositeOperation;
}

#pragma mark
#pragma mark Private (level 0)

- (void)_registerDependency:(COOperation *)operation {
    operation.operationQueue = self.operationQueue;

    if (self.concurrencyType == COCompositeOperationSerial) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.internalDependencies.count > 0) {
                COOperation *lastOperation = self.internalDependencies.lastObject;

                [operation addDependency:lastOperation];
            }

            [self.internalDependencies addObject:operation];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self addDependency:operation];
        });
    }
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
    
    NSString *concurrencyString = self.concurrencyType == COCompositeOperationConcurrent ? @"Concurrent" : @"Serial";

    NSString *description = [NSString stringWithFormat:@"<%@[%@]: %p> ((name = %@; registrationCompleted = %@; state = %@; isCancelled = %@; dependencies = %@; internalDependencies = %@)", NSStringFromClass([self class]), concurrencyString, self, self.name, self.registrationCompleted ? @"YES" : @"NO", COKeyPathFromOperationState(self.state), self.isCancelled ? @"YES" : @"NO", self.dependencies, self.internalDependencies];

    return description;
}

@end
