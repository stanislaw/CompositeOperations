//
//  CascadeOperationsTests.m
//  CompositeOperationsTests
//
//  Created by Stanislaw Pankevich on 10/20/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "SATransactionalOperation.h"
#import "SAQueues.h"

@interface TransactionalOperationsTests : SenTestCase
@end

@implementation TransactionalOperationsTests

// Ensures that -[SAOperation cancel] of suboperation cancels all operations in a transaction
- (void) testTransactionalOperation_cancel {
    __block BOOL isFinished = NO;

    SATransactionalOperation *to = [SATransactionalOperation new];

    [to run:^(SATransactionalOperation *to) {
        [to operationInQueue:serialQueue() operation:^(SAOperation *o) {
            // Intentionally unfinished operation
        }];

        [to operationInQueue:serialQueue() operation:^(SAOperation *o) {
            STAssertFalse(o.isCancelled, nil);

            @synchronized(to) {
                for (SAOperation *operation in to.operations) {
                    STAssertFalse(operation.isFinished, nil);
                    STAssertFalse(operation.isCancelled, nil);
                }
            }

            [o cancel];

            @synchronized(to) {
                for (SAOperation *operation in to.operations) {
                    STAssertFalse(operation.isFinished, nil);
                    STAssertTrue(operation.isCancelled, nil);
                }
            }
        }];
        
        [to operationInQueue:serialQueue() operation:^(SAOperation *o) {
            // Intentionally unfinished operation
        }];
    } completionHandler:^{
        NSLog(@"operations: %@", to.operations);
        NSLog(@"self: %@", to);
        
        NSLog(@"Call stack: %@", [NSThread callStackSymbols]);
        raiseShouldNotReachHere();
    } cancellationHandler:^(SATransactionalOperation *to) {
        isFinished = YES;
    }];

    while (!isFinished);

    for (SAOperation *operation in to.operations) {
        NSString *errMessage = [NSString stringWithFormat:@"Expected all operations to be cancelled after cancelling third sub-operation: %@", operation];
        STAssertTrue(operation.isCancelled, errMessage);
    }
}

// Ensures that if cancellationHandler is defined, -[SAOperation cancel] of suboperation cancels suboperations, NOT cancels transaction automatically and runs a cancellation handler, so it could be decided what to do with a transaction.
- (void) testTransactionalOperation_cancel_cancellation_handler {
    __block BOOL isFinished = NO;

    SATransactionalOperation *to = [SATransactionalOperation new];

    [to run:^(SATransactionalOperation *to) {
        [to operationInQueue:serialQueue() operation:^(SAOperation *o) {
            [o cancel];
        }];
    } completionHandler:^{
        raiseShouldNotReachHere();
    } cancellationHandler:^(SATransactionalOperation *to) {
        STAssertTrue(to.isExecuting, nil);  // cancellation handler is provided
        STAssertFalse(to.isCancelled, nil); // so the transaction is not cancelled automatically

        [to cancel];

        STAssertFalse(to.isExecuting, nil);
        STAssertTrue(to.isCancelled, nil);
        
        isFinished = YES;
    }];

    while (!isFinished);

    for (SAOperation *operation in to.operations) {
        STAssertTrue(operation.isCancelled, @"Expected all operations to be cancelled after cancelling third sub-operation");
    }
}

#pragma mark
#pragma mark SATransactionalOperation: assigns NSOperation's operationBlocks to its suboperations.

#if !OS_OBJECT_USE_OBJC

// Ensures that -[SATransactionalOperation cancel] does not run and remove completionBlocks of suboperations ("soft cancel") when cancellationHandler is provided.
- (void)test_transactionalOperation_cancel_does_not_runs_suboperations_completionBlocks_if_cancellation_handler_is_provided {
    __block BOOL isFinished = NO;

    SATransactionalOperation *tOperation = [SATransactionalOperation new];

    [tOperation run:^(SATransactionalOperation *to) {
        [to operation:^(SAOperation *o) {
            [o cancel];
        }];
    } completionHandler:^{
        raiseShouldNotReachHere();
    } cancellationHandler:^(SATransactionalOperation *cascadeOperation) {
        for (SAOperation *operation in cascadeOperation.operations) {
            STAssertNotNil(operation.completionBlock, nil);
        }

        isFinished = YES;
    }];

    while (!isFinished);
}

