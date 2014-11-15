// NSOperationQueueController
//
// NSOperationQueueController/NSOperationQueueController.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "NSOperationQueueController.h"

#import "NSOperationQueueController_Private.h"

@implementation NSOperationQueueController

- (id)init {
    @throw [NSException exceptionWithName:NSGenericException reason:@"Must not run -[NSOperationQueueController init]. Use designated initializer -[NSOperationQueueController initWithOperationQueue:] instead!" userInfo:nil];
    return nil;
}

- (instancetype)initWithOperationQueue:(NSOperationQueue *)operationQueue {
    self = [super init];

    if (self == nil) return nil;

    self.operationQueue = operationQueue;

    self.pendingOperations = [NSMutableArray array];
    self.enqueuedOperations = [NSMutableArray array];

    self.order = NSOperationQueueControllerOrderFIFO;
    self.limit = 0;

    return self;
}

- (void)dealloc {
    self.pendingOperations = nil;
    self.enqueuedOperations = nil;
}

#pragma mark
#pragma mark Properties

- (NSUInteger)operationCount {
    NSUInteger operationCount;

    @synchronized(self) {
        operationCount = self.pendingOperations.count + self.enqueuedOperations.count;
    }

    return operationCount;
}

#pragma mark
#pragma mark NSOperation

- (NSUInteger)maxConcurrentOperationCount {
    return self.operationQueue.maxConcurrentOperationCount;
}

- (void)addOperation:(NSOperation *)operation {
    if (self.operationQueue == nil) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"NSOperationQueueController: operation queue should be defined" userInfo:nil];
    }

    @synchronized(self) {
        if (self.limit > 0 && self.pendingOperations.count == self.limit) {
            NSOperation *operationToCancelAndIgnore;

            if (self.order == NSOperationQueueControllerOrderFIFO) {
                operationToCancelAndIgnore = self.pendingOperations.firstObject;
            } else {
                operationToCancelAndIgnore = self.pendingOperations.lastObject;
            }

            [operationToCancelAndIgnore cancel];

            [self.pendingOperations removeObject:operationToCancelAndIgnore];

            [self.operationQueue addOperation:operationToCancelAndIgnore];
        }

        [self.pendingOperations addObject:operation];
    }

    [self _runNextOperationIfExists];
}

- (void)addOperationWithBlock:(void (^)(void))operationBlock {
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:operationBlock];

    [self addOperation:operation];
}

- (BOOL)isSuspended {
    return self.operationQueue.isSuspended;
}

- (void)setSuspended:(BOOL)suspend {
    [self.operationQueue setSuspended:suspend];

    if (suspend == NO) {
        [self _triggerIsReadyChecksOnEnqueuedOperations];

        [self _runNextOperationIfExists];
    }
}

- (void)cancelAllOperations {
    @synchronized(self) {
        [self.pendingOperations makeObjectsPerformSelector:@selector(cancel)];
    }

    [self.operationQueue cancelAllOperations];
}

- (void)cancelAndRunOutAllPendingOperations {
    [self cancelAllOperations];

    for (NSOperation *operation in self.pendingOperations) {
        [self.operationQueue addOperation:operation];
    }
}

#pragma mark
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    @synchronized(self) {
        if ([keyPath isEqualToString:@"isFinished"]) {
            [object removeObserver:self forKeyPath:@"isFinished"];
            [object removeObserver:self forKeyPath:@"isExecuting"];
            [object removeObserver:self forKeyPath:@"isCancelled"];

            [self.enqueuedOperations removeObject:object];

            if ([self.delegate respondsToSelector:@selector(operationQueueController:operationDidFinish:)]) {
                [self.delegate operationQueueController:self operationDidFinish:object];
            }
        }

        else if ([keyPath isEqualToString:@"isExecuting"]) {
            BOOL newValue = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];

            if (newValue) {
                if ([self.delegate respondsToSelector:@selector(operationQueueController:operationDidStartExecuting:)]) {
                    [self.delegate operationQueueController:self operationDidStartExecuting:object];
                }
            }
        }

        else if ([keyPath isEqualToString:@"isCancelled"]) {
            if ([self.delegate respondsToSelector:@selector(operationQueueController:operationDidCancel:)]) {
                [self.delegate operationQueueController:self operationDidCancel:object];
            }
        }
    }

    [self _runNextOperationIfExists];
}

#pragma mark
#pragma mark NSObject

- (NSString *)description {
    NSString *description;

    @synchronized(self) {
        description = [NSString stringWithFormat:@"%@ (\n\tisSuspended = %@,\n\toperationCount = %u,\n\tpendingOperations = %@,\n\tenqueuedOperations = %@,\n)", super.description, self.isSuspended ? @"YES" : @"NO", (unsigned)self.operationCount, self.pendingOperations, self.enqueuedOperations];
    }

    return description;
}

- (NSString *)debugDescription {
    return self.description;
}

#pragma mark
#pragma mark Private (level 0)

- (void)_runNextOperationIfExists {
    if (self.isSuspended) return;

    @synchronized(self) {
        NSUInteger numberOfOperationsToRun = [self numberOfPendingOperationsToRun];
        if (numberOfOperationsToRun == 0) return;

        NSIndexSet *indexesOfOperationsToRun;

        if (self.order == NSOperationQueueControllerOrderFIFO) {
            indexesOfOperationsToRun = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numberOfOperationsToRun)];
        } else {
            indexesOfOperationsToRun = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.pendingOperations.count - numberOfOperationsToRun, numberOfOperationsToRun)];
        }

        NSEnumerationOptions enumerationOptions = 0;

        if (self.order != NSOperationQueueControllerOrderFIFO) {
            enumerationOptions = NSEnumerationReverse;
        }

        NSArray *operationsToEnqueue = [self.pendingOperations objectsAtIndexes:indexesOfOperationsToRun];

        [self.pendingOperations removeObjectsAtIndexes:indexesOfOperationsToRun];

        [operationsToEnqueue enumerateObjectsWithOptions:enumerationOptions usingBlock:^(NSOperation *operation, NSUInteger idx, BOOL *stop) {
            [operation addObserver:self
                        forKeyPath:@"isFinished"
                           options:NSKeyValueObservingOptionNew
                           context:NULL];
            [operation addObserver:self
                        forKeyPath:@"isExecuting"
                           options:NSKeyValueObservingOptionNew
                           context:NULL];
            [operation addObserver:self
                        forKeyPath:@"isCancelled"
                           options:NSKeyValueObservingOptionNew
                           context:NULL];

            [self.enqueuedOperations addObject:operation];

            [self.operationQueue addOperation:operation];
        }];
    }
}

- (void)_triggerIsReadyChecksOnEnqueuedOperations {
    @synchronized(self) {
        [self.enqueuedOperations enumerateObjectsUsingBlock:^(NSOperation *operation, NSUInteger idx, BOOL *stop) {
            [operation willChangeValueForKey:@"isReady"];
            [operation didChangeValueForKey:@"isReady"];
        }];
    }
}

- (NSUInteger)numberOfPendingOperationsToRun {
    return numberOfPendingOperationsToRun(self.pendingOperations.count, self.enqueuedOperations.count, self.maxConcurrentOperationCount);
}

@end
