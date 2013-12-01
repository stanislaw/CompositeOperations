
#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "COCompositeOperation.h"
#import "COQueues.h"
#import "COOperation_Private.h"
#import "COCompositeOperation_Private.h"

#import "COOperationQueue.h"

SPEC_BEGIN(COCompositeOperationConcurrentSpec)

describe(@"", ^{
    it(@"", ^{
        __block BOOL isFinishedFirst = NO;
        __block BOOL isFinishedSecond = NO;

        __block BOOL compositeConcurrentOperationHaveAlreadyBeenSuspended = NO;

        COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

        COSetDefaultQueue(concurrentQueue());

        [compositeOperation run:^(COCompositeOperation *compositeOperation) {
            [compositeOperation operationInQueue:serialQueue() withBlock:^(COOperation *operation) {
                [operation finish];

                [[theValue(operation.isFinished) should] beYes];
            }];

            [compositeOperation operationInQueue:serialQueue() withBlock:^(COOperation *operation) {
                [[theValue(compositeOperation.isFinished) should] beNo];

                // It should both times be serialQueue()
                BOOL queuesAreEqual = (currentQueue() == serialQueue());
                [[theValue(queuesAreEqual) should] beYes];

                // First time it will just run out without finish or cancel
                // And on the second it will actually finish itself
                if (compositeConcurrentOperationHaveAlreadyBeenSuspended == NO) {
                    [compositeOperation suspend];

                    isFinishedFirst = YES;
                } else {
                    [operation finish];
                }
            }];
        } completionHandler:^{
            isFinishedSecond = YES;
        } cancellationHandler:nil];

        while (isFinishedFirst == NO);

        compositeConcurrentOperationHaveAlreadyBeenSuspended = YES;
        [compositeOperation resume];
        
        while (isFinishedSecond == NO) {}

        [[theValue(compositeOperation.isFinished) should] beYes];
    });

    it(@"", ^{
        __block BOOL isFinished = NO;

        NSMutableArray *countArr = [NSMutableArray array];

        __block NSMutableString *accResult = [NSMutableString string];

        COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];;

        [compositeOperation run:^(COCompositeOperation *compositeOperation) {
            for (int i = 1; i <= 10; i++) {
                [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *tao) {
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

        while (isFinished == NO);

        [[theValue(countArr.count) should] equal:@(10)];

        NSLog(@"%s: accResult is: %@", __PRETTY_FUNCTION__, accResult);
    });

    it(@"Ensures that -[COOperation cancel] of suboperation cancels all operations in a composite concurrent operation", ^{
        __block BOOL isFinished = NO;

        COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

        [compositeOperation run:^(COCompositeOperation *compositeOperation) {
            [compositeOperation operationInQueue:serialQueue() withBlock:^(COOperation *o) {
                // Intentionally unfinished operation
            }];

            [compositeOperation operationInQueue:serialQueue() withBlock:^(COOperation *operation) {
                [[theValue(operation.isCancelled) should] beNo];

                @synchronized(compositeOperation) {
                    for (COOperation *operation in compositeOperation.operations) {
                        [[theValue(operation.isCancelled) should] beNo];
                        [[theValue(operation.isFinished) should] beNo];
                    }
                }

                [operation cancel];

                @synchronized(compositeOperation) {
                    for (COOperation *operation in compositeOperation.operations) {
                        [[theValue(operation.isCancelled) should] beYes];
                        [[theValue(operation.isFinished) should] beNo];
                    }
                }
            }];

            [compositeOperation operationInQueue:serialQueue() withBlock:^(COOperation *o) {
                // Intentionally unfinished operation
            }];
        } completionHandler:^{
            NSLog(@"operations: %@", compositeOperation.operations);
            NSLog(@"self: %@", compositeOperation);
            NSLog(@"Call stack: %@", [NSThread callStackSymbols]);
            
            raiseShouldNotReachHere();
        } cancellationHandler:^(COCompositeOperation *compositeOperation) {
            for (COOperation *operation in compositeOperation.operations) {
                [[theValue(operation.isCancelled) should] beYes];
            }

            isFinished = YES;
        }];

        while (isFinished == NO);
    });

    it(@"Ensures that if cancellationHandler is defined, -[COOperation cancel] of suboperation cancels suboperations, NOT cancels composite concurrent operation automatically and runs a cancellation handler, so it could be decided what to do with a composite concurrent operation.", ^{
        __block BOOL isFinished = NO;

        COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

        [compositeOperation run:^(COCompositeOperation *to) {
            [compositeOperation operationInQueue:serialQueue() withBlock:^(COOperation *o) {
                [o cancel];
            }];
        } completionHandler:^{
            raiseShouldNotReachHere();
        } cancellationHandler:^(COCompositeOperation *compositeOperation) {
            [[theValue(compositeOperation.isExecuting) should] beYes]; // cancellation handler is provided
            [[theValue(compositeOperation.isCancelled) should] beNo]; // so the composite operation is not cancelled automatically

            [compositeOperation cancel];

            [[theValue(compositeOperation.isExecuting) should] beNo];
            [[theValue(compositeOperation.isCancelled) should] beYes];

            for (COOperation *operation in compositeOperation.operations) {
                [[theValue(operation.isCancelled) should] beYes];
            }

            isFinished = YES;
        }];

        while (isFinished == NO);
    });

    it(@"", ^{
        int N = 10;

        __block BOOL isFinished = NO;
        NSMutableArray *countArr = [NSMutableArray array];

        COCompositeOperation *to = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

        [to run:^(COCompositeOperation *to) {
            [to operationInQueue:concurrentQueue() withBlock:^(COOperation *tao) {
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
        
        [[theValue(countArr.count) should] equal:@(N)];
    });

    describe(@"!OS_OBJECT_USE_OBJC", ^{
#if !OS_OBJECT_USE_OBJC
        it(@"Ensures that -[COCompositeOperation cancel] does not run and remove completionBlocks of suboperations ('soft cancel') when cancellationHandler is provided.", ^{
            __block BOOL isFinished = NO;

            COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

            [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                [compositeOperation operationWithBlock:^(COOperation *o) {
                    [o cancel];
                }];
            } completionHandler:^{
                raiseShouldNotReachHere();
            } cancellationHandler:^(COCompositeOperation *compositeOperation) {
                for (COOperation *operation in compositeOperation.operations) {
                    [[operation.completionBlock shouldNot] beNil];
                }
                
                isFinished = YES;
            }];
            
            while (!isFinished);

        });

        it(@"Ensures that -[COCompositeOperation cancel] DOES run and remove completionBlocks of suboperations ('soft cancel') when cancellationHandler is not provided.", ^{
            __block BOOL isFinished = NO;

            COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

            [compositeOperation run:^(COCompositeOperation *to) {
                [to operationWithBlock:^(COOperation *o) {
                    [o cancel];

                    isFinished = YES;
                }];
            } completionHandler:^{
                raiseShouldNotReachHere();
            } cancellationHandler:nil];

            while (isFinished == NO);
            
            for (COOperation *operation in compositeOperation.operations) {
                [[operation.completionBlock should] beNil];
            }
        });
#endif
    });

    describe(@"Suspend / Resume", ^{
        it(@"Ensures that -[COCompositeOperation resume] reruns left suspended operation if composite serial operation was suspended in the body of successful previous sub-operation", ^{
            int N = 1;

            for(int i = 1; i <= N; i++) {
                __block BOOL isFinished = NO;

                __block BOOL compositeConcurrentOperationHaveAlreadyBeenSuspended = NO;

                COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

                [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                    [compositeOperation operationInQueue:serialQueue() withBlock:^(COOperation *operation) {
                        [operation finish];

                        [[theValue(compositeOperation.isFinished) should] beNo];
                        [[theValue(operation.isFinished) should] beYes];
                    }];

                    [compositeOperation operationInQueue:serialQueue() withBlock:^(COOperation *operation) {

                        [[theValue(compositeOperation.isFinished) should] beNo];

                        // First time it will just run out without finish or cancel
                        // And on the second it will actually finish itself
                        if (compositeConcurrentOperationHaveAlreadyBeenSuspended == NO) {
                            [compositeOperation suspend];

                            [[theValue(operation.isSuspended) should] beYes];
                            isFinished = YES;
                        } else {
                            [[theValue(operation.isExecuting) should] beYes]; // The second time operation is run - it was resumed

                            [operation finish];
                        }
                    }];
                } completionHandler:^{
                    isFinished = YES;
                } cancellationHandler:nil];

                while (isFinished == NO);
                [[theValue(compositeOperation.isFinished) should] beNo];

                isFinished = NO;
                
                [[theValue(compositeOperation.isFinished) should] beNo];

                compositeConcurrentOperationHaveAlreadyBeenSuspended = YES;
                [compositeOperation resume];
                
                while (isFinished == NO) {};
                
                [[theValue(compositeOperation.isFinished) should] beYes];
            }

        });
    });
});

SPEC_END

//
//- (void)test_COCompositeOperationConcurrent_in_operation_queue {
//    __block BOOL isFinished = NO;
//    NSMutableArray *countArr = [NSMutableArray array];
//
//    COOperationQueue *opQueue = [[COOperationQueue alloc] init];
//
//    opQueue.queue = concurrentQueue();
//
//    COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];
//    compositeOperation.operationQueue = opQueue;
//
//    STAssertEquals((int)opQueue.pendingOperations.count, 0, nil);
//    STAssertEquals((int)opQueue.runningOperations.count, 0, nil);
//    
//    [compositeOperation run:^(COCompositeOperation *compositeOperation) {
//        STAssertEquals((int)opQueue.pendingOperations.count, 0, nil);
//        STAssertEquals((int)opQueue.runningOperations.count, 1, nil);
//
//        [compositeOperation operationWithBlock:^(COOperation *tao) {
//            @synchronized(countArr) {
//                [countArr addObject:@1];
//            }
//            [tao finish];
//        }];
//        
//        [compositeOperation operationWithBlock:^(COOperation *tao) {
//            @synchronized(countArr) {
//                [countArr addObject:@1];
//            }
//            [tao finish];
//        }];
//        
//        [compositeOperation operationWithBlock:^(COOperation *tao) {
//            @synchronized(countArr) {
//                [countArr addObject:@1];
//            }
//            [tao finish];
//        }];
//    } completionHandler:^{
//        isFinished = YES;
//        STAssertEquals((int)opQueue.pendingOperations.count, 0, nil);
//    } cancellationHandler:nil];
//    
//    while (isFinished == NO);
//    STAssertEquals((int)countArr.count, 3, @"Expected count to be equal 3");
//
//    while(opQueue.runningOperations.count > 0);
//
//    STAssertTrue(opQueue.runningOperations.count == 0, nil);
//}
//

//- (void) test_COCompositeOperationConcurrent_with_defaultQueue_set {
//    COSetDefaultQueue(concurrentQueue());
//    NSMutableArray *countArr = [NSMutableArray array];
//    __block BOOL isFinished = NO;
//    __block NSMutableString *accResult = [NSMutableString string];
//
//    COCompositeOperation *to = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];
//
//    [to run:^(COCompositeOperation *to) {
//        [to operationWithBlock:^(COOperation *tao) {
//            @synchronized(countArr) {
//                [countArr addObject:@1];
//            }
//            [accResult appendString:@"1"];
//            [tao finish];
//        }];
//        [to operationWithBlock:^(COOperation *tao) {
//            @synchronized(countArr) {
//                [countArr addObject:@1];
//            }
//            [accResult appendString:@"2"];
//            [tao finish];
//        }];
//        [to operationWithBlock:^(COOperation *tao) {
//            @synchronized(countArr) {
//                [countArr addObject:@1];
//            }
//            [accResult appendString:@"3"];
//            [tao finish];
//        }];
//    } completionHandler:^{
//        isFinished = YES;
//    } cancellationHandler:nil];
//
//    while (!isFinished);
//
//    STAssertEquals((int)countArr.count, 3, @"Expected count to be equal 3");
//    COSetDefaultQueue(nil);
//    NSLog(@"%s: accResult is: %@", __PRETTY_FUNCTION__, accResult);
//}
//

//
//#pragma mark
//#pragma mark reRun / awake
//
//// Ensures that -[COCompositeOperation(Concurrent) awake] awakes(i.e. reruns) all unfinished operations.
//
//- (void)test_COCompositeOperationConcurrent_awake {
//    COSetDefaultQueue(serialQueue());
//    
//    NSMutableArray *regArray = [NSMutableArray new];
//
//    __block BOOL blockFlag = NO;
//    __block NSNumber *secondOperationRunTimes = @(0);
//
//    COCompositeOperation *tOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];
//
//    [tOperation run:^(COCompositeOperation *co) {
//        [co operationWithBlock:^(COOperation *o) {
//            [regArray addObject:@"1"];
//            [o finish];
//        }];
//
//        [co operationWithBlock:^(COOperation *operation) {
//            STAssertTrue(tOperation.isExecuting, nil);
//
//            secondOperationRunTimes = @(secondOperationRunTimes.intValue + 1);
//
//            if ([secondOperationRunTimes isEqualToNumber:@(1)]) {
//                [regArray addObject:@"2"];
//                [operation cancel];
//            } else {
//                STAssertTrue(tOperation.isExecuting, nil);
//
//                [regArray addObject:@"3"];
//                [operation finish];
//            }
//        }];
//    } completionHandler:^{
//        STAssertTrue(tOperation.isFinished, nil);
//
//        STAssertTrue([regArray containsObject:@"1"], nil);
//        STAssertTrue([regArray containsObject:@"2"], nil);
//        STAssertTrue([regArray containsObject:@"3"], nil);
//
//        blockFlag = YES;
//    } cancellationHandler:^(COCompositeOperation *to) {
//        STAssertTrue([regArray containsObject:@"1"], nil);
//        STAssertTrue([regArray containsObject:@"2"], nil);
//        STAssertFalse([regArray containsObject:@"3"], nil);
//
//        STAssertTrue(tOperation.isExecuting, nil);
//
//        blockFlag = YES;
//    }];
//
//    while(blockFlag == NO);
//    
//    blockFlag = NO;
//    
//    [tOperation awake];
//    
//    while(blockFlag == NO){}
//
//    STAssertTrue(regArray.count == 3, nil);
//}
//
//// Ensures that -[COCompositeOperationConcurrent awake] HAS effect on executing operations
//- (void)test_COCompositeOperationConcurrent_awake_has_effect_on_executing_operations {
//    __block BOOL blockFlag = NO;
//    
//    COCompositeOperation *intentionallyUnfinishableTOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];
//
//    intentionallyUnfinishableTOperation.operation = ^(COCompositeOperation *co) {
//        [co operationWithBlock:^(COOperation *operation) {
//            [operation finish];
//            blockFlag = YES;
//        }];
//    };
//
//    intentionallyUnfinishableTOperation.state = COOperationStateExecuting;
//    STAssertTrue(intentionallyUnfinishableTOperation.isExecuting, nil);
//    
//    [intentionallyUnfinishableTOperation awake];
//
//    while(blockFlag == NO) {};
//
//    STAssertTrue(intentionallyUnfinishableTOperation.isFinished, nil);
//}
//
//// Ensures that -[COCompositeOperation[Concurrent] awake] has no effect on finished operations
//- (void)test_COCompositeOperationConcurrent_awake_has_no_effect_on_finished_operations {
//    COCompositeOperation *intentionallyUnfinishableTOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];
//
//    intentionallyUnfinishableTOperation.operation = ^(COCompositeOperation *co) {
//        [co operationWithBlock:^(COOperation *operation) {
//            raiseShouldNotReachHere();
//        }];
//    };
//
//    STAssertTrue(intentionallyUnfinishableTOperation.isReady, nil);
//    [intentionallyUnfinishableTOperation finish];
//
//    STAssertTrue(intentionallyUnfinishableTOperation.isFinished, nil);
//    [intentionallyUnfinishableTOperation awake];
//    STAssertTrue(intentionallyUnfinishableTOperation.isFinished, nil);
//}
//
//// Ensures that -[COCompositeOperation[Concurrent] awake] has no effect on cancelled operations
//- (void)test_COCompositeOperationConcurrent_awake_has_no_effect_on_cancelled_operations {
//    COCompositeOperation *intentionallyUnfinishableTOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];
//
//    intentionallyUnfinishableTOperation.operation = ^(COCompositeOperation *co) {
//        [co operationWithBlock:^(COOperation *operation) {
//            raiseShouldNotReachHere();
//        }];
//    };
//
//    STAssertTrue(intentionallyUnfinishableTOperation.isReady, nil);
//    [intentionallyUnfinishableTOperation cancel];
//    
//    STAssertTrue(intentionallyUnfinishableTOperation.isCancelled, nil);
//
//    [intentionallyUnfinishableTOperation awake];
//
//    STAssertTrue(intentionallyUnfinishableTOperation.isCancelled, nil);
//}
//
//@end
