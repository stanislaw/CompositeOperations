
#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "COCompositeOperation.h"
#import "COOperation_Private.h"
#import "COCompositeOperation_Private.h"

#import "COQueues.h"

SPEC_BEGIN(COCompositeOperationSerialSpecs)

describe(@"COCompositeOperationSerial", ^{
    beforeEach(^{
        COSetDefaultQueue(concurrentQueue());
    });

    describe(@"Basics", ^{
        it(@"should run composite operation", ^{
            waitSemaphore = dispatch_semaphore_create(0);

            __block BOOL completionBlockWasRun = NO;

            NSMutableArray *registry = [NSMutableArray array];

            COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];
            compositeOperation.operationQueue = [[NSOperationQueue alloc] init];

            [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                [[theValue(currentQueue() == dispatch_get_main_queue()) should] beYes];

                [compositeOperation operationWithBlock:^(COOperation *operation) {
                    asynchronousJob(^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"First operation");
                        });

                        [registry addObject:@(1)];

                        [operation finish];
                    });
                }];

                [compositeOperation operationWithBlock:^(COOperation *operation) {
                    asynchronousJob(^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"Second operation");
                        });

                        [registry addObject:@(2)];

                        [operation finish];
                    });
                }];

                [compositeOperation operationWithBlock:^(COOperation *operation) {
                    asynchronousJob(^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"Third operation");
                        });

                        [registry addObject:@(3)];

                        [operation finish];
                    });
                }];
            } completionHandler:^(id result) {
                completionBlockWasRun = YES;

                dispatch_semaphore_signal(waitSemaphore);
            } cancellationHandler:nil];
            
            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            }
            
            BOOL registryIsCorrect = [registry isEqual:@[ @(1), @(2), @(3) ]];
            
            [[theValue(registryIsCorrect) should] beYes];
            [[theValue(completionBlockWasRun) should] beYes];
        });
    });

    describe(@"-[COCompositeOperation operationInQueue:withBlock:]", ^{
        it(@"", ^{
            __block BOOL isFinished = NO;
            NSMutableArray *registry = [NSMutableArray array];

            COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];
            compositeOperation.operationQueue = [[NSOperationQueue alloc] init];

            [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *cao) {
                    [registry addObject:@(1)];

                    [cao finish];
                }];

                [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *cao) {
                    [registry addObject:@(2)];

                    [cao finish];
                }];

                [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *cao) {
                    [registry addObject:@(3)];

                    [cao finish];
                }];
            } completionHandler:^(NSArray *result){
                isFinished = YES;
            } cancellationHandler:nil];
            
            while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, NO);

            BOOL registryIsCorrect = [registry isEqual:@[ @(1), @(2), @(3) ]];
            [[theValue(registryIsCorrect) should] beYes];
        });
    });

    describe(@"Dispatch contexts", ^{
        describe(@"Default dispatch queue", ^{
            it(@"should run operation inside CODefaultQueue()", ^{
                __block BOOL isFinished = NO;
                COSetDefaultQueue(concurrentQueue());

                COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];
                compositeOperation.operationQueue = [[NSOperationQueue alloc] init];
                
                [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                    [compositeOperation operationWithBlock:^(COOperation *cao) {
                        [[theValue(currentQueue() == concurrentQueue()) should] beYes];

                        [cao finish];
                        isFinished = YES;
                    }];
                } completionHandler:nil cancellationHandler:nil];

                while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, NO);
            });

            it(@"should run operation inside CODefaultQueue()", ^{
                __block BOOL isFinished = NO;

                COSetDefaultQueue(serialQueue());

                COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];
                compositeOperation.operationQueue = [[NSOperationQueue alloc] init];

                [compositeOperation run:^(COCompositeOperation *co) {
                    [compositeOperation operationWithBlock:^(COOperation *cao) {
                        [[theValue(currentQueue() == serialQueue()) should] beYes];

                        [cao finish];
                        isFinished = YES;
                    }];
                } completionHandler:nil cancellationHandler:nil];

                while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, NO);
            });
        });
    });

    describe(@"Rejection", ^{
        describe(@"First operation is rejected (-reject)", ^{
            it(@"should propagate rejection(cancellation) of all operations", ^{
                for (int i = 0; i < 1; i++) {
                __block BOOL isFinished = NO;

                COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];
                compositeOperation.operationQueue = [[NSOperationQueue alloc] init];
                    
                [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                    [compositeOperation operationWithBlock:^(COOperation *operation) {
                        [operation reject];
                    }];

                    [compositeOperation operationWithBlock:^(COOperation *operation) {
                        [operation finish];
                    }];

                    [compositeOperation operationWithBlock:^(COOperation *operation) {
                        [operation finish];
                    }];
                } completionHandler:^(NSArray *result){
                    raiseShouldNotReachHere();
                } cancellationHandler:^(COCompositeOperation *compositeOperation, NSError *error) {
                    [[theValue(compositeOperation.isCancelled) should] beYes];

                    for (COOperation *operation in compositeOperation.zOperation.dependencies) {
                        [[theValue(operation.isFinished) should] beYes];
                    }

                    isFinished = YES;
                }];

                while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, NO);
                }
            });
        });

        describe(@"First operation is cancelled (-cancelWithError:)", ^{
            it(@"should propagate cancellation on all operations and pass NSError to composite operation", ^{
                __block BOOL isFinished = NO;
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:1 userInfo:nil];

                COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];
                compositeOperation.operationQueue = [[NSOperationQueue alloc] init];
                
                [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                    [compositeOperation operationWithBlock:^(COOperation *operation) {
                        [operation rejectWithError:error];
                    }];

                    [compositeOperation operationWithBlock:^(COOperation *operation) {
                        [operation finish];
                    }];

                    [compositeOperation operationWithBlock:^(COOperation *operation) {
                        [operation finish];
                    }];
                } completionHandler:^(id result){
                    NSAssert(NO, @"Expected operation to not reach here: %@", compositeOperation);
                } cancellationHandler:^(COCompositeOperation *compositeOperation, NSError *_error) {
                    [[theValue([_error isEqual:error]) should] beYes];
                    
                    for (COOperation *operation in compositeOperation.zOperation.dependencies) {
                        [[theValue(operation.isFinished) should] beYes];
                    }

                    isFinished = YES;
                }];

                while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, NO);
            });
        });
    });

    describe(@"Shared data", ^{
        it(@"should keep shared data (primitive test)", ^{
            __block BOOL isFinished = NO;

            __block NSString *data = @"1";

            COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];
            compositeOperation.operationQueue = [[NSOperationQueue alloc] init];
            
            [compositeOperation run:^(COCompositeOperation *co) {
                [co operationWithBlock:^(COOperation *cao) {
                    [co safelyAccessData:^(id _data) {
                        return data;
                    }];

                    [cao finish];
                }];

                [co operationWithBlock:^(COOperation *cao) {
                    [co safelyAccessData:^id(id _data) {
                        [[theValue([_data isEqualToString:data]) should] beYes];

                        return nil;
                    }];

                    isFinished = YES;
                    [cao finish];
                }];
            } completionHandler:nil cancellationHandler:nil];
            
            while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, NO);
        });
    });

    describe(@"Nested composite operations", ^{
        describe(@"", ^{
            it(@"", ^{
                NSMutableArray *countArr = [NSMutableArray array];
                __block BOOL isFinished = NO;

                COCompositeOperation *cOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];
                cOperation.operationQueue = [[NSOperationQueue alloc] init];

                [cOperation run:^(COCompositeOperation *co) {
                    [co operationWithBlock:^(COOperation *cuo) {
                        [cuo finish];
                    }];

                    [co compositeOperation:COCompositeOperationConcurrent withBlock:^(COCompositeOperation *innerCompositeOperation) {
                        [innerCompositeOperation operationWithBlock:^(COOperation *operation) {
                            @synchronized(countArr) {
                                [countArr addObject:@1];
                            }
                            [operation finish];
                        }];

                        [innerCompositeOperation operationWithBlock:^(COOperation *operation) {
                            @synchronized(countArr) {
                                [countArr addObject:@1];
                            }
                            [operation finish];
                        }];
                    }];
                    
                    [co operationWithBlock:^(COOperation *operation) {
                        [operation finish];
                    }];
                } completionHandler:^(NSArray *result) {
                    isFinished = YES;
                } cancellationHandler:nil];
                
                while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, NO);

                [[theValue(countArr.count) should] equal:@(2)];
            });
        });
    });

    describe(@"Lazy copying", ^{
        it(@"should copy composite operation", ^{
            static dispatch_once_t thirdOperationToken;

            __block COCompositeOperation *lazyCopiedOperation;

            waitSemaphore = dispatch_semaphore_create(0);

            __block BOOL completionBlockWasRun = NO;

            NSMutableArray *checkpoints = [NSMutableArray array];
            NSMutableArray *registry = [NSMutableArray array];

            COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];
            compositeOperation.operationQueue = [[NSOperationQueue alloc] init];

            [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                [[theValue(currentQueue() == dispatch_get_main_queue()) should] beYes];

                [compositeOperation operationWithBlock:^(COOperation *operation) {
                    asynchronousJob(^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"First operation");
                        });

                        [registry addObject:@(1)];

                        [operation finish];
                    });
                }];

                [compositeOperation operationWithBlock:^(COOperation *operation) {
                    asynchronousJob(^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"Second operation");
                        });

                        [registry addObject:@(2)];

                        [operation finish];
                    });
                }];

                [compositeOperation operationWithBlock:^(COOperation *operation) {
                    asynchronousJob(^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"Third operation");
                        });

                        dispatch_once_and_next_time(&thirdOperationToken, ^{
                            [operation reject];
                        }, ^{
                            NSLog(@"lalalala %@", lazyCopiedOperation);


                            [registry addObject:@(3)];

                            [operation finish];
                        });
                    });
                }];
            } completionHandler:^(id result) {
                static dispatch_once_t completionToken;
                dispatch_once_and_next_time(&completionToken, ^{
                }, ^{
                    abort();
                });

                completionBlockWasRun = YES;

                dispatch_semaphore_signal(waitSemaphore);

            } cancellationHandler:^(COCompositeOperation *compositeOperation, NSError *error) {
                static dispatch_once_t cancellationToken;
                dispatch_once_and_next_time(&cancellationToken, ^{
                }, ^{
                    abort();
                });

                dispatch_semaphore_signal(waitSemaphore);

                lazyCopiedOperation = [compositeOperation lazyCopy];
                [lazyCopiedOperation.operationQueue addOperation:lazyCopiedOperation];
            }];

            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            }

            BOOL registryIsCorrect = [registry isEqual:@[ @(1), @(2) ]];
            [[theValue(registryIsCorrect) should] beYes];

            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            }

            registryIsCorrect = [registry isEqual:@[ @(1), @(2), @(3) ]];
            
            [[theValue(registryIsCorrect) should] beYes];
            [[theValue(completionBlockWasRun) should] beYes];
        });
    });

});

SPEC_END

