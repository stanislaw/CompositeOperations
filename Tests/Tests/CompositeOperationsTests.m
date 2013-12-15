
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

    while (oOver == NO) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);
    }

    STAssertTrue(oOver, @"Expected aoOver to be YES");
}

//- (void)test_operation_in_queue {
//    __block BOOL oOver = NO;
//
//    operation(concurrentQueue(), ^(COOperation *o) {
//        oOver = YES;
//        [o finish];
//    });
//
//    while (!oOver) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);
//
//    STAssertTrue(oOver, @"Expected aoOver to be YES");
//}
//
//- (void)test_operation_in_operation_queue {
//    __block BOOL oOver = NO;
//    
//    COOperationQueue *opQueue = [COOperationQueue new];
//    opQueue.queue = createQueue();
//
//    STAssertEquals((int)opQueue.pendingOperations.count, 0, nil);
//    STAssertEquals((int)opQueue.runningOperations.count, 0, nil);
//    
//    operation(opQueue, ^(COOperation *o) {
//        STAssertEquals((int)opQueue.runningOperations.count, 1, nil);
//        [o finish];
//        oOver = YES;
//    });
//
//    while (oOver == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);
//
//    STAssertEquals((int)opQueue.runningOperations.count, 0, nil);
//
//    STAssertTrue(oOver, @"Expected aoOver to be YES");
//}
//
//
//- (void)test_operation_resolveOperation {
//    __block BOOL isFinished = NO;
//
//    NSString *predefinedResult = @("Result");
//
//    COOperation *otherOperation = [COOperation new];
//    otherOperation.operation = ^(COOperation *operation){
//        [operation finishWithResult:predefinedResult];
//    };
//
//    operation(otherOperation, ^(id result) {
//        STAssertTrue([result isEqualToString:predefinedResult], nil);
//
//        isFinished = YES;
//    }, ^(COOperation *operation, NSError *error) {
//        raiseShouldNotReachHere();
//    });
//
//    while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);
//}

- (void)test_CompositeSerialOperation {
    for (int i = 0; i < 10; i++) {
    __block int count = 0;
    __block BOOL isFinished = NO;
    __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

    __block COCompositeOperation *__compositeOperation;

    compositeOperation(COCompositeOperationSerial, ^(COCompositeOperation *compositeOperation) {
        __compositeOperation = compositeOperation;
        compositeOperation.debugLabel = [@(i) stringValue];
        [compositeOperation operationWithBlock:^(COOperation *operation) {
            operation.debugLabel = [NSString stringWithFormat:@"%@.%@", @(i), @(1)];
            asynchronousJob(^{
                count = count + 1;

                NSAssert(operation.dependencies.count == 0, nil);

                STAssertFalse(firstJobIsDone, @"Expected firstJobIsDone to be NO");
                STAssertFalse(secondJobIsDone, @"Expected secondJobIsDone to be NO");
                STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

                STAssertEquals((int)count, 1, @"Expected count to be equal 1 inside the first operation");

                firstJobIsDone = YES;
                [operation finish];
            });
        }];

        [compositeOperation operationWithBlock:^(COOperation *operation) {
            operation.debugLabel = [NSString stringWithFormat:@"%@.%@", @(i), @(2)];
            NSAssert(operation.dependencies.count == 1, nil);
            NSAssert(((COOperation *)operation.dependencies.lastObject).isFinished, nil);

            asynchronousJob(^{
                count = count + 1;

                STAssertTrue(firstJobIsDone, @"Expected firstJobIsDone to be YES");
                STAssertFalse(secondJobIsDone, @"Expected secondJobIsDone to be NO");
                STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

                STAssertEquals((int)count, 2, @"Expected count to be equal 2 inside the second operation");

                secondJobIsDone = YES;

                [operation finish];
            });
        }];

        [compositeOperation operationWithBlock:^(COOperation *operation) {
            operation.debugLabel = [NSString stringWithFormat:@"%@.%@", @(i), @(3)];
            NSAssert(operation.dependencies.count == 1, nil);
            NSAssert(((COOperation *)operation.dependencies.lastObject).isFinished, nil);

            asynchronousJob(^{
                count = count + 1;

                STAssertTrue(firstJobIsDone, @"Expected firstJobIsDone to be YES");
                STAssertTrue(secondJobIsDone, @"Expected secondJobIsDone to be YES");
                STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

                STAssertEquals((int)count, 3, @"Expected count to be equal 3 inside the third operation");

                [operation finish];
            });
        }];
    }, ^(id result) {
        isFinished = YES;
    }, nil);
    
        while (isFinished == NO) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.025, YES);
        }

    STAssertEquals(count, 3, @"Expected count to be equal 3");

    }
}

