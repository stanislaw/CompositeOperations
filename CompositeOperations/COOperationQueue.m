#import "SAOperationQueue.h"

static inline NSString * SAKeyPathFromOperationQueueState(SAOperationQueueState state) {
    switch (state) {
        case SAOperationQueueSuspendedState:
            return @"isSuspended";
        default:
            return @"isNormal";
    }
}

@implementation SAOperationQueue

- (id)init {
    self = [super init];

    self.maximumOperationsLimit = 0;
    self.pendingOperations = [NSMutableArray array];
    self.runningOperations = [NSMutableArray array];
    self.queueType = SAOperationQueueFIFO;
    self.state = SAOperationQueueNormalState;

    return self;
}

- (void)dealloc {
    self.queue = nil;

    self.pendingOperations = nil;
    self.runningOperations = nil;
}

- (NSString *)stateKey {
    return SAKeyPathFromOperationQueueState(self.state);
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
    return self.state == SAOperationQueueSuspendedState;
}

#pragma mark
#pragma mark

- (void)addOperationWithBlock:(SABlock)operationBlock {
    SAOperation *operation = [SAOperation new];

    operation.operation = ^(SAOperation *op){
        operationBlock();

        [op finish];
    };

    [self addOperation:operation];
}

#pragma mark
#pragma mark Enqueuing / Dequeuing

- (void)addOperation:(NSOperation *)operation {
    if (self.queue == nil) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"SAOperationQueue: queue should be defined" userInfo:nil];
    }

    @synchronized(self) {
        switch (self.queueType) {
            case SAOperationQueueFIFO:
                [self.pendingOperations addObject:operation];

                break;

            case SAOperationQueueLIFO:
                [self.pendingOperations insertObject:operation atIndex:0];

                break;

            case SAOperationQueueAggressiveLIFO:
                if (self.maximumOperationsLimit > 0 && self.pendingOperations.count == self.maximumOperationsLimit) {
                    SAOperation *operation = (SAOperation *)self.pendingOperations.lastObject;
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
            NSUInteger firstReadyOperationIndex = [self.pendingOperations indexOfObjectPassingTest:^BOOL(SAOperation *operation, NSUInteger idx, BOOL *stop) {
                if (operation.isReady) {
                    *stop = YES;

                    return YES;
                } else {
                    return NO;
                }
            }];

            if (firstReadyOperationIndex != NSNotFound) {
                SAOperation *operation = (SAOperation *)[self.pendingOperations objectAtIndex:firstReadyOperationIndex];

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
            self.state = SAOperationQueueSuspendedState;
                        
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
        self.state = SAOperationQueueNormalState;

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
        description = [NSString stringWithFormat:@"%@ (\n\tstate = %@,\n\toperationCount = %u,\n\tpendingOperations = %@,\n\trunningOperations = %@,\n)", super.description, self.stateKey, (unsigned)self.operationCount, self.pendingOperations, self.runningOperations];
    }

    return description;
}

- (NSString *)debugDescription {
    return self.description;
}

@end
