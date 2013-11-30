
#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "COCompositeOperation.h"
#import "COQueues.h"
#import "COOperation_Private.h"
#import "COOperationQueue.h"

@interface TransactionalOperationsTests : SenTestCase
@end

@implementation TransactionalOperationsTests

// Ensures that -[COOperation cancel] of suboperation cancels all operations in a transaction
- (void) testTransactionalOperation_cancel {
    __block BOOL isFinished = NO;

    COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

    [compositeOperation run:^(COCompositeOperation *compositeOperation) {
        [compositeOperation operationInQueue:serialQueue() operation:^(COOperation *o) {
            // Intentionally unfinished operation
        }];

        [compositeOperation operationInQueue:serialQueue() operation:^(COOperation *o) {
            STAssertFalse(o.isCancelled, nil);

            @synchronized(compositeOperation) {
                for (COOperation *operation in [compositeOperation.operations copy]) {
                    STAssertFalse(operation.isFinished, nil);
                    STAssertFalse(operation.isCancelled, nil);
                }
            }

            [o cancel];

            @synchronized(compositeOperation) {
                for (COOperation *operation in [compositeOperation.operations copy]) {
                    STAssertFalse(operation.isFinished, nil);
                    STAssertTrue(operation.isCancelled, nil);
                }
            }
        }];
        
        [compositeOperation operationInQueue:serialQueue() operation:^(COOperation *o) {
            // Intentionally unfinished operation
        }];
    } completionHandler:^{
        NSLog(@"operations: %@", compositeOperation.operations);
        NSLog(@"self: %@", compositeOperation);
        
        NSLog(@"Call stack: %@", [NSThread callStackSymbols]);
        raiseShouldNotReachHere();
    } cancellationHandler:^(COCompositeOperation *compositeOperation) {
        isFinished = YES;
    }];

    while (!isFinished);

    for (COOperation *operation in compositeOperation.operations) {
        NSString *errMessage = [NSString stringWithFormat:@"Expected all operations to be cancelled after cancelling third sub-operation: %@", operation];
        STAssertTrue(operation.isCancelled, errMessage);
    }
}

// Ensures that if cancellationHandler is defined, -[COOperation cancel] of suboperation cancels suboperations, NOT cancels transaction automatically and runs a cancellation handler, so it could be decided what to do with a transaction.
- (void) testTransactionalOperation_cancel_cancellation_handler {
    __block BOOL isFinished = NO;

    COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

    [compositeOperation run:^(COCompositeOperation *to) {
        [compositeOperation operationInQueue:serialQueue() operation:^(COOperation *o) {
            [o cancel];
        }];
    } completionHandler:^{
        raiseShouldNotReachHere();
    } cancellationHandler:^(COCompositeOperation *compositeOperation) {
        STAssertTrue(compositeOperation.isExecuting, nil);  // cancellation handler is provided
        STAssertFalse(compositeOperation.isCancelled, nil); // so the transaction is not cancelled automatically

        [compositeOperation cancel];

        STAssertFalse(compositeOperation.isExecuting, nil);
        STAssertTrue(compositeOperation.isCancelled, nil);
        
        isFinished = YES;
    }];

    while (!isFinished);

    for (COOperation *operation in compositeOperation.operations) {
        STAssertTrue(operation.isCancelled, @"Expected all operations to be cancelled after cancelling third sub-operation");
    }
}

#pragma mark
#pragma mark COCompositeOperation: assigns NSOperation's operationBlocks to its suboperations.

#if !OS_OBJECT_USE_OBJC

// Ensures that -[COCompositeOperation cancel] does not run and remove completionBlocks of suboperations ("soft cancel") when cancellationHandler is provided.
- (void)test_transactionalOperation_cancel_does_not_runs_suboperations_completionBlocks_if_cancellation_handler_is_provided {
    __block BOOL isFinished = NO;

    COCompositeOperation *tOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

    [tOperation run:^(COCompositeOperation *to) {
        [to operation:^(COOperation *o) {
            [o cancel];
        }];
    } completionHandler:^{
        raiseShouldNotReachHere();
    } cancellationHandler:^(COCompositeOperation *compositeOperation) {
        for (COOperation *operation in compositeOperation.operations) {
            STAssertNotNil(operation.completionBlock, nil);
        }

        isFinished = YES;
    }];

    while (!isFinished);
}

// Ensures that -[COCompositeOperation cancel] DOES run and remove completionBlocks of suboperations ("soft cancel") when cancellationHandler is not provided.
- (void)test_transactionalOperation_cancel_does_run_suboperations_completionBlocks_if_cancellation_handler_is_provided {
    __block BOOL isFinished = NO;

    COCompositeOperation *tOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

    [tOperation run:^(COCompositeOperation *to) {
        [to operation:^(COOperation *o) {
            [o cancel];

            isFinished = YES;
        }];
    } completionHandler:^{
        raiseShouldNotReachHere();
    } cancellationHandler:nil];

    while (!isFinished);

    for (COOperation *operation in tOperation.operations) {
        STAssertNotNil(operation.completionBlock, nil);
    }
}

#endif

#pragma mark

