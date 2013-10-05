//
//  GlobalNamespacedHelpersTest.m
//  CompositeOperationsTests
//
//  Created by Stanislaw Pankevich on 10/20/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "CompositeOperations.h"
#import "COQueues.h"

@interface GlobalNamespacedHelpersTest : SenTestCase
@end

@implementation GlobalNamespacedHelpersTest

- (void)testSyncOperation {
    __block BOOL soOver = NO;

    syncOperation(^(COSyncOperation *so){
        soOver = YES;
        [so finish];
    });

    STAssertTrue(soOver, @"Expected soOver to be YES");
}

- (void)test_syncOperation_in_queue {
    __block BOOL soOver = NO;

    syncOperation(concurrentQueue(), ^(COSyncOperation *so){
        soOver = YES;
        [so finish];
    });

    STAssertTrue(soOver, @"Expected soOver to be YES");
}

- (void)test_syncOperation_rough_integration {
    for (int i = 0; i < 10; i++) {
        __block BOOL soOver = NO;

        COSyncOperation *sOperation = [COSyncOperation new];

        STAssertFalse(sOperation.isFinished, nil);

        [sOperation runInQueue:concurrentQueue() operation:^(COSyncOperation *so) {
            STAssertFalse(sOperation.isFinished, nil);

            syncOperation(concurrentQueue(), ^(COSyncOperation *syOp) {
                STAssertFalse(syOp.isFinished, nil);

                syncOperation(concurrentQueue(), ^(COSyncOperation *syOp) {
                    STAssertFalse(syOp.isFinished, nil);

                    syncOperation(concurrentQueue(), ^(COSyncOperation *syOp) {
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

- (void)testCascadeOperation {
    __block int count = 0;
    __block BOOL isFinished = NO;
    __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

    cascadeOperation(^(COCascadeOperation *rco) {
        [rco operation:^(COOperation *rao) {
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

        [rco operation:^(COOperation *rao) {
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

        [rco operation:^(COOperation *rao) {
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

    cascadeOperation(^(COCascadeOperation *co) {
        [co operation:^(COOperation *rao) {
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

        [co operation:^(COOperation *rao) {
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

        [co operation:^(COOperation *rao) {
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

        [co transactionalOperation:^(COTransactionalOperation *to) {
            [to operation:^(COOperation *tao) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [accResult appendString:@"t1"];
                [tao finish];
            }];

            [to operation:^(COOperation *tao) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [accResult appendString:@"t2"];
                [tao finish];
            }];

            [to operation:^(COOperation *tao) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [accResult appendString:@"t3"];
                [tao finish];
            }];
        }];

        [co operation:^(COOperation *cuo) {
            [cuo finish];
            isFinished = YES;
        }];
    }, nil, nil);
    
    while (!isFinished);

    STAssertEquals((int)countArr.count, 6, @"Expected count to be equal 6");
    NSLog(@"%s: accResult is: %@", __PRETTY_FUNCTION__, accResult);

}

- (void)test_cascadeOperation_in_operation_queue {
    COOperationQueue *opQueue = [COOperationQueue new];
    opQueue.queue = concurrentQueue();
    
    __block int count = 0;
    __block BOOL isFinished = NO;

    cascadeOperation(opQueue, ^(COCascadeOperation *sco) {
        [sco operation:^(COOperation *cao) {
            count = count + 1;

            STAssertEquals((int)count, 1, @"Expected count to be equal 1 inside the first operation");

            [cao finish];
        }];

        [sco operation:^(COOperation *cao) {
            count = count + 1;

            STAssertEquals((int)count, 2, @"Expected count to be equal 2 inside the second operation");

            [cao finish];
        }];

        [sco operation:^(COOperation *cao) {
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

    COSetDefaultQueue(concurrentQueue());
    
    transactionalOperation(^(COTransactionalOperation *to) {
        for (int i = 1; i <= 30; i++) {
            [to operation:^(COOperation *tao) {

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

    COSetDefaultQueue(nil);
}

- (void) test_transactionalOperation_in_operation_queue {
    __block BOOL isFinished = NO;
    NSMutableArray *countArr = [NSMutableArray array];

    COOperationQueue *opQueue = [COOperationQueue new];
    opQueue.queue = createQueue();

    STAssertEquals((int)opQueue.pendingOperations.count, 0, nil);
    STAssertEquals((int)opQueue.runningOperations.count, 0, nil);

    transactionalOperation(opQueue, ^(COTransactionalOperation *to) {
        STAssertEquals((int)opQueue.runningOperations.count, 1, nil);

        [to operation:^(COOperation *tao) {

            @synchronized(countArr) {
                [countArr addObject:@1];
            }

            [tao finish];
        }];

        [to operation:^(COOperation *tao) {

            @synchronized(countArr) {
                [countArr addObject:@1];
            }

            [tao finish];
        }];

        [to operation:^(COOperation *tao) {

            @synchronized(countArr) {
                [countArr addObject:@1];
            }

            [tao finish];
        }];
    }, ^{
        isFinished = YES;
    }, ^(COTransactionalOperation *to){});

    while (!isFinished);

    STAssertEquals((int)countArr.count, 3, @"Expected count to be equal 3");
}

- (void) testTransactionalOperation_operationInQueue {
    __block BOOL isFinished = NO;
    NSMutableArray *countArr = [NSMutableArray array];

    transactionalOperation(^(COTransactionalOperation *to) {
        [to operationInQueue:concurrentQueue() operation:^(COOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
        [to operationInQueue:concurrentQueue() operation:^(COOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
        [to operationInQueue:concurrentQueue() operation:^(COOperation *tao) {
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
        transactionalOperation(^(COTransactionalOperation *to) {
            [to operation:^(COOperation *o) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [o finish];
            }];

            [to operation:^(COOperation *o) {
                asynchronousJob(^{
                    @synchronized(countArr) {
                        [countArr addObject:@1];
                    }
                    [o finish];
                });
            }];

            [to cascadeOperation:^(COCascadeOperation *co) {
                [co operation:^(COOperation *o) {
                    @synchronized(countArr) {
                        [countArr addObject:@1];
                    }
                    [o finish];
                }];

                [co operation:^(COOperation *o) {
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
    
    __block COCascadeOperation *cascOp;

    cascadeOperation(^(COCascadeOperation *cascadeOperation) {
        cascOp = cascadeOperation;
        
        [cascadeOperation cascadeOperation:^(COCascadeOperation *cascadeOperation) {
            [cascadeOperation cascadeOperation:^(COCascadeOperation *cascadeOperation) {
                [cascadeOperation transactionalOperation:^(COTransactionalOperation *transactionalOperation) {
                    [transactionalOperation cascadeOperation:^(COCascadeOperation *cascadeOperation) {
                        [cascadeOperation operation:^(COOperation *operation) {
                            [operation finish];
                        }];

                        [transactionalOperation cascadeOperation:^(COCascadeOperation *cascadeOperation) {
                            [cascadeOperation operation:^(COOperation *operation) {
                                [operation finish];
                            }];
                        }];

                        [transactionalOperation cascadeOperation:^(COCascadeOperation *cascadeOperation) {
                            [cascadeOperation operation:^(COOperation *operation) {
                                reachedTheLastAndTheMostNestedOperation = YES;
                                [operation finish];
                            }];
                        }];
                    }];
                }];

                [cascadeOperation operation:^(COOperation *operation) {
                    isDone = YES;
                }];
            }];
        }];

        [cascadeOperation operation:^(COOperation *operation) {
            [operation finish];
        }];
    }, ^{
        STAssertTrue(cascOp.isFinished, nil);
        STAssertTrue(reachedTheLastAndTheMostNestedOperation, nil);
    }, ^(COCascadeOperation *cascade){
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
