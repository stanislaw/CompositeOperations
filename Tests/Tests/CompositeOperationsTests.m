
#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "CompositeOperations.h"
#import "COQueues.h"

@interface GlobalNamespacedHelpersTest : SenTestCase
@end

@implementation GlobalNamespacedHelpersTest

- (void)test_operation {
    __block BOOL oOver = NO;

    operation(^(COOperation *o) {
        oOver = YES;
        [o finish];
    });

    while (!oOver) {}

    STAssertTrue(oOver, @"Expected aoOver to be YES");
}

- (void)test_operation_in_queue {
    __block BOOL oOver = NO;

    operation(concurrentQueue(), ^(COOperation *o) {
        oOver = YES;
        [o finish];
    });

    while (!oOver) {}

    STAssertTrue(oOver, @"Expected aoOver to be YES");
}

- (void)test_operation_in_operation_queue {
    __block BOOL oOver = NO;
    
    COOperationQueue *opQueue = [COOperationQueue new];
    opQueue.queue = createQueue();

    STAssertEquals((int)opQueue.pendingOperations.count, 0, nil);
    STAssertEquals((int)opQueue.runningOperations.count, 0, nil);
    
    operation(opQueue, ^(COOperation *o) {
        STAssertEquals((int)opQueue.runningOperations.count, 1, nil);
        [o finish];
        oOver = YES;
    });

    while (!oOver) {}

    STAssertEquals((int)opQueue.runningOperations.count, 0, nil);

    STAssertTrue(oOver, @"Expected aoOver to be YES");
}

- (void)test_CompositeSerialOperation {
    __block int count = 0;
    __block BOOL isFinished = NO;
    __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

    compositeOperation(COCompositeOperationSerial, ^(COCompositeOperation *compositeOperation) {
        [compositeOperation operationWithBlock:^(COOperation *rao) {
            asynchronousJob(^{
                count = count + 1;

                STAssertFalse(firstJobIsDone, @"Expected firstJobIsDone to be NO");
                STAssertFalse(secondJobIsDone, @"Expected secondJobIsDone to be NO");
                STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

                STAssertEquals((int)count, 1, @"Expected count to be equal 1 inside the first operation");

                firstJobIsDone = YES;
                [rao finish];
            });
        }];

        [compositeOperation operationWithBlock:^(COOperation *rao) {
            asynchronousJob(^{
                count = count + 1;

                STAssertTrue(firstJobIsDone, @"Expected firstJobIsDone to be YES");
                STAssertFalse(secondJobIsDone, @"Expected secondJobIsDone to be NO");
                STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

                STAssertEquals((int)count, 2, @"Expected count to be equal 2 inside the second operation");

                secondJobIsDone = YES;

                [rao finish];
            });
        }];

        [compositeOperation operationWithBlock:^(COOperation *rao) {
            asynchronousJob(^{
                count = count + 1;

                STAssertTrue(firstJobIsDone, @"Expected firstJobIsDone to be YES");
                STAssertTrue(secondJobIsDone, @"Expected secondJobIsDone to be YES");
                STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

                STAssertEquals((int)count, 3, @"Expected count to be equal 3 inside the third operation");

                isFinished = YES;
                [rao finish];
            });
        }];
    }, nil, nil);
    
    while (!isFinished);

    STAssertEquals(count, 3, @"Expected count to be equal 3");
}

- (void)test_CompositeSerialOperation_operation {
    __block BOOL isFinished = NO;
    NSMutableArray *registry = [NSMutableArray array];

    COOperation *operation = [COOperation new];
    operation.operation = ^(COOperation *operation) {
        asynchronousJob(^{
            [registry addObject:@(1)];
            [operation finish];
        });
    };

    compositeOperation(COCompositeOperationSerial, ^(COCompositeOperation *compositeOperation) {
        [compositeOperation operation:[operation copy]];
        [compositeOperation operation:[operation copy]];
        [compositeOperation operation:[operation copy]];
    }, ^{
        isFinished = YES;
    }, ^(COCompositeOperation *compositeOperation){
        raiseShouldNotReachHere();
    });
    
    while (isFinished == NO);

    STAssertTrue(registry.count == 3, nil);
}