// Ensures that -[SACascadeOperation cancel] DOES run and remove completionBlocks of suboperations ("soft cancel") when cancellationHandler is not provided.
- (void)test_transactionalOperation_cancel_does_run_suboperations_completionBlocks_if_cancellation_handler_is_provided {
    __block BOOL isFinished = NO;

    SATransactionalOperation *tOperation = [SATransactionalOperation new];

    [tOperation run:^(SATransactionalOperation *to) {
        [to operation:^(SAOperation *o) {
            [o cancel];

            isFinished = YES;
        }];
    } completionHandler:^{
        raiseShouldNotReachHere();
    } cancellationHandler:nil];

    while (!isFinished);

    for (SAOperation *operation in tOperation.operations) {
        STAssertNotNil(operation.completionBlock, nil);
    }
}

#endif

#pragma mark

- (void) testTransactionalOperation_reRun {
    int N = 10;
    
    __block BOOL isFinished = NO;
    NSMutableArray *countArr = [NSMutableArray array];

    SATransactionalOperation *to = [SATransactionalOperation new];

    [to run:^(SATransactionalOperation *to) {
        [to operationInQueue:concurrentQueue() operation:^(SAOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            
            if (countArr.count < N)
                [tao reRun];
            else
                [tao finish];
        }];
    } completionHandler:^{
        isFinished = YES;
    } cancellationHandler:nil];

    while (!isFinished);

    STAssertEquals((int)countArr.count, N, @"Expected count to be equal N");
}

