
#import <SenTestingKit/SenTestingKit.h>

#import "TestHelpers.h"

#import "CompositeOperations.h"
#import "COQueues.h"
#import "COOperationQueue.h"

@interface COOperationQueue ()
- (void) _runNextOperationIfExists;
@end

@interface OperationQueueTests : SenTestCase
@end

static int finishedOperationsCount;

@implementation OperationQueueTests

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    @synchronized(self) {
        if ([keyPath isEqual:@"isFinished"]) {
            BOOL finished = (BOOL)[[change objectForKey:NSKeyValueChangeNewKey] integerValue];

            if (finished == YES) {
                [object removeObserver:self forKeyPath:@"isFinished"];
                finishedOperationsCount++;
            }
        }
    }
}

- (void)setUp {
    [super setUp];
    
    finishedOperationsCount = 0;
}

- (void)test_addOperationWithBlock {
    __block BOOL isFinished = NO;

    COOperationQueue *opQueue = [COOperationQueue new];
    opQueue.maximumOperationsLimit = 0;
    opQueue.queue = concurrentQueue();

    [opQueue addOperationWithBlock:^{
        isFinished = YES;
    }];

    while(!isFinished || opQueue.runningOperations.count != 0) {}

    STAssertTrue(isFinished, nil);
    STAssertEquals((int)opQueue.runningOperations.count, 0, nil);
}

- (void)test_COOperationQueue_addOperation_max_limit_0 {
    for(int i = 0; i < 1; i++) {
    finishedOperationsCount = 0;

    int N = 100;

    NSMutableArray *countArr = [NSMutableArray array];

    COOperationQueue *opQueue = [COOperationQueue new];

    opQueue.maximumOperationsLimit = 0;

    opQueue.queue = concurrentQueue();

    int countDown = N;
    
    while (countDown-- > 0) {
        COOperation *o = [COOperation new];

        o.operationBlock = ^(COOperation *operation) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }

            [operation finish];
        };
        
        [o addObserver:self
                    forKeyPath:@"isFinished"
                       options:NSKeyValueObservingOptionNew
                       context:NULL];
        [opQueue addOperation:o];
    }

    while (finishedOperationsCount < N);

    STAssertEquals((int)countArr.count, N, nil);

    STAssertEquals(finishedOperationsCount, N, @"Expected finishedOperationsCount to be 100");
    }
}

- (void)test_COOperationQueue_addOperation_max_limit_1 {
    NSMutableArray *countArr = [NSMutableArray array];
    __block BOOL finished = NO;

    COOperationQueue *opQueue = [COOperationQueue new];
    opQueue.maximumOperationsLimit = 1;
    opQueue.queue = concurrentQueue();

    int countDown = 10;
    while (countDown-- > 0 ) {
        COOperation *o = [COOperation new];
        o.operationBlock = ^(COOperation *o) {
            STAssertEquals((int)opQueue.runningOperations.count, 1, nil);

            @synchronized(countArr) {
                [countArr addObject:@1];
            }

            [o finish];

            if (countArr.count == 10) {
                finished = YES;
            }
        };
        
        [opQueue.pendingOperations addObject:o];
    }

    [opQueue _runNextOperationIfExists];
    
    while (!finished);

    STAssertEquals((int)countArr.count, 10, nil);
}

- (void)test_COOperationQueue_removeAllPendingOperations {
    NSMutableArray *countArr = [NSMutableArray array];
    __block BOOL finished = NO;

    COOperationQueue *opQueue = [COOperationQueue new];
    opQueue.maximumOperationsLimit = 1;
    opQueue.queue = concurrentQueue();

    int countDown = 10;
    while (countDown-- > 0 ) {
        COOperation *o = [COOperation new];
        
        o.operationBlock = ^(COOperation *o) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            STAssertEquals((int)opQueue.runningOperations.count, 1, nil);
            
            if (countArr.count == 5) {
                STAssertEquals((int)opQueue.pendingOperations.count, 5, nil);
                [opQueue removeAllPendingOperations];
                STAssertEquals((int)opQueue.pendingOperations.count, 0, nil);

                [o finish];
                finished = YES;
            } else {
                [o finish];
            }
        };

        [opQueue.pendingOperations addObject:o];
    }

    [opQueue _runNextOperationIfExists];

    while (!finished);

    STAssertEquals((int)countArr.count, 5, nil);
}

- (void)test_aggressive_LIFO {
    __block BOOL isFinished = NO;
    
    COOperationQueue *operationQueue = [COOperationQueue new];

    operationQueue.queueType = COOperationQueueAggressiveLIFO;
    operationQueue.maximumOperationsLimit = 1;
    operationQueue.queue = serialQueue();
    
    operation(operationQueue, ^(COOperation *operation) {
        // Nothing intentionally - operation will never finish itself and will stay in runningOperations
    });

    operation(operationQueue, ^(COOperation *operation) {
        // Nothing intentionally - operation will never be run
        // Because it will be replaced by the following operation
        raiseShouldNotReachHere();
    }, ^(id result){}, ^(COOperation *operation, NSError *error){
        isFinished = YES;
    });

    operation(operationQueue, ^(COOperation *operation) {
        raiseShouldNotReachHere();
    }, ^(id result){
    }, ^(COOperation *operation, NSError *error){
    });

    while(isFinished == NO);

    STAssertTrue(isFinished, nil);
    STAssertEquals((int)operationQueue.pendingOperations.count, 1, nil);
}


@end