- (void)test_CompositeSerialOperation_compositeOperation {
    __block BOOL isFinished = NO;
    NSMutableArray *registry = [NSMutableArray array];

    COOperation *operation = [COOperation new];
    operation.operation = ^(COOperation *operation) {
        asynchronousJob(^{
            [registry addObject:@(1)];
            [operation finish];
        });
    };

    COCompositeOperation *innerCompositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

    innerCompositeOperation.operation = ^(COCompositeOperation *compositeOperation) {
        [compositeOperation operation:[operation copy]];
        [compositeOperation operation:[operation copy]];
        [compositeOperation operation:[operation copy]];
    };

    compositeOperation(COCompositeOperationSerial, ^(COCompositeOperation *mixedCompositeOperation) {
        [mixedCompositeOperation compositeOperation:innerCompositeOperation];
    }, ^{
        isFinished = YES;
    }, ^(COCompositeOperation *compositeOperation){
        raiseShouldNotReachHere();
    });

    while (isFinished == NO) {};

    STAssertTrue(registry.count == 3, nil);
}


- (void)test_compositeSerialOperation_Integration {
    NSMutableArray *countArr = [NSMutableArray array];
    __block BOOL isFinished = NO;
    __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

    __block NSMutableString *accResult = [NSMutableString string];

    compositeOperation(COCompositeOperationSerial, ^(COCompositeOperation *compositeOperation) {
        [compositeOperation operationWithBlock:^(COOperation *rao) {
            asynchronousJob(^{
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [accResult appendString:@"c1"];

                STAssertFalse(firstJobIsDone, @"Expected firstJobIsDone to be NO");
                STAssertFalse(secondJobIsDone, @"Expected secondJobIsDone to be NO");
                STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

                STAssertEquals((int)countArr.count, 1, @"Expected count to be equal 1 inside the first operation");

                firstJobIsDone = YES;
                [rao finish];
            });
        }];

        [compositeOperation operationWithBlock:^(COOperation *rao) {
            asynchronousJob(^{
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [accResult appendString:@"c2"];

                STAssertTrue(firstJobIsDone, @"Expected firstJobIsDone to be YES");
                STAssertFalse(secondJobIsDone, @"Expected secondJobIsDone to be NO");
                STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

                STAssertEquals((int)countArr.count, 2, @"Expected count to be equal 2 inside the second operation");

                secondJobIsDone = YES;

                [rao finish];
            });
        }];

        [compositeOperation operationWithBlock:^(COOperation *rao) {
            asynchronousJob(^{
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [accResult appendString:@"c3"];
                
                STAssertTrue(firstJobIsDone, @"Expected firstJobIsDone to be YES");
                STAssertTrue(secondJobIsDone, @"Expected secondJobIsDone to be YES");
                STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

                STAssertEquals((int)countArr.count, 3, @"Expected count to be equal 3 inside the third operation");

                [rao finish];
            });
        }];

        [compositeOperation compositeOperation:COCompositeOperationConcurrent withBlock:^(COCompositeOperation *to) {
            [to operationWithBlock:^(COOperation *tao) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [accResult appendString:@"t1"];
                [tao finish];
            }];

            [to operationWithBlock:^(COOperation *tao) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [accResult appendString:@"t2"];
                [tao finish];
            }];

            [to operationWithBlock:^(COOperation *tao) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [accResult appendString:@"t3"];
                [tao finish];
            }];
        }];

        [compositeOperation operationWithBlock:^(COOperation *cuo) {
            [cuo finish];
            isFinished = YES;
        }];
    }, nil, nil);
    
    while (!isFinished);

    STAssertEquals((int)countArr.count, 6, @"Expected count to be equal 6");
    NSLog(@"%s: accResult is: %@", __PRETTY_FUNCTION__, accResult);

}

