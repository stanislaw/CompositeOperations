//
//  GlobalNamespacedHelpersTest.m
//  CompositeOperationsTests
//
//  Created by Stanislaw Pankevich on 10/20/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "SACompositeOperations.h"
#import "SAQueues.h"

@interface GlobalNamespacedHelpersTest : SenTestCase
@end

@implementation GlobalNamespacedHelpersTest

- (void)testSyncOperation {
    __block BOOL soOver = NO;

    syncOperation(^(SASyncOperation *so){
        soOver = YES;
        [so finish];
    });

    STAssertTrue(soOver, @"Expected soOver to be YES");
}

- (void)test_syncOperation_in_queue {
    __block BOOL soOver = NO;

    syncOperation(concurrentQueue(), ^(SASyncOperation *so){
        soOver = YES;
        [so finish];
    });

    STAssertTrue(soOver, @"Expected soOver to be YES");
}

- (void)test_syncOperation_rough_integration {
    for (int i = 0; i < 10; i++) {
        __block BOOL soOver = NO;

        SASyncOperation *sOperation = [SASyncOperation new];

        STAssertFalse(sOperation.isFinished, nil);

        [sOperation runInQueue:concurrentQueue() operation:^(SASyncOperation *so) {
            STAssertFalse(sOperation.isFinished, nil);

            syncOperation(concurrentQueue(), ^(SASyncOperation *syOp) {
                STAssertFalse(syOp.isFinished, nil);

                syncOperation(concurrentQueue(), ^(SASyncOperation *syOp) {
                    STAssertFalse(syOp.isFinished, nil);

                    syncOperation(concurrentQueue(), ^(SASyncOperation *syOp) {
                        STAssertFalse(syOp.isFinished, nil);

                        soOver = YES;
                        [syOp finish];
                        STAssertTrue(soOver, nil);
                        STAssertTrue(syOp.isFinished, nil);
                    });

                    [syOp finish];
                    STAssertTrue(soOver, nil);
                    STAssertTrue(syOp.isFinished, nil);
                });

                [syOp finish];
                STAssertTrue(soOver, nil);
                STAssertTrue(syOp.isFinished, nil);
            });

            [so finish];
            STAssertTrue(soOver, nil);
            STAssertTrue(so.isFinished, nil);
        }];

        STAssertTrue(sOperation.isFinished, nil);
        STAssertTrue(soOver, nil);
    }
}

- (void)test_operation {
    __block BOOL oOver = NO;

    operation(^(SAOperation *o) {
        oOver = YES;
        [o finish];
    });

    while (!oOver) {}

    STAssertTrue(oOver, @"Expected aoOver to be YES");
}

- (void)test_operation_in_queue {
    __block BOOL oOver = NO;

    operation(concurrentQueue(), ^(SAOperation *o) {
        oOver = YES;
        [o finish];
    });

    while (!oOver) {}

    STAssertTrue(oOver, @"Expected aoOver to be YES");
}

- (void)test_operation_in_operation_queue {
    __block BOOL oOver = NO;
    
    SAOperationQueue *opQueue = [SAOperationQueue new];
    opQueue.queue = createQueue();

    STAssertEquals((int)opQueue.pendingOperations.count, 0, nil);
    STAssertEquals((int)opQueue.runningOperations.count, 0, nil);
    
    operation(opQueue, ^(SAOperation *o) {
        STAssertEquals((int)opQueue.runningOperations.count, 1, nil);
        [o finish];
        oOver = YES;
    });

    while (!oOver) {}

    STAssertEquals((int)opQueue.runningOperations.count, 0, nil);

    STAssertTrue(oOver, @"Expected aoOver to be YES");
}

