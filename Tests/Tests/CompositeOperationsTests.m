
#import "TestHelpers.h"

#import "CompositeOperations.h"
#import "COQueues.h"

SPEC_BEGIN(CompositeOperationsSpecs)

beforeEach(^{
    COSetDefaultQueue(concurrentQueue());
});

describe(@"operation()", ^{
    specify(^{
        waitSemaphore = dispatch_semaphore_create(0);

        __block BOOL operationWasRun = NO;

        operation(^(COOperation *o) {
            [o finish];

            operationWasRun = YES;

            dispatch_semaphore_signal(waitSemaphore);
        });

        while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);
        }

        [[theValue(operationWasRun) should] beYes];
    });
});

describe(@"compositeOperation(COCompositeOperationSerial, ...)", ^{
    describe(@"Using operationWithBlock:", ^{
        specify(^{
            for (int i = 0; i < 10; i++) {
                waitSemaphore = dispatch_semaphore_create(0);

                __block NSMutableArray *registry = [NSMutableArray array];

                __block COCompositeOperation *__compositeOperation;

                compositeOperation(COCompositeOperationSerial, nil, ^(COCompositeOperation *compositeOperation) {
                    __compositeOperation = compositeOperation;
                    compositeOperation.name = [@(i) stringValue];
                    [compositeOperation operationWithBlock:^(COOperation *operation) {
                        operation.name = [NSString stringWithFormat:@"%@.%@", @(i), @(1)];

                        asynchronousJob(^{
                            [registry addObject:@(1)];

                            [operation finish];
                        });
                    }];

                    [compositeOperation operationWithBlock:^(COOperation *operation) {
                        operation.name = [NSString stringWithFormat:@"%@.%@", @(i), @(2)];
                        NSAssert(operation.dependencies.count == 1, @"Expected operation to have 1 dependency but got", operation, operation.dependencies);

                        NSAssert(((COOperation *)operation.dependencies.lastObject).isFinished, @"Expected operation's dependencies lastObject to be finished", operation, operation.dependencies);

                        asynchronousJob(^{
                            [registry addObject:@(2)];

                            [operation finish];
                        });
                    }];

                    [compositeOperation operationWithBlock:^(COOperation *operation) {
                        operation.name = [NSString stringWithFormat:@"%@.%@", @(i), @(3)];
                        NSAssert(operation.dependencies.count == 1, @"Expected operation to have 1 dependency but got", operation, operation.dependencies);
                        NSAssert(((COOperation *)operation.dependencies.lastObject).isFinished, @"Expected operation's dependencies lastObject to be finished", operation, operation.dependencies);

                        asynchronousJob(^{
                            [registry addObject:@(3)];

                            [operation finish];
                        });
                    }];
                }, ^(id result) {
                    dispatch_semaphore_signal(waitSemaphore);
                }, nil);
                
                while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
                }
                
                [[theValue(registry.count) should] beYes];
                
            }
        });

    });

    describe(@"Using operationWithBlock:", ^{
        specify(^{
            waitSemaphore = dispatch_semaphore_create(0);
            NSMutableArray *registry = [NSMutableArray array];

            COOperation *operation = [COOperation new];
            operation.operationBlock = ^(COOperation *operation) {
                asynchronousJob(^{
                    [registry addObject:@(1)];
                    [operation finish];
                });
            };

            compositeOperation(COCompositeOperationSerial, nil, ^(COCompositeOperation *compositeOperation) {
                [compositeOperation operation:[operation copy]];
                [compositeOperation operation:[operation copy]];
                [compositeOperation operation:[operation copy]];
            }, ^(NSArray *result){
                dispatch_semaphore_signal(waitSemaphore);
            }, ^(COCompositeOperation *compositeOperation, NSError *error){
                AssertShouldNotReachHere();
            });

            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            }

            [[theValue(registry.count) should] beYes];
        });

    });

});

describe(@"compositeOperation(COCompositeOperationConcurrent, ...)", ^{
    describe(@"Using operationWithBlock:", ^{
        specify(^{
            int N = 100;

            __block BOOL completionHandlerWasRun = NO;

            NSMutableArray *registry = [NSMutableArray array];
            NSMutableString *accResult = [NSMutableString string];

            COSetDefaultQueue(concurrentQueue());

            compositeOperation(COCompositeOperationConcurrent, nil, ^(COCompositeOperation *compositeOperation) {
                for (int i = 1; i <= N; i++) {
                    [compositeOperation operationWithBlock:^(COOperation *operation) {

                        dispatch_async(dispatch_get_main_queue(), ^{
                            [registry addObject:@(i)];

                            [accResult appendString:[NSString stringWithFormat:@"op%d", i]];
                        });

                        [operation finish];
                    }];
                }
            }, ^(id result){
                completionHandlerWasRun = YES;

                dispatch_semaphore_signal(waitSemaphore);
            }, nil);

            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            }

            [[theValue(registry.count) should] equal:@(N)];

            [[theValue(completionHandlerWasRun) should] beYes];

            NSLog(@"%s: accResult is: %@", __PRETTY_FUNCTION__, accResult);
        });

        specify(^{
            NSMutableArray *registry = [NSMutableArray array];

            compositeOperation(COCompositeOperationConcurrent, nil, ^(COCompositeOperation *compositeOperation) {
                [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *operation) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [registry addObject:@(1)];
                    });

                    [operation finish];
                }];
                [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *operation) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [registry addObject:@(1)];
                    });

                    [operation finish];
                }];
                [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *operation) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [registry addObject:@(1)];
                    });

                    [operation finish];
                }];
            }, ^(NSArray *result){

                dispatch_semaphore_signal(waitSemaphore);

            }, ^(COCompositeOperation *compositeOperation, NSError *error){
                AssertShouldNotReachHere();
            });
            
            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            }

            [[theValue(registry.count) should] equal:@(3)];
        });
    });
});

