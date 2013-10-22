// CompositeOperations
//
// CompositeOperations/COOperationQueue.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "COOperationQueue.h"

static inline NSString * COKeyPathFromOperationQueueState(COOperationQueueState state) {
    switch (state) {
        case COOperationQueueSuspendedState:
            return @"isSuspended";
        default:
            return @"isNormal";
    }
}

@implementation COOperationQueue

- (id)init {
    self = [super init];

    self.maximumOperationsLimit = 0;
    self.pendingOperations = [NSMutableArray array];
    self.runningOperations = [NSMutableArray array];
    self.queueType = COOperationQueueFIFO;
    self.state = COOperationQueueNormalState;

    return self;
}

- (void)dealloc {
    self.queue = nil;

    self.pendingOperations = nil;
    self.runningOperations = nil;
}

#pragma mark
#pragma mark Properties

- (void)setQueue:(dispatch_queue_t)queue {
#if !OS_OBJECT_USE_OBJC
    if (_queue) dispatch_release(_queue);

    if (queue) {
        dispatch_retain(queue);
    }
#endif

    _queue = queue;
}

- (dispatch_queue_t)queue {
    return _queue;
}

- (NSUInteger)operationCount {
    NSUInteger operationCount;

    @synchronized(self) {
        operationCount = self.pendingOperations.count + self.runningOperations.count;
    }

    return operationCount;
}

- (BOOL)isSuspended {
    return self.state == COOperationQueueSuspendedState;
}

#pragma mark
#pragma mark

- (void)addOperationWithBlock:(COBlock)operationBlock {
    COOperation *operation = [COOperation new];

    operation.operation = ^(COOperation *op){
        operationBlock();

        [op finish];
    };

    [self addOperation:operation];
}

#pragma mark
#pragma mark Enqueuing / Dequeuing

- (void)addOperation:(NSOperation *)operation {
    if (self.queue == nil) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"COOperationQueue: queue should be defined" userInfo:nil];
    }

    @synchronized(self) {
        switch (self.queueType) {
            case COOperationQueueFIFO:
                [self.pendingOperations addObject:operation];

                break;

            case COOperationQueueLIFO:
                [self.pendingOperations insertObject:operation atIndex:0];

                break;

            case COOperationQueueAggressiveLIFO:
                if (self.maximumOperationsLimit > 0 && self.pendingOperations.count == self.maximumOperationsLimit) {
                    COOperation *operation = (COOperation *)self.pendingOperations.lastObject;
                    [self.pendingOperations removeObject:operation];

                    [operation cancel];
                }

                [self.pendingOperations insertObject:operation atIndex:0];

                break;
                
            default:
                [self.pendingOperations addObject:operation];
                
                break;
        }

        [self _runNextOperationIfExists];
    }
}

- (void)_runNextOperationIfExists {
    if (self.isSuspended) return;
    
    @synchronized(self) {
        if (self.pendingOperations.count > 0 && (self.runningOperations.count < self.maximumOperationsLimit || (self.maximumOperationsLimit == 0))) {
            NSUInteger firstReadyOperationIndex = [self.pendingOperations indexOfObjectPassingTest:^BOOL(COOperation *operation, NSUInteger idx, BOOL *stop) {
                if (operation.isReady) {
                    *stop = YES;

                    return YES;
                } else {
                    return NO;
                }
            }];

            if (firstReadyOperationIndex != NSNotFound) {
                COOperation *operation = (COOperation *)[self.pendingOperations objectAtIndex:firstReadyOperationIndex];

                [operation addObserver:self
                            forKeyPath:@"isFinished"
                               options:NSKeyValueObservingOptionNew
                               context:NULL];

                [operation addObserver:self
                            forKeyPath:@"isCancelled"
                               options:NSKeyValueObservingOptionNew
                               context:NULL];

                [self.pendingOperations removeObjectAtIndex:firstReadyOperationIndex];
                [self.runningOperations addObject:operation];

                dispatch_async(self.queue, ^{
                    [operation start];
                });
            };
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    @synchronized(self) {
        if ([keyPath isEqualToString:@"isFinished"] || [keyPath isEqualToString:@"isCancelled"]) {
            BOOL done = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];

            if (done) {
                [object removeObserver:self forKeyPath:@"isFinished"];
                [object removeObserver:self forKeyPath:@"isCancelled"];

                [self.runningOperations removeObject:object];

                [self _runNextOperationIfExists];
            }
        }
    }
}

#pragma mark
#pragma mark Resume / Suspend

- (void)suspend {
    if (self.isSuspended == NO) {
        @synchronized(self) {
            self.state = COOperationQueueSuspendedState;
                        
            [[self.pendingOperations copy] makeObjectsPerformSelector:@selector(suspend)];

            // Do not suspend operations that are on the fly
            // [[self.runningOperations copy] makeObjectsPerformSelector:@selector(suspend)];
        }
    } else {
        // Should an exception be raised here?
    }
}

- (void)resume {
    @synchronized(self) {
        self.state = COOperationQueueNormalState;

        [[self.pendingOperations copy] makeObjectsPerformSelector:@selector(resume)];
        [[self.runningOperations copy] makeObjectsPerformSelector:@selector(resume)];
    }
}

#pragma mark
#pragma mark Cancellation

- (void)cancelAllOperations {
    @synchronized(self) {
        [[self.pendingOperations copy] makeObjectsPerformSelector:@selector(cancel)];
        [[self.runningOperations copy] makeObjectsPerformSelector:@selector(cancel)];
    }
}

#pragma mark
#pragma mark Removing

- (void)removeAllPendingOperations {
    @synchronized(self) {
        [self.pendingOperations removeAllObjects];
    }
}

#pragma mark
#pragma mark NSObject

- (NSString *)description {
    NSString *description;

    @synchronized(self) {
        description = [NSString stringWithFormat:@"%@ (\n\tstate = %@,\n\toperationCount = %u,\n\tpendingOperations = %@,\n\trunningOperations = %@,\n)", super.description, COKeyPathFromOperationQueueState(self.state), (unsigned)self.operationCount, self.pendingOperations, self.runningOperations];
    }

    return description;
}

- (NSString *)debugDescription {
    return self.description;
}

@end
