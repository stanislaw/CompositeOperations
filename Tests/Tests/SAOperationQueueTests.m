//
//  CascadeOperationsTests.m
//  CompositeOperationsTests
//
//  Created by Stanislaw Pankevich on 10/20/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "TestHelpers.h"

#import "SASyncOperation.h"
#import "SACompositeOperations.h"
#import "SAQueues.h"
#import "SAOperationQueue.h"

@interface SAOperationQueue ()
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
    __block BOOL done = NO;

    SAOperationQueue *opQueue = [SAOperationQueue new];
    opQueue.maximumOperationsLimit = 0;
    opQueue.queue = concurrentQueue();

    [opQueue addOperationWithBlock:^{
        done = YES;
    }];

    while(!done || opQueue.runningOperations.count != 0) {}

    STAssertTrue(done, nil);
    STAssertEquals((int)opQueue.runningOperations.count, 0, nil);
}

- (void)test_SAOperationQueue_addOperation_max_limit_0 {
    int N = 100;

    NSMutableArray *countArr = [NSMutableArray array];

    SAOperationQueue *opQueue = [SAOperationQueue new];

    opQueue.maximumOperationsLimit = 0;

    opQueue.queue = concurrentQueue();

    int countDown = N;
    
    while (countDown-- > 0) {
        SAOperation *o = [SAOperation new];

        o.operation = ^(SAOperation *operation) {
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

- (void)test_SAOperationQueue_addOperation_max_limit_1 {
    NSMutableArray *countArr = [NSMutableArray array];
    __block BOOL finished = NO;

    SAOperationQueue *opQueue = [SAOperationQueue new];
    opQueue.maximumOperationsLimit = 1;
    opQueue.queue = concurrentQueue();

    int countDown = 10;
    while (countDown-- > 0 ) {
        SAOperation *o = [SAOperation new];
        o.operation = ^(SAOperation *o) {
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

- (void)test_SAOperationQueue_removeAllPendingOperations {
    NSMutableArray *countArr = [NSMutableArray array];
    __block BOOL finished = NO;

    SAOperationQueue *opQueue = [SAOperationQueue new];
    opQueue.maximumOperationsLimit = 1;
    opQueue.queue = concurrentQueue();

    int countDown = 10;
    while (countDown-- > 0 ) {
        SAOperation *o = [SAOperation new];
        
        o.operation = ^(SAOperation *o) {
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

// SAOperationQueue suspends only pendingOperations - it does not touch on-the-fly operations, leaving them to manage their states.
// But when resuming, it does call 'resume' on both pending and running operations.
- (void)test_suspend_and_resume {
    SAOperationQueue *opQueue = [[SAOperationQueue alloc] init];
    opQueue.queue = concurrentQueue();
    opQueue.maximumOperationsLimit = 2;

    SAOperationBlock operation = ^(SAOperation *operation) { /* Just nothing! */ };

    SAOperation *operationA = [SAOperation new];
    SAOperation *operationB = [SAOperation new];
    SAOperation *operationC = [SAOperation new];
    SAOperation *operationD = [SAOperation new];

    operationA.operation = operation;
    operationB.operation = operation;
    operationC.operation = operation;
    operationD.operation = operation;

    [opQueue addOperation:operationA];
    [opQueue addOperation:operationB];
    [opQueue addOperation:operationC];
    [opQueue addOperation:operationD];

    // Wait while all operations are queued
    while(![[opQueue.runningOperations objectAtIndex:0] isExecuting]) {}
    while(![[opQueue.runningOperations objectAtIndex:1] isExecuting]) {}

    STAssertFalse(opQueue.isSuspended, nil);

    STAssertEquals((int)opQueue.pendingOperations.count, 2, nil);
    STAssertEquals((int)opQueue.runningOperations.count, 2, nil);

    [opQueue suspend];

    STAssertTrue(opQueue.isSuspended, nil);

    // Pending operations should have all been suspended
    for (SAOperation *operation in opQueue.pendingOperations) {
        STAssertTrue(operation.isSuspended, nil);
    }

    // Running operations should have not all been suspended - they should have isExecuting state
    for (SAOperation *operation in opQueue.runningOperations) {
        STAssertTrue(operation.isExecuting, nil);
    }

    [opQueue resume];

    STAssertFalse(opQueue.isSuspended, nil);

    // Pending operations should have all been resumed and become ready again
    for (SAOperation *operation in opQueue.pendingOperations) {
        STAssertTrue(operation.isReady, nil);
    }

    // Running operations should be executing - their states have not been changed
    for (SAOperation *operation in opQueue.runningOperations) {
        STAssertTrue(operation.isExecuting, nil);
    }
}

// Though SAOperationQueue does not suspend on-the-fly operations, it does resume them if they did suspend themselves before.
- (void)test_suspend_and_resume_one_of_operations_suspends_itself_on_ {
    SAOperationQueue *opQueue = [[SAOperationQueue alloc] init];
    opQueue.queue = concurrentQueue();
    opQueue.maximumOperationsLimit = 1;

    SAOperation *operationA = [SAOperation new];
    SAOperation *operationB = [SAOperation new];

    operationA.operation = ^(SAOperation *operation) { [operation suspend]; };
    operationB.operation = ^(SAOperation *operation) { /* Just nothing! */ };

    [opQueue addOperation:operationA];
    [opQueue addOperation:operationB];

    // Wait while all operations are queued
    while(![[opQueue.runningOperations objectAtIndex:0] isSuspended]) {}

    STAssertFalse(opQueue.isSuspended, nil);

    STAssertEquals((int)opQueue.pendingOperations.count, 1, nil);
    STAssertEquals((int)opQueue.runningOperations.count, 1, nil);

    [opQueue suspend];

    STAssertTrue(opQueue.isSuspended, nil);

    // Pending operation B should have been suspended by opQueue
    STAssertTrue(operationB.isSuspended, nil);

    // Running operation A should have been suspended by itself
    STAssertTrue(operationA.isSuspended, nil);

    [opQueue resume];

    STAssertFalse(opQueue.isSuspended, nil);

    // Pending operation B should have all been resumed and become ready again
    STAssertTrue(operationB.isReady, nil);


    // Running operation A should again have made itself suspended since it was rerun after opQueue had been resumed
    STAssertTrue(operationA.isSuspended, nil);
}

- (void)test_aggressive_LIFO {
    __block BOOL flag = NO;
    
    SAOperationQueue *operationQueue = [SAOperationQueue new];

    operationQueue.queueType = SAOperationQueueAggressiveLIFO;
    operationQueue.maximumOperationsLimit = 1;
    operationQueue.queue = serialQueue();
    
    operation(operationQueue, ^(SAOperation *operation) {
        // Nothing intentionally - operation will never finish itself and will stay in runningOperations
    });

    operation(operationQueue, ^(SAOperation *operation) {
        // Nothing intentionally - operation will never be run
        // Because it will be replaced by the following operation
        raiseShouldNotReachHere();
    }, ^{}, ^{
        flag = YES;
    });

    operation(operationQueue, ^(SAOperation *operation) {
        raiseShouldNotReachHere();
    }, ^{
    }, ^{
    });

    while(flag == NO);

    STAssertTrue(flag, nil);
    STAssertEquals((int)operationQueue.pendingOperations.count, 1, nil);
}


@end