- (void)test_transactionalOperation_in_operation_queue {
    __block BOOL isFinished = NO;
    NSMutableArray *countArr = [NSMutableArray array];

    SAOperationQueue *opQueue = [SAOperationQueue new];
    opQueue.queue = concurrentQueue();

    SATransactionalOperation *to = [SATransactionalOperation new];
    to.operationQueue = opQueue;

    STAssertEquals((int)opQueue.pendingOperations.count, 0, @"Expected to be 0 pending operations before transactional operation");
    STAssertEquals((int)opQueue.runningOperations.count, 0, @"Expected to be 0 running operations before transactional operation");
    
    [to run:^(SATransactionalOperation *to) {
        STAssertEquals((int)opQueue.pendingOperations.count, 0, nil);
        STAssertEquals((int)opQueue.runningOperations.count, 1, nil);

        [to operation:^(SAOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
        
        [to operation:^(SAOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
        
        [to operation:^(SAOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
    } completionHandler:^{
        isFinished = YES;
        STAssertEquals((int)opQueue.pendingOperations.count, 0, @"Expected to be 0 pending operations when running inside completion handler");
    } cancellationHandler:nil];
    
    while (!isFinished);
    STAssertEquals((int)countArr.count, 3, @"Expected count to be equal 3");

    while(opQueue.runningOperations.count > 0);

    STAssertEquals((int)opQueue.runningOperations.count, 0, @"Expected to be 0 running operations before transactional operation");
}



- (void) test_transactionalOperation_operationInQueue {
    __block BOOL isFinished = NO;
    NSMutableArray *countArr = [NSMutableArray array];
    __block NSMutableString *accResult = [NSMutableString string];
    __block NSUInteger operationsScheduled;

    SATransactionalOperation *to = [SATransactionalOperation new];

    [to run:^(SATransactionalOperation *to) {
        for (int i=1; i<=10;i++) {
            [to operationInQueue:concurrentQueue() operation:^(SAOperation *tao) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                NSString *ind = [NSString stringWithFormat:@"%d", i];
                [accResult appendString:ind];
                [tao finish];
            }];
        }
        operationsScheduled = to.operations.count;
    } completionHandler:^{
        isFinished = YES;
    } cancellationHandler:nil];

    while (!isFinished);

    STAssertEquals((int)countArr.count, 10, @"Expected count to be equal 10");
    STAssertEquals((int)operationsScheduled, 10, @"Expected 10 operations to be scheduled");
    NSLog(@"%s: accResult is: %@", __PRETTY_FUNCTION__, accResult);
}

- (void) test_transactionalOperation_with_defaultQueue_set {
    SASetDefaultQueue(concurrentQueue());
    NSMutableArray *countArr = [NSMutableArray array];
    __block BOOL isFinished = NO;
    __block NSMutableString *accResult = [NSMutableString string];

    SATransactionalOperation *to = [SATransactionalOperation new];

    [to run:^(SATransactionalOperation *to) {
        [to operation:^(SAOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [accResult appendString:@"1"];
            [tao finish];
        }];
        [to operation:^(SAOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [accResult appendString:@"2"];
            [tao finish];
        }];
        [to operation:^(SAOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [accResult appendString:@"3"];
            [tao finish];
        }];
    } completionHandler:^{
        isFinished = YES;
    } cancellationHandler:nil];

    while (!isFinished);

    STAssertEquals((int)countArr.count, 3, @"Expected count to be equal 3");
    SASetDefaultQueue(nil);
    NSLog(@"%s: accResult is: %@", __PRETTY_FUNCTION__, accResult);
}

#pragma mark
#pragma mark Resume / suspend

// Ensures that -[SATransactionalOperation resume] reruns left suspended operation if cascade operation was suspended in the body of successful previous sub-operation

- (void)test_transactionalOperation_resume_runs_all_suspended_operations_if_cascade_operation_was_suspended_in_th_body_of_successful_previous_sub_operation {
    int N = 10;
    
    for(int i = 1; i <= N; i++) {
        __block BOOL isFinished = NO;
        
        __block BOOL transactionHaveAlreadyBeenSuspended = NO;
        
        SATransactionalOperation *tOperation = [SATransactionalOperation new];

        [tOperation run:^(SATransactionalOperation *transaction) {
            [transaction operationInQueue:serialQueue() operation:^(SAOperation *operation) {
                [operation finish];
                
                STAssertTrue(operation.isFinished, nil);
            }];

            [transaction operationInQueue:serialQueue() operation:^(SAOperation *operation) {
                // First time it will just run out without finish or cancel
                // And on the second it will actually finish itself
                if (transactionHaveAlreadyBeenSuspended == NO) {
                    [transaction suspend]; // transaction cascade and all suboperations

                    STAssertTrue(operation.isSuspended, nil); // The first time operation is run - it is suspended by first operation
                } else {
                    STAssertTrue(operation.isExecuting, nil); // The second time operation is run - it was resumed

                    [operation finish];
                }
                
                isFinished = YES;
            }];
        } completionHandler:nil cancellationHandler:nil];

        while (!isFinished || !tOperation.isSuspended);

        isFinished = NO;

        transactionHaveAlreadyBeenSuspended = YES;
        [tOperation resume];

        while (!isFinished || !tOperation.isFinished) {}
        STAssertTrue(tOperation.isFinished, nil);
    }
}

- (void)test_transactionalOperation_resume_runs_all_suspended_operations_in_the_same_queues_they_were_originally_scheduled {
    __block BOOL isFinished = NO;

    __block BOOL transactionHaveAlreadyBeenSuspended = NO;

    SATransactionalOperation *tOperation = [SATransactionalOperation new];

    SASetDefaultQueue(concurrentQueue());
    
    [tOperation run:^(SATransactionalOperation *transaction) {
        [transaction operationInQueue:serialQueue() operation:^(SAOperation *operation) {
            [operation finish];

            STAssertTrue(operation.isFinished, nil);
        }];

        [transaction operationInQueue:serialQueue() operation:^(SAOperation *operation) {

            // It should both times be serialQueue() 
            STAssertTrue(dispatch_get_current_queue() == serialQueue(), nil);
            
            // First time it will just run out without finish or cancel
            // And on the second it will actually finish itself
            if (transactionHaveAlreadyBeenSuspended == NO) {
                [transaction suspend]; // transaction cascade and all suboperations
            } else {
                [operation finish];
            }

            isFinished = YES;
        }];
    } completionHandler:nil cancellationHandler:nil];

    while (!isFinished || !tOperation.isSuspended);

    isFinished = NO;

    transactionHaveAlreadyBeenSuspended = YES;
    [tOperation resume];

    while (!isFinished || !tOperation.isFinished) {}
    STAssertTrue(tOperation.isFinished, nil);
}

#pragma mark
#pragma mark reRun / awake

// Ensures that -[TransactionalOperation awake] awakes(i.e. reruns) all unfinished operations.

- (void)test_transactionalOperation_awake {
    SASetDefaultQueue(serialQueue());
    
    NSMutableArray *regArray = [NSMutableArray new];

    __block BOOL blockFlag = NO;
    __block NSNumber *secondOperationRunTimes = @(0);

    SATransactionalOperation *tOperation = [SATransactionalOperation new];

    [tOperation run:^(SATransactionalOperation *co) {
        [co operation:^(SAOperation *o) {
            [regArray addObject:@"1"];
            [o finish];
        }];

        [co operation:^(SAOperation *operation) {
            STAssertTrue(tOperation.isExecuting, nil);

            secondOperationRunTimes = @(secondOperationRunTimes.intValue + 1);

            if ([secondOperationRunTimes isEqualToNumber:@(1)]) {
                [regArray addObject:@"2"];
                [operation cancel];
            } else {
                STAssertTrue(tOperation.isExecuting, nil);

                [regArray addObject:@"3"];
                [operation finish];
            }
        }];
    } completionHandler:^{
        STAssertTrue(tOperation.isFinished, nil);

        STAssertTrue([regArray containsObject:@"1"], nil);
        STAssertTrue([regArray containsObject:@"2"], nil);
        STAssertTrue([regArray containsObject:@"3"], nil);

        blockFlag = YES;
    } cancellationHandler:^(SATransactionalOperation *to) {
        STAssertTrue([regArray containsObject:@"1"], nil);
        STAssertTrue([regArray containsObject:@"2"], nil);
        STAssertFalse([regArray containsObject:@"3"], nil);

        STAssertTrue(tOperation.isExecuting, nil);

        blockFlag = YES;
    }];

    while(blockFlag == NO);
    
    blockFlag = NO;
    
    [tOperation awake];
    
    while(blockFlag == NO){}
}

// Ensures that -[TransactionalOperation awake] HAS effect on executing operations
- (void)test_transactionalOperation_awake_has_effect_on_executing_operations {
    __block BOOL blockFlag = NO;
    
    SATransactionalOperation *intentionallyUnfinishableTOperation = [SATransactionalOperation new];

    intentionallyUnfinishableTOperation.operation = ^(SATransactionalOperation *co) {
        [co operation:^(SAOperation *operation) {
            [operation finish];
            blockFlag = YES;
        }];
    };

    intentionallyUnfinishableTOperation.state = SAOperationExecutingState;
    STAssertTrue(intentionallyUnfinishableTOperation.isExecuting, nil);
    
    [intentionallyUnfinishableTOperation awake];

    while(blockFlag == NO) {};

    STAssertTrue(intentionallyUnfinishableTOperation.isFinished, nil);
}

// Ensures that -[TransactionalOperation awake] has no effect on finished operations
- (void)test_transactionalOperation_awake_has_no_effect_on_finished_operations {
    SATransactionalOperation *intentionallyUnfinishableTOperation = [SATransactionalOperation new];

    intentionallyUnfinishableTOperation.operation = ^(SATransactionalOperation *co) {
        [co operation:^(SAOperation *operation) {
            raiseShouldNotReachHere();
        }];
    };

    STAssertTrue(intentionallyUnfinishableTOperation.isReady, nil);
    [intentionallyUnfinishableTOperation finish];

    STAssertTrue(intentionallyUnfinishableTOperation.isFinished, nil);
    [intentionallyUnfinishableTOperation awake];
    STAssertTrue(intentionallyUnfinishableTOperation.isFinished, nil);
}

// Ensures that -[TransactionalOperation awake] has no effect on cancelled operations
- (void)test_transactionalOperation_awake_has_no_effect_on_cancelled_operations {
    SATransactionalOperation *intentionallyUnfinishableTOperation = [SATransactionalOperation new];

    intentionallyUnfinishableTOperation.operation = ^(SATransactionalOperation *co) {
        [co operation:^(SAOperation *operation) {
            raiseShouldNotReachHere();
        }];
    };

    STAssertTrue(intentionallyUnfinishableTOperation.isReady, nil);
    [intentionallyUnfinishableTOperation cancel];
    
    STAssertTrue(intentionallyUnfinishableTOperation.isCancelled, nil);

    [intentionallyUnfinishableTOperation awake];

    STAssertTrue(intentionallyUnfinishableTOperation.isCancelled, nil);
}

@end