- (void)test_CompositeSerialOperation_operation {
    __block BOOL isFinished = NO;
    NSMutableArray *registry = [NSMutableArray array];

    COOperation *operation = [COOperation new];
    operation.operationBlock = ^(COOperation *operation) {
        asynchronousJob(^{
            [registry addObject:@(1)];
            [operation finish];
        });
    };

    compositeOperation(COCompositeOperationSerial, ^(COCompositeOperation *compositeOperation) {
        [compositeOperation operation:[operation copy]];
        [compositeOperation operation:[operation copy]];
        [compositeOperation operation:[operation copy]];
    }, ^(NSArray *result){
        isFinished = YES;
    }, ^(COCompositeOperation *compositeOperation, NSError *error){
        raiseShouldNotReachHere();
    });
    
    while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);

    STAssertTrue(registry.count == 3, nil);
}

- (void)test_COCompositeOperationSerial_mixed_in_COCompositeOperationSerial_using_operation_method {
    __block BOOL isFinished = NO;
    NSMutableArray *registry = [NSMutableArray array];

    COOperation *operation = [COOperation new];
    operation.operationBlock = ^(COOperation *operation) {
        asynchronousJob(^{
            [registry addObject:@(1)];
            [operation finish];
        });
    };

    COCompositeOperation *innerCompositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

    innerCompositeOperation.operationBlock = ^(COCompositeOperation *compositeOperation) {
        [compositeOperation operation:[operation copy]];
        [compositeOperation operation:[operation copy]];
        [compositeOperation operation:[operation copy]];
    };

    compositeOperation(COCompositeOperationSerial, ^(COCompositeOperation *mixedCompositeOperation) {
        [mixedCompositeOperation compositeOperation:innerCompositeOperation];
    }, ^(NSArray *result){
        isFinished = YES;
    }, ^(COCompositeOperation *compositeOperation, NSError *error){
        raiseShouldNotReachHere();
    });

    while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);

    STAssertTrue(registry.count == 3, nil);
}

- (void)test_COCompositeOperationConcurrent_mixed_in_COCompositeOperationSerial_using_operation_method {
    __block BOOL isFinished = NO;
    __block BOOL completionHandlerWasRun = NO;

    NSMutableArray *registry = [NSMutableArray array];

    COOperation *operation = [COOperation new];
    operation.operationBlock = ^(COOperation *operation) {
        asynchronousJob(^{
            [registry addObject:@(1)];
            [operation finish];
        });
    };

    COCompositeOperation *innerCompositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

    innerCompositeOperation.operationBlock = ^(COCompositeOperation *compositeOperation) {
        [compositeOperation operation:[operation copy]];
        [compositeOperation operation:[operation copy]];
        [compositeOperation operation:[operation copy]];
    };

    compositeOperation(COCompositeOperationSerial, ^(COCompositeOperation *mixedCompositeOperation) {
        [mixedCompositeOperation compositeOperation:innerCompositeOperation];
    }, ^(NSArray *result){
        completionHandlerWasRun = YES;
        isFinished = YES;
    }, ^(COCompositeOperation *compositeOperation, NSError *error){
        raiseShouldNotReachHere();
    });

    while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);

    STAssertTrue(registry.count == 3, nil);
    STAssertTrue(completionHandlerWasRun, nil);
}