- (void)test_compositeOperation_in_operation_queue {
    COOperationQueue *opQueue = [COOperationQueue new];
    opQueue.queue = concurrentQueue();
    
    __block int count = 0;
    __block BOOL isFinished = NO;

    compositeOperation(COCompositeOperationSerial, opQueue, ^(COCompositeOperation *compositeOperation) {
        [compositeOperation operationWithBlock:^(COOperation *cao) {
            count = count + 1;

            STAssertEquals((int)count, 1, @"Expected count to be equal 1 inside the first operation");

            [cao finish];
        }];

        [compositeOperation operationWithBlock:^(COOperation *cao) {
            count = count + 1;

            STAssertEquals((int)count, 2, @"Expected count to be equal 2 inside the second operation");

            [cao finish];
        }];

        [compositeOperation operationWithBlock:^(COOperation *cao) {
            count = count + 1;

            STAssertEquals((int)count, 3, @"Expected count to be equal 3 inside the third operation");

            [cao finish];
            isFinished = YES;
        }];
    }, nil, nil);

    while (!isFinished);
    
    STAssertEquals(count, 3, @"Expected count to be equal 3");
}

- (void)test_compositeConcurrentOperation {
    __block BOOL passedHandler = NO;
    
    NSMutableArray *countArr = [NSMutableArray array];
    NSMutableString *accResult = [NSMutableString string];

    COSetDefaultQueue(concurrentQueue());
    
    compositeOperation(COCompositeOperationConcurrent, ^(COCompositeOperation *compositeOperation) {
        for (int i = 1; i <= 30; i++) {
            [compositeOperation operationWithBlock:^(COOperation *operation) {

                @synchronized(countArr) {
                    [countArr addObject:@1];
                }

                @synchronized(accResult) {
                   [accResult appendString:[NSString stringWithFormat:@"%d", i]];
                }

                [operation finish];
            }];
        }
    }, ^{
        passedHandler = YES;
    }, nil);

    while (passedHandler == NO);

    STAssertEquals((int)countArr.count, 30, @"Expected count to be equal 30");
    STAssertTrue(passedHandler, @"Expected passedHandler to be equal YES");
    NSLog(@"%s: accResult is: %@", __PRETTY_FUNCTION__, accResult);

    COSetDefaultQueue(nil);

}

- (void) test_COCompositeOperationConcurrent_in_operation_queue {
    __block BOOL isFinished = NO;
    NSMutableArray *countArr = [NSMutableArray array];

    COOperationQueue *opQueue = [COOperationQueue new];
    opQueue.queue = createQueue();

    STAssertEquals((int)opQueue.pendingOperations.count, 0, nil);
    STAssertEquals((int)opQueue.runningOperations.count, 0, nil);

    compositeOperation(COCompositeOperationConcurrent, opQueue, ^(COCompositeOperation *to) {
        STAssertEquals((int)opQueue.runningOperations.count, 1, nil);

        [to operationWithBlock:^(COOperation *tao) {

            @synchronized(countArr) {
                [countArr addObject:@1];
            }

            [tao finish];
        }];

        [to operationWithBlock:^(COOperation *tao) {

            @synchronized(countArr) {
                [countArr addObject:@1];
            }

            [tao finish];
        }];

        [to operationWithBlock:^(COOperation *tao) {

            @synchronized(countArr) {
                [countArr addObject:@1];
            }

            [tao finish];
        }];
    }, ^{
        isFinished = YES;
    }, ^(COCompositeOperation *to){});

    while (!isFinished);

    STAssertEquals((int)countArr.count, 3, @"Expected count to be equal 3");
}

- (void) test_compositeConcurrentOperation_operationInQueue {
    __block BOOL isFinished = NO;
    NSMutableArray *countArr = [NSMutableArray array];

    compositeOperation(COCompositeOperationConcurrent, ^(COCompositeOperation *compositeOperation) {
        [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *operation) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [operation finish];
        }];
        [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *operation) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [operation finish];
        }];
        [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *operation) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [operation finish];
        }];
    }, ^{
        isFinished = YES;
    }, ^(COCompositeOperation *compositeOperation){
        raiseShouldNotReachHere();
    });

    while (!isFinished);

    STAssertEquals((int)countArr.count, 3, @"Expected count to be equal 3");
}