- (void)testCascadeOperation {
    __block int count = 0;
    __block BOOL isFinished = NO;
    __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

    cascadeOperation(^(SACascadeOperation *rco) {
        [rco operation:^(SAOperation *rao) {
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

        [rco operation:^(SAOperation *rao) {
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

        [rco operation:^(SAOperation *rao) {
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

- (void)testCascadeOperation_Integration {
    NSMutableArray *countArr = [NSMutableArray array];
    __block BOOL isFinished = NO;
    __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

    __block NSMutableString *accResult = [NSMutableString string];

    cascadeOperation(^(SACascadeOperation *co) {
        [co operation:^(SAOperation *rao) {
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

        [co operation:^(SAOperation *rao) {
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

        [co operation:^(SAOperation *rao) {
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

        [co transactionalOperation:^(SATransactionalOperation *to) {
            [to operation:^(SAOperation *tao) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [accResult appendString:@"t1"];
                [tao finish];
            }];

            [to operation:^(SAOperation *tao) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [accResult appendString:@"t2"];
                [tao finish];
            }];

            [to operation:^(SAOperation *tao) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [accResult appendString:@"t3"];
                [tao finish];
            }];
        }];

        [co operation:^(SAOperation *cuo) {
            [cuo finish];
            isFinished = YES;
        }];
    }, nil, nil);
    
    while (!isFinished);

    STAssertEquals((int)countArr.count, 6, @"Expected count to be equal 6");
    NSLog(@"%s: accResult is: %@", __PRETTY_FUNCTION__, accResult);

}

- (void)test_cascadeOperation_in_operation_queue {
    SAOperationQueue *opQueue = [SAOperationQueue new];
    opQueue.queue = concurrentQueue();
    
    __block int count = 0;
    __block BOOL isFinished = NO;

    cascadeOperation(opQueue, ^(SACascadeOperation *sco) {
        [sco operation:^(SAOperation *cao) {
            count = count + 1;

            STAssertEquals((int)count, 1, @"Expected count to be equal 1 inside the first operation");

            [cao finish];
        }];

        [sco operation:^(SAOperation *cao) {
            count = count + 1;

            STAssertEquals((int)count, 2, @"Expected count to be equal 2 inside the second operation");

            [cao finish];
        }];

        [sco operation:^(SAOperation *cao) {
            count = count + 1;

            STAssertEquals((int)count, 3, @"Expected count to be equal 3 inside the third operation");

            [cao finish];
            isFinished = YES;
        }];
    }, nil, nil);

    while (!isFinished);
    
    STAssertEquals(count, 3, @"Expected count to be equal 3");
}

- (void)testTransactionalOperation {
    __block BOOL passedHandler = NO;
    
    NSMutableArray *countArr = [NSMutableArray array];
    NSMutableString *accResult = [NSMutableString string];

    SASetDefaultQueue(concurrentQueue());
    
    transactionalOperation(^(SATransactionalOperation *to) {
        for (int i = 1; i <= 30; i++) {
            [to operation:^(SAOperation *tao) {

                @synchronized(countArr) {
                    [countArr addObject:@1];
                }

                @synchronized(accResult) {
                   [accResult appendString:[NSString stringWithFormat:@"%d", i]];
                }
                
                [tao finish];
            }];
        }
    }, ^{
        passedHandler = YES;
    }, nil);

    while (!passedHandler);

    STAssertEquals((int)countArr.count, 30, @"Expected count to be equal 30");
    STAssertTrue(passedHandler, @"Expected passedHandler to be equal YES");
    NSLog(@"%s: accResult is: %@", __PRETTY_FUNCTION__, accResult);

    SASetDefaultQueue(nil);
}

- (void) test_transactionalOperation_in_operation_queue {
    __block BOOL isFinished = NO;
    NSMutableArray *countArr = [NSMutableArray array];

    SAOperationQueue *opQueue = [SAOperationQueue new];
    opQueue.queue = createQueue();

    STAssertEquals((int)opQueue.pendingOperations.count, 0, nil);
    STAssertEquals((int)opQueue.runningOperations.count, 0, nil);

    transactionalOperation(opQueue, ^(SATransactionalOperation *to) {
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
    }, ^{
        isFinished = YES;
    }, ^(SATransactionalOperation *to){});

    while (!isFinished);

    STAssertEquals((int)countArr.count, 3, @"Expected count to be equal 3");
}

- (void) testTransactionalOperation_operationInQueue {
    __block BOOL isFinished = NO;
    NSMutableArray *countArr = [NSMutableArray array];

    transactionalOperation(^(SATransactionalOperation *to) {
        [to operationInQueue:concurrentQueue() operation:^(SAOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
        [to operationInQueue:concurrentQueue() operation:^(SAOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
        [to operationInQueue:concurrentQueue() operation:^(SAOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
    }, ^{
        isFinished = YES;
    }, nil);

    while (!isFinished);

    STAssertEquals((int)countArr.count, 3, @"Expected count to be equal 3");
}

- (void) testTransactionalOperation_Integration {
    __block BOOL isFinished = NO;
    __block BOOL passedHandler = NO;
    NSMutableArray *countArr = [NSMutableArray array];

    dispatch_sync(createQueue(), ^{
        transactionalOperation(^(SATransactionalOperation *to) {
            [to operation:^(SAOperation *o) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [o finish];
            }];

            [to operation:^(SAOperation *o) {
                asynchronousJob(^{
                    @synchronized(countArr) {
                        [countArr addObject:@1];
                    }
                    [o finish];
                });
            }];

            [to cascadeOperation:^(SACascadeOperation *co) {
                [co operation:^(SAOperation *o) {
                    @synchronized(countArr) {
                        [countArr addObject:@1];
                    }
                    [o finish];
                }];

                [co operation:^(SAOperation *o) {
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

- (void)test_nestingCascadeAndTranscationalOperations_roughIntegration {
    __block BOOL isDone = NO;
    __block BOOL reachedTheLastAndTheMostNestedOperation = NO;
    
    __block SACascadeOperation *cascOp;

    cascadeOperation(^(SACascadeOperation *cascadeOperation) {
        cascOp = cascadeOperation;
        
        [cascadeOperation cascadeOperation:^(SACascadeOperation *cascadeOperation) {
            [cascadeOperation cascadeOperation:^(SACascadeOperation *cascadeOperation) {
                [cascadeOperation transactionalOperation:^(SATransactionalOperation *transactionalOperation) {
                    [transactionalOperation cascadeOperation:^(SACascadeOperation *cascadeOperation) {
                        [cascadeOperation operation:^(SAOperation *operation) {
                            [operation finish];
                        }];

                        [transactionalOperation cascadeOperation:^(SACascadeOperation *cascadeOperation) {
                            [cascadeOperation operation:^(SAOperation *operation) {
                                [operation finish];
                            }];
                        }];

                        [transactionalOperation cascadeOperation:^(SACascadeOperation *cascadeOperation) {
                            [cascadeOperation operation:^(SAOperation *operation) {
                                reachedTheLastAndTheMostNestedOperation = YES;
                                [operation finish];
                            }];
                        }];
                    }];
                }];

                [cascadeOperation operation:^(SAOperation *operation) {
                    isDone = YES;
                }];
            }];
        }];

        [cascadeOperation operation:^(SAOperation *operation) {
            [operation finish];
        }];
    }, ^{
        STAssertTrue(cascOp.isFinished, nil);
        STAssertTrue(reachedTheLastAndTheMostNestedOperation, nil);
    }, ^(SACascadeOperation *cascade){
        raiseShouldNotReachHere();
    });

    while(!isDone) {}
}

//

- (void)test_run_completionHandler_cancellationHandler {
    __block BOOL blockFlag = NO;

    SAOperationQueue *queue = [SAOperationQueue new];
    queue.queue = serialQueue();

    __block SAOperation *op;
    
    operation(queue, ^(SAOperation *operation) {
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