- (void)test_COCompositeOperationConcurrent_mixed_in_COCompositeOperationConcurrent_using_operation_method {
    __block BOOL isFinished = NO;
    __block BOOL completionHandlerWasRun = NO;

    NSMutableArray *registry = [NSMutableArray array];

    COOperation *operation = [COOperation new];
    operation.operationBlock = ^(COOperation *operation) {
        asynchronousJob(^{
            [registry addObject:@(1)];
            [operation finish];
        });
    };

    COCompositeOperation *innerCompositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

    innerCompositeOperation.operationBlock = ^(COCompositeOperation *compositeOperation) {
        [compositeOperation operation:[operation copy]];
        [compositeOperation operation:[operation copy]];
        [compositeOperation operation:[operation copy]];
    };

    compositeOperation(COCompositeOperationConcurrent, ^(COCompositeOperation *mixedCompositeOperation) {
        [mixedCompositeOperation compositeOperation:innerCompositeOperation];
    }, ^(NSArray *result){
        completionHandlerWasRun = YES;
        isFinished = YES;
    }, ^(COCompositeOperation *compositeOperation, NSError *error){
        raiseShouldNotReachHere();
    });

    while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);

    STAssertTrue(registry.count == 3, nil);
    STAssertTrue(completionHandlerWasRun, nil);
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
    }, ^(id result){
        passedHandler = YES;
    }, nil);

    while (passedHandler == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);

    STAssertEquals((int)countArr.count, 30, @"Expected count to be equal 30");
    STAssertTrue(passedHandler, @"Expected passedHandler to be equal YES");
    NSLog(@"%s: accResult is: %@", __PRETTY_FUNCTION__, accResult);
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
    }, ^(NSArray *result){
        isFinished = YES;
    }, ^(COCompositeOperation *compositeOperation, NSError *error){
        raiseShouldNotReachHere();
    });

    while (!isFinished) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);

    STAssertEquals((int)countArr.count, 3, @"Expected count to be equal 3");
}

- (void) test_compositeSerialOperation_Integration {
    static dispatch_once_t onceToken;

    for (int i = 0; i < 10; i++) {
    onceToken = 0;

    __block BOOL isFinished = NO;
    __block BOOL passedHandler = NO;
    NSMutableArray *countArr = [NSMutableArray array];

    dispatch_sync(createQueue(), ^{
        __block COCompositeOperation *__compositeOperation;
        compositeOperation(COCompositeOperationSerial, ^(COCompositeOperation *compositeOperation) {
            compositeOperation.debugLabel = [NSString stringWithFormat:@"Composite operation #%@", @(i)];

            __compositeOperation = compositeOperation;
            [compositeOperation operationWithBlock:^(COOperation *o) {
                o.debugLabel = [@(1) stringValue];

                NSAssert(countArr.count == 0, nil);

                [countArr addObject:@1];

                [o finish];
            }];

            [compositeOperation operationWithBlock:^(COOperation *o) {
                NSAssert(countArr.count == 1, nil);

                o.debugLabel = [@(2) stringValue];
                asynchronousJob(^{
                    NSAssert(countArr.count == 1, nil);

                    [countArr addObject:@2];

                    [o finish];
                });
            }];

            [compositeOperation compositeOperation:COCompositeOperationSerial withBlock:^(COCompositeOperation *innerCompositeOperation) {
                innerCompositeOperation.debugLabel = [@(3) stringValue];

                dispatch_once_and_next_time(&onceToken, ^{
                    //
                }, ^{
                    abort();
                });

                NSString *reason = [NSString stringWithFormat:@"Expected countArr.count to be equal 2.... Inner composite operation of operation %@, countArr: %@", innerCompositeOperation, countArr];

                NSAssert(countArr.count == 2, reason);

                [innerCompositeOperation operationWithBlock:^(COOperation *operation) {
                    operation.debugLabel = [@(3.1) stringValue];

                    [countArr addObject:@3];

                    [operation finish];
                }];

                [innerCompositeOperation operationWithBlock:^(COOperation *operation) {
                    operation.debugLabel = [@(3.2) stringValue];

                    [countArr addObject:@4];

                    [operation finish];
                }];
            }];
        }, ^(id result){
            NSString *reason = [NSString stringWithFormat:@"Expected countArr to be 4, got: %lu, operation: %@", countArr.count, __compositeOperation];
            NSAssert(countArr.count == 4, reason);
            passedHandler = YES;
            isFinished = YES;
        }, nil);

        while (isFinished == NO) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.025, YES);
        }
    });
    
    STAssertEquals((int)countArr.count, 4, nil);
    STAssertTrue(passedHandler, @"Expected passedHandler to be equal YES");

    }
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
    }, ^(NSArray *result){
        isDone = YES;

        STAssertTrue(cascOp.isFinished, nil);
        STAssertTrue(reachedTheLastAndTheMostNestedOperation, nil);
    }, ^(COCompositeOperation *compositeOperation, NSError *error){
        raiseShouldNotReachHere();
    });

    while(!isDone) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);
}

@end
