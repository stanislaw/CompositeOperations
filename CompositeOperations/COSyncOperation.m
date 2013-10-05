#import "SASyncOperation.h"

@implementation SASyncOperation

@synthesize operation = _operation;

- (void)dealloc {
    _semaphore = nil;
    _operation = nil;
}

- (BOOL)isConcurrent {
    return NO;
}

#pragma mark
#pragma mark Start, run

- (void)start {
    if (self.isReady) {
        self.state = SAOperationExecutingState;

        if (self.isCancelled) {
            [self finish];
        } else {
            [self addObserver: self
                   forKeyPath: @"isFinished"
                      options: NSKeyValueObservingOptionNew
                      context: NULL];

            self.operation(self);

            if (self.isFinished == NO) {
                [self _blockThreadAndWait];
            }
        }
    }
}

- (void)run:(SASyncOperationBlock)operationBlock {
    self.operation = operationBlock;

    [self start];
}

- (void)runInQueue:(dispatch_queue_t)queue operation:(SASyncOperationBlock)operationBlock {
#if !OS_OBJECT_USE_OBJC
    dispatch_retain(queue);
#endif

    SASyncOperationBlock operationBlockInQueue = ^(SASyncOperation *op) {
        dispatch_async(queue, ^{
            if (op.isExecuting == YES) {
                operationBlock(op);
            }
        });
    };

    self.operation = operationBlockInQueue;

#if !OS_OBJECT_USE_OBJC
    SASyncOperation *weakSelf = self;
    self.completionBlock = ^{
        __strong SASyncOperation *strongSelf = weakSelf;

        if (strongSelf.isFinished || strongSelf.isCancelled) {
            dispatch_release(queue);

            strongSelf.completionBlock = nil;
        }
    };
#endif
    
    [self start];
}

#pragma mark
#pragma mark Flow control

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    @synchronized(self) {
        if ([keyPath isEqual:@"isFinished"]) {
            BOOL finished = (BOOL)[[change objectForKey:NSKeyValueChangeNewKey] integerValue];

            if (finished) {
                [object removeObserver:self forKeyPath:@"isFinished"];
                
                [self _unblockThread];
            }
        }
    }
}

- (void)_blockThreadAndWait {
    self.semaphore = dispatch_semaphore_create(0);

    if ((self.isOnMainThread = [NSThread isMainThread])) {
        while (dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_NOW)) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, [[NSDate distantFuture] timeIntervalSinceNow], NO);
        }
    } else {
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    }
}

- (void)_unblockThread {
    if (self.semaphore) {
        dispatch_semaphore_signal(self.semaphore);

        if (self.isOnMainThread) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CFRunLoopStop(CFRunLoopGetMain());
            });
        }
    }
}

@end