- (void) testTransactionalOperation_reRun {
    int N = 10;
    
    __block BOOL isFinished = NO;
    NSMutableArray *countArr = [NSMutableArray array];

    COCompositeOperation *to = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

    [to run:^(COCompositeOperation *to) {
        [to operationInQueue:concurrentQueue() operation:^(COOperation *tao) {
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

    COOperationQueue *opQueue = [[COOperationQueue alloc] init];

    opQueue.queue = concurrentQueue();

    COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];
    compositeOperation.operationQueue = opQueue;

    STAssertEquals((int)opQueue.pendingOperations.count, 0, @"Expected to be 0 pending operations before transactional operation");
    STAssertEquals((int)opQueue.runningOperations.count, 0, @"Expected to be 0 running operations before transactional operation");
    
    [compositeOperation run:^(COCompositeOperation *compositeOperation) {
        STAssertEquals((int)opQueue.pendingOperations.count, 0, nil);
        STAssertEquals((int)opQueue.runningOperations.count, 1, nil);

        [compositeOperation operation:^(COOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
        
        [compositeOperation operation:^(COOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
        
        [compositeOperation operation:^(COOperation *tao) {
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

    COCompositeOperation *to = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];;

    [to run:^(COCompositeOperation *to) {
        for (int i=1; i<=10;i++) {
            [to operationInQueue:concurrentQueue() operation:^(COOperation *tao) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                NSString *ind = [NSString stringWithFormat:@"%d", i];
                [accResult appendString:ind];
                [tao finish];
            }];
        }
    } completionHandler:^{
        isFinished = YES;
    } cancellationHandler:nil];

    while (!isFinished);

    STAssertEquals((int)countArr.count, 10, @"Expected count to be equal 10");
    NSLog(@"%s: accResult is: %@", __PRETTY_FUNCTION__, accResult);
}

- (void) test_transactionalOperation_with_defaultQueue_set {
    COSetDefaultQueue(concurrentQueue());
    NSMutableArray *countArr = [NSMutableArray array];
    __block BOOL isFinished = NO;
    __block NSMutableString *accResult = [NSMutableString string];

    COCompositeOperation *to = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

    [to run:^(COCompositeOperation *to) {
        [to operation:^(COOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [accResult appendString:@"1"];
            [tao finish];
        }];
        [to operation:^(COOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [accResult appendString:@"2"];
            [tao finish];
        }];
        [to operation:^(COOperation *tao) {
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
    COSetDefaultQueue(nil);
    NSLog(@"%s: accResult is: %@", __PRETTY_FUNCTION__, accResult);
}

#pragma mark
#pragma mark Resume / suspend

// Ensures that -[COCompositeOperation resume] reruns left suspended operation if cascade operation was suspended in the body of successful previous sub-operation

- (void)test_transactionalOperation_resume_runs_all_suspended_operations_if_cascade_operation_was_suspended_in_th_body_of_successful_previous_sub_operation {
    int N = 10;
    
    for(int i = 1; i <= N; i++) {
        __block BOOL isFinished = NO;
        
        __block BOOL transactionHaveAlreadyBeenSuspended = NO;
        
        COCompositeOperation *tOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

        [tOperation run:^(COCompositeOperation *transaction) {
            [transaction operationInQueue:serialQueue() operation:^(COOperation *operation) {
                [operation finish];
                
                STAssertTrue(operation.isFinished, nil);
            }];

            [transaction operationInQueue:serialQueue() operation:^(COOperation *operation) {
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

    COCompositeOperation *tOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

    COSetDefaultQueue(concurrentQueue());
    
    [tOperation run:^(COCompositeOperation *transaction) {
        [transaction operationInQueue:serialQueue() operation:^(COOperation *operation) {
            [operation finish];

            STAssertTrue(operation.isFinished, nil);
        }];

        [transaction operationInQueue:serialQueue() operation:^(COOperation *operation) {

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
    COSetDefaultQueue(serialQueue());
    
    NSMutableArray *regArray = [NSMutableArray new];

    __block BOOL blockFlag = NO;
    __block NSNumber *secondOperationRunTimes = @(0);

    COCompositeOperation *tOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

    [tOperation run:^(COCompositeOperation *co) {
        [co operation:^(COOperation *o) {
            [regArray addObject:@"1"];
            [o finish];
        }];

        [co operation:^(COOperation *operation) {
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
    } cancellationHandler:^(COCompositeOperation *to) {
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
    
    COCompositeOperation *intentionallyUnfinishableTOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

    intentionallyUnfinishableTOperation.operation = ^(COCompositeOperation *co) {
        [co operation:^(COOperation *operation) {
            [operation finish];
            blockFlag = YES;
        }];
    };

    intentionallyUnfinishableTOperation.state = COOperationStateExecuting;
    STAssertTrue(intentionallyUnfinishableTOperation.isExecuting, nil);
    
    [intentionallyUnfinishableTOperation awake];

    while(blockFlag == NO) {};

    STAssertTrue(intentionallyUnfinishableTOperation.isFinished, nil);
}

// Ensures that -[TransactionalOperation awake] has no effect on finished operations
- (void)test_transactionalOperation_awake_has_no_effect_on_finished_operations {
    COCompositeOperation *intentionallyUnfinishableTOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

    intentionallyUnfinishableTOperation.operation = ^(COCompositeOperation *co) {
        [co operation:^(COOperation *operation) {
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
    COCompositeOperation *intentionallyUnfinishableTOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

    intentionallyUnfinishableTOperation.operation = ^(COCompositeOperation *co) {
        [co operation:^(COOperation *operation) {
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