- (void) test_compositeConcurrentOperation_Integration {
    __block BOOL isFinished = NO;
    __block BOOL passedHandler = NO;
    NSMutableArray *countArr = [NSMutableArray array];

    dispatch_sync(createQueue(), ^{
        compositeOperation(COCompositeOperationConcurrent, ^(COCompositeOperation *to) {
            [to operationWithBlock:^(COOperation *o) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [o finish];
            }];

            [to operationWithBlock:^(COOperation *o) {
                asynchronousJob(^{
                    @synchronized(countArr) {
                        [countArr addObject:@1];
                    }
                    [o finish];
                });
            }];

            [to compositeOperation:COCompositeOperationConcurrent withBlock:^(COCompositeOperation *co) {
                [co operationWithBlock:^(COOperation *o) {
                    @synchronized(countArr) {
                        [countArr addObject:@1];
                    }
                    [o finish];
                }];

                [co operationWithBlock:^(COOperation *o) {
                    @synchronized(countArr) {
                        [countArr addObject:@1];
                    }
                    [o finish];
                }];
            }];
        }, ^{
            passedHandler = YES;
            isFinished = YES;
        }, nil);

        while (!isFinished);
    });
    
    STAssertEquals((int)countArr.count, 4, @"Expected count to be equal 3");
    STAssertTrue(passedHandler, @"Expected passedHandler to be equal YES");
}

- (void)test_nesting_composite_operations_roughIntegration {
    __block BOOL isDone = NO;
    __block BOOL reachedTheLastAndTheMostNestedOperation = NO;
    
    __block COCompositeOperation *cascOp;

    compositeOperation(COCompositeOperationConcurrent, ^(COCompositeOperation *compositeOperation) {
        cascOp = compositeOperation;
        
        [compositeOperation compositeOperation:COCompositeOperationConcurrent withBlock:^(COCompositeOperation *compositeOperation) {
            [compositeOperation compositeOperation:COCompositeOperationSerial withBlock:^(COCompositeOperation *compositeOperation) {
                [compositeOperation compositeOperation:COCompositeOperationConcurrent withBlock:^(COCompositeOperation *compositeOperation) {
                    [compositeOperation compositeOperation:COCompositeOperationConcurrent withBlock:^(COCompositeOperation *compositeOperation) {
                        [compositeOperation operationWithBlock:^(COOperation *operation) {
                            [operation finish];
                        }];

                        [compositeOperation compositeOperation:COCompositeOperationConcurrent withBlock:^(COCompositeOperation *compositeOperation) {
                            [compositeOperation operationWithBlock:^(COOperation *operation) {
                                [operation finish];
                            }];
                        }];

                        [compositeOperation compositeOperation:COCompositeOperationConcurrent withBlock:^(COCompositeOperation *compositeOperation) {
                            [compositeOperation operationWithBlock:^(COOperation *operation) {
                                reachedTheLastAndTheMostNestedOperation = YES;
                                [operation finish];
                            }];
                        }];
                    }];
                }];

                [compositeOperation operationWithBlock:^(COOperation *operation) {
                    [operation finish];
                }];
            }];
        }];

        [compositeOperation operationWithBlock:^(COOperation *operation) {
            [operation finish];
        }];
    }, ^{
        isDone = YES;

        STAssertTrue(cascOp.isFinished, nil);
        STAssertTrue(reachedTheLastAndTheMostNestedOperation, nil);
    }, ^(COCompositeOperation *compositeOperation){
        raiseShouldNotReachHere();
    });

    while(!isDone) {}
}

//

- (void)test_run_completionHandler_cancellationHandler {
    __block BOOL blockFlag = NO;

    COOperationQueue *queue = [COOperationQueue new];
    queue.queue = serialQueue();

    __block COOperation *op;
    
    operation(queue, ^(COOperation *operation) {
        op = operation;
        [operation cancel];
    }, ^{
        raiseShouldNotReachHere();
    }, ^{
        STAssertTrue(op.isCancelled, nil);

        blockFlag = YES;
    });

    while(blockFlag == NO);
}

@end