describe(@"Mixing operations", ^{
    describe(@"compositeOperation(COCompositeOperationSerial) with mixed inner composite operation", ^{
        specify(^{
            waitSemaphore = dispatch_semaphore_create(0);

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

            compositeOperation(COCompositeOperationSerial, nil, ^(COCompositeOperation *mixedCompositeOperation) {
                [mixedCompositeOperation compositeOperation:innerCompositeOperation];
            }, ^(NSArray *result){
                dispatch_semaphore_signal(waitSemaphore);
            }, ^(COCompositeOperation *compositeOperation, NSError *error){
                AssertShouldNotReachHere();
            });

            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            }
            
            [[theValue(registry.count) should] beYes];
        });
    });

    describe(@"compositeOperation(COCompositeOperationConcurrent) with mixed inner composite operation", ^{
        specify(^{
            waitSemaphore = dispatch_semaphore_create(0);
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

            compositeOperation(COCompositeOperationSerial, nil, ^(COCompositeOperation *mixedCompositeOperation) {
                [mixedCompositeOperation compositeOperation:innerCompositeOperation];
            }, ^(NSArray *result){
                completionHandlerWasRun = YES;

                dispatch_semaphore_signal(waitSemaphore);
            }, ^(COCompositeOperation *compositeOperation, NSError *error){
                AssertShouldNotReachHere();
            });
            
            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            }

            [[theValue(registry.count) should] beYes];
            [[theValue(completionHandlerWasRun) should] beYes];
        });
    });


    describe(@"Various integrations", ^{
        it(@"serial composite operation inside serial composite operation", ^{
            static dispatch_once_t onceToken;

            for (int i = 0; i < 100; i++) {
                onceToken = 0;

                NSMutableArray *registry = [NSMutableArray array];
                waitSemaphore = dispatch_semaphore_create(0);

                dispatch_sync(createQueue(), ^{
                    __block COCompositeOperation *__compositeOperation;
                    compositeOperation(COCompositeOperationSerial, nil, ^(COCompositeOperation *compositeOperation) {
                        compositeOperation.name = [NSString stringWithFormat:@"Composite operation #%@", @(i)];

                        __compositeOperation = compositeOperation;
                        [compositeOperation operationWithBlock:^(COOperation *o) {
                            o.name = [@(1) stringValue];

                            [registry addObject:@1];

                            [o finish];
                        }];

                        [compositeOperation operationWithBlock:^(COOperation *o) {
                            o.name = [@(2) stringValue];

                            asynchronousJob(^{
                                NSAssert(registry.count == 1, nil);

                                [registry addObject:@2];

                                [o finish];
                            });
                        }];

                        [compositeOperation compositeOperation:COCompositeOperationSerial withBlock:^(COCompositeOperation *innerCompositeOperation) {
                            innerCompositeOperation.name = [@(3) stringValue];

                            dispatch_once_and_next_time(&onceToken, ^{
                                //
                            }, ^{
                                abort();
                            });

                            NSString *reason = [NSString stringWithFormat:@"Expected countArr.count to be equal 2.... Inner composite operation of operation %@, countArr: %@", innerCompositeOperation, registry];

                            NSAssert(registry.count == 2, reason);

                            [innerCompositeOperation operationWithBlock:^(COOperation *operation) {
                                operation.name = [@(3.1) stringValue];

                                [registry addObject:@3];

                                [operation finish];
                            }];
                            
                            [innerCompositeOperation operationWithBlock:^(COOperation *operation) {
                                operation.name = [@(3.2) stringValue];
                                
                                [registry addObject:@4];

                                [operation finish];
                            }];
                        }];
                    }, ^(id result){
                        NSString *reason = [NSString stringWithFormat:@"Expected countArr to be 4, got: %lu, operation: %@", registry.count, __compositeOperation];
                        NSAssert(registry.count == 4, reason);

                        dispatch_semaphore_signal(waitSemaphore);
                    }, nil);
                    
                    while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
                    }

                    BOOL registryIsCorrect = [registry isEqual:@[ @(1), @(2), @(3), @(4) ]];

                    [[theValue(registryIsCorrect) should] beYes];
                });
            }
        });

        it(@"Deep nested composite operation", ^{
            for (int i = 0; i < 100; i++) {

            waitSemaphore = dispatch_semaphore_create(0);
            __block BOOL reachedTheLastAndTheMostNestedOperation = NO;

            __block COCompositeOperation *nestedCompositeOperation;

            compositeOperation(COCompositeOperationConcurrent, nil, ^(COCompositeOperation *compositeOperation) {
                nestedCompositeOperation = compositeOperation;

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
                [[theValue(nestedCompositeOperation.isFinished) should] beYes];
                [[theValue(reachedTheLastAndTheMostNestedOperation) should] beYes];

                dispatch_semaphore_signal(waitSemaphore);
            }, ^(COCompositeOperation *compositeOperation, NSError *error){
                AssertShouldNotReachHere();
            });
            
            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            }

            [[theValue(nestedCompositeOperation.isFinished) should] beYes];

            }
        });
    });
});


SPEC_END

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
//        AssertShouldNotReachHere();
//    });
//
//    while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);
//}