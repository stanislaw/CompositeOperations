
#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "COCompositeOperation.h"
#import "COOperation_Private.h"
#import "COCompositeOperation_Private.h"

#import "COQueues.h"
#import "COOperationQueue.h"

SPEC_BEGIN(COCompositeOperationSerialSpecs)

describe(@"COCompositeOperationSerial", ^{
    beforeEach(^{
        COSetDefaultQueue(concurrentQueue());
    });

    describe(@"Basics", ^{
        it(@"should run composite operation", ^{
            __block int count = 0;
            __block BOOL isFinished = NO;
            __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

            COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

            [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                [compositeOperation operationWithBlock:^(COOperation *cao) {
                    asynchronousJob(^{
                        count = count + 1;

                        [[theValue(firstJobIsDone) should] beNo];
                        [[theValue(secondJobIsDone) should] beNo];
                        [[theValue(thirdJobIsDone) should] beNo];

                        [[theValue(count) should] equal:@(1)];

                        firstJobIsDone = YES;
                        [cao finish];
                    });
                }];

                [compositeOperation operationWithBlock:^(COOperation *cao) {
                    asynchronousJob(^{
                        count = count + 1;

                        [[theValue(firstJobIsDone) should] beYes];
                        [[theValue(secondJobIsDone) should] beNo];
                        [[theValue(thirdJobIsDone) should] beNo];

                        [[theValue(count) should] equal:@(2)];

                        secondJobIsDone = YES;

                        [cao finish];
                    });
                }];

                [compositeOperation operationWithBlock:^(COOperation *cao) {
                    asynchronousJob(^{
                        count = count + 1;

                        [[theValue(firstJobIsDone) should] beYes];
                        [[theValue(secondJobIsDone) should] beYes];
                        [[theValue(thirdJobIsDone) should] beNo];

                        [[theValue(count) should] equal:@(3)];

                        isFinished = YES;
                        [cao finish];
                    });
                }];
            } completionHandler:nil cancellationHandler:nil];
            
            while (isFinished == NO);
            
            [[theValue(count) should] equal:@(3)];
        });
    });

    describe(@"-[COCompositeOperation operationInQueue:withBlock:]", ^{
        it(@"", ^{
            __block int count = 0;
            __block BOOL isFinished = NO;
            __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

            COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

            [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *cao) {
                    count = count + 1;

                    [[theValue(firstJobIsDone) should] beNo];
                    [[theValue(secondJobIsDone) should] beNo];
                    [[theValue(thirdJobIsDone) should] beNo];

                    [[theValue(count) should] equal:@(1)];

                    firstJobIsDone = YES;
                    [cao finish];
                }];

                [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *cao) {
                    count = count + 1;

                    [[theValue(firstJobIsDone) should] beYes];
                    [[theValue(secondJobIsDone) should] beNo];
                    [[theValue(thirdJobIsDone) should] beNo];


                    [[theValue(count) should] equal:@(2)];

                    secondJobIsDone = YES;

                    [cao finish];
                }];

                [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *cao) {
                    count = count + 1;

                    [[theValue(firstJobIsDone) should] beYes];
                    [[theValue(secondJobIsDone) should] beYes];
                    [[theValue(thirdJobIsDone) should] beNo];


                    [[theValue(count) should] equal:@(3)];

                    isFinished = YES;
                    [cao finish];
                }];
            } completionHandler:nil cancellationHandler:nil];
            
            while (!isFinished);
            
            [[theValue(count) should] equal:@(3)];
        });
    });

    describe(@"Running inside COOperationQueue", ^{
        it(@"", ^{
            NSMutableArray *countArr = [NSMutableArray array];
            __block BOOL isFinished = NO;

            COOperationQueue *opQueue = [COOperationQueue new];
            opQueue.queue = createQueue();

            COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

            compositeOperation.operationQueue = opQueue;
            [[theValue(opQueue.pendingOperations.count) should] equal:@(0)];
            [[theValue(opQueue.runningOperations.count) should] equal:@(0)];

            [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                [[theValue(opQueue.pendingOperations.count) should] equal:@(0)];
                [[theValue(opQueue.runningOperations.count) should] equal:@(1)];

                [compositeOperation operationWithBlock:^(COOperation *cao) {
                    asynchronousJob(^{
                        @synchronized(countArr) {
                            [countArr addObject:@1];
                        }
                        [cao finish];
                    });
                }];

                [compositeOperation operationWithBlock:^(COOperation *cao) {
                    asynchronousJob(^{
                        @synchronized(countArr) {
                            [countArr addObject:@1];
                        }
                        [cao finish];
                    });
                }];

                [compositeOperation operationWithBlock:^(COOperation *cuo) {
                    @synchronized(countArr) {
                        [countArr addObject:@1];
                    }
                    isFinished = YES;
                }];
            } completionHandler:nil cancellationHandler:nil];
            
            while (!isFinished);
            
            [[theValue(countArr.count) should] equal:@(3)];
        });
    });

    describe(@"Dispatch contexts", ^{
        describe(@"Default dispatch queue", ^{
            it(@"should run operation inside CODefaultQueue()", ^{
                __block BOOL isFinished = NO;

                COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

                [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                    [compositeOperation operationWithBlock:^(COOperation *cao) {
                        [[theValue(currentQueue() == concurrentQueue()) should] beYes];

                        [cao finish];
                        isFinished = YES;
                    }];
                } completionHandler:nil cancellationHandler:nil];

                while (!isFinished);
            });

            it(@"should run operation inside CODefaultQueue()", ^{
                __block BOOL isFinished = NO;

                COSetDefaultQueue(serialQueue());

                COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

                [compositeOperation run:^(COCompositeOperation *co) {
                    [compositeOperation operationWithBlock:^(COOperation *cao) {
                        [[theValue(currentQueue() == serialQueue()) should] beYes];

                        [cao finish];
                        isFinished = YES;
                    }];
                } completionHandler:nil cancellationHandler:nil];

                while (isFinished == NO);

                COSetDefaultQueue(nil);
            });
        });
    });

    describe(@"Suspend / Resume", ^{
        it(@"Ensures that -[COCompositeOperation suspend] suspends self and inner operations.", ^{
            __block BOOL isFinished = NO;

            COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

            [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                [compositeOperation operationWithBlock:^(COOperation *operation) {
                    [[theValue(compositeOperation.isCancelled) should] beNo];

                    [compositeOperation suspend]; // Suspends composite operation and all suboperations

                    [[theValue(compositeOperation.isSuspended) should] beYes];

                    [compositeOperation.operations enumerateObjectsUsingBlock:^(COOperation *operation, NSUInteger idx, BOOL *stop) {
                        [[theValue(operation.isSuspended) should] beYes];
                    }];

                    isFinished = YES;
                }];

                [compositeOperation operationWithBlock:^(COOperation *operation) {
                    raiseShouldNotReachHere();
                }];
            } completionHandler:nil cancellationHandler:nil];
            
            while (isFinished == NO);
        });

        it(@"Ensures that -[COCompositeOperation suspend] suspends self and inner operations so that -cancel of inner operations does hot have effect.", ^{
            __block BOOL isFinished = NO;

            COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

            [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                [compositeOperation operationWithBlock:^(COOperation *operation) {
                    [compositeOperation suspend]; // Suspends composite operation and all suboperations

                    [[theValue(operation.isSuspended) should] beYes];

                    [operation cancel]; // Has no effect

                    [[theValue(operation.isSuspended) should] beYes];

                    isFinished = YES;
                }];

                [compositeOperation operationWithBlock:^(COOperation *operation) {
                    raiseShouldNotReachHere();
                }];
            } completionHandler:nil cancellationHandler:nil];
            
            while (!isFinished);
        });

        it(@"Ensures that -[COCompositeOperation[Serial] resume] runs next operation at current index if composite serial operation  was suspended in the body of successful previous sub-operation", ^{
            __block BOOL isFinished = NO;

            COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

            [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                [compositeOperation operationWithBlock:^(COOperation *operation) {
                    [compositeOperation suspend]; // Suspends composite operation and all suboperations

                    [compositeOperation.operations enumerateObjectsUsingBlock:^(COOperation *operation, NSUInteger idx, BOOL *stop) {
                        [[theValue(operation.isSuspended) should] beYes];
                    }];

                    [operation finish];

                    [[theValue(operation.isFinished) should] beYes];

                    isFinished = YES;
                }];

                [compositeOperation operationWithBlock:^(COOperation *operation) {
                    [[theValue(operation.isExecuting) should] beYes];

                    isFinished = YES;

                    [operation finish];
                }];
            } completionHandler:nil cancellationHandler:nil];
            
            while (isFinished == NO);
            
            isFinished = NO;
            
            [compositeOperation resume];
            
            while (isFinished == NO || !compositeOperation.isFinished) {}

            [[theValue(compositeOperation.isFinished) should] beYes];
        });
    });

    describe(@"reRun / awake", ^{
        it(@"Ensures that -[CompositeOperation[Serial] awake] awakes(i.e. reruns) all unfinished operations.", ^{
            NSMutableString *regString = [NSMutableString new];

            __block BOOL blockFlag = NO;
            __block NSNumber *secondOperationRunTimes = @(0);

            COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

            [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                [compositeOperation operationWithBlock:^(COOperation *o) {
                    [regString appendString:@"1"];
                    [o finish];
                }];

                [compositeOperation operationWithBlock:^(COOperation *operation) {
                    [[theValue(compositeOperation.isExecuting) should] beYes];

                    secondOperationRunTimes = @(secondOperationRunTimes.intValue + 1);

                    if ([secondOperationRunTimes isEqualToNumber:@(1)]) {
                        [operation cancel];
                    } else {
                        [regString appendString:@"2"];
                        [operation finish];
                    }
                }];

                [compositeOperation operationWithBlock:^(COOperation *o) {
                    [[theValue([regString isEqualToString:@"12"]) should] beYes];
                    [regString appendString:@"3"];

                    [o finish];
                }];
            } completionHandler:^{
                [[theValue(compositeOperation.isFinished) should] beYes];

                [[theValue([regString isEqualToString:@"123"]) should] beYes];

                blockFlag = YES;
            } cancellationHandler:^(COCompositeOperation *compositeOperation) {
                [[theValue(compositeOperation.isExecuting) should] beYes];

                [[theValue([regString isEqualToString:@"1"]) should] beYes];

                blockFlag = YES;
            }];
            
            while(blockFlag == NO);
            
            blockFlag = NO;
            
            [compositeOperation awake];
            
            while(blockFlag == NO){}
        });

        it(@"Ensures that -[COCompositeOperation awake] HAS effect on executing operations", ^{
            __block BOOL blockFlag = NO;

            COCompositeOperation *intentionallyUnfinishableCOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

            intentionallyUnfinishableCOperation.operation = ^(COCompositeOperation *co) {
                [co operationWithBlock:^(COOperation *operation) {
                    [operation finish];
                    blockFlag = YES;
                }];
            };

            intentionallyUnfinishableCOperation.state = COOperationStateExecuting;
            [[theValue(intentionallyUnfinishableCOperation.isExecuting) should] beYes];
            
            [intentionallyUnfinishableCOperation awake];
            
            while(blockFlag == NO) {};

            [[theValue(intentionallyUnfinishableCOperation.isFinished) should] beYes];
        });

        it(@"Ensures that -[COCompositeOperation awake] has no effect on finished operations", ^{
            COCompositeOperation *intentionallyUnfinishableCOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

            intentionallyUnfinishableCOperation.operation = ^(COCompositeOperation *co) {
                [co operationWithBlock:^(COOperation *operation) {
                    raiseShouldNotReachHere();
                }];
            };

            [[theValue(intentionallyUnfinishableCOperation.isReady) should] beYes];

            [intentionallyUnfinishableCOperation finish];

            [[theValue(intentionallyUnfinishableCOperation.isFinished) should] beYes];
            [intentionallyUnfinishableCOperation awake];
            [[theValue(intentionallyUnfinishableCOperation.isFinished) should] beYes];
        });

        it(@"Ensures that -[CompositeOperation[Serial] awake] has no effect on cancelled operations", ^{
            COCompositeOperation *intentionallyUnfinishableCOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

            intentionallyUnfinishableCOperation.operation = ^(COCompositeOperation *co) {
                [co operationWithBlock:^(COOperation *operation) {
                    raiseShouldNotReachHere();
                }];
            };

            [[theValue(intentionallyUnfinishableCOperation.isReady) should] beYes];
            [intentionallyUnfinishableCOperation cancel];

            [[theValue(intentionallyUnfinishableCOperation.isCancelled) should] beYes];

            [intentionallyUnfinishableCOperation awake];
            
            [[theValue(intentionallyUnfinishableCOperation.isCancelled) should] beYes];
        });
    });

    describe(@"Shared data", ^{
        it(@"should keep shared data (primitive test)", ^{
            __block BOOL isFinished = NO;

            __block NSString *data = @"1";

            COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

            [compositeOperation run:^(COCompositeOperation *co) {
                [co operationWithBlock:^(COOperation *cao) {
                    co.sharedData = data;

                    [cao finish];
                }];

                [co operationWithBlock:^(COOperation *cao) {
                    NSString *sharedData = co.sharedData;

                    [[theValue([sharedData isEqualToString:data]) should] beYes];
                    
                    isFinished = YES;
                    [cao finish];
                }];
            } completionHandler:nil cancellationHandler:nil];
            
            while (isFinished == NO);
        });
    });

    describe(@"Internals", ^{

        describe(@"!OS_OBJECT_USE_OBJC", ^{
#if !OS_OBJECT_USE_OBJC
            it(@"COCompositeOperation: assigns NSOperation's operationBlocks to its suboperations. Ensures that -[COCompositeOperation cancel] does not run and remove completionBlocks of suboperations (\"soft cancel\") when cancellationHandler is provided.", ^{
                __block BOOL isFinished = NO;

                COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

                [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                    [compositeOperation operationWithBlock:^(COOperation *operation) {
                        [operation cancel];
                    }];

                    [compositeOperation operationWithBlock:^(COOperation *operation) {
                        raiseShouldNotReachHere();
                    }];
                } completionHandler:^{
                    raiseShouldNotReachHere();
                } cancellationHandler:^(COCompositeOperation *compositeOperation) {
                    NSLog(@"%@", [compositeOperation.operations valueForKey:@"completionBlock"]);

                    for (COOperation *operation in compositeOperation.operations) {
                        [[operation.completionBlock shouldNot] beNil];
                    }
                    isFinished = YES;
                }];

                while (isFinished == NO);
            });

            it(@"Ensures that -[COCompositeOperation cancel] DOES run and remove completionBlocks of suboperations (\"soft cancel\") when cancellationHandler is not provided.", ^{
                __block BOOL isFinished = NO;

                COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

                [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                    [compositeOperation operationWithBlock:^(COOperation *operation) {
                        [compositeOperation cancel];
                        
                        isFinished = YES;
                    }];
                    
                    [compositeOperation operationWithBlock:^(COOperation *operation) {
                        raiseShouldNotReachHere();
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

    });

    describe(@"Nested composite operations", ^{
        describe(@"", ^{
            it(@"", ^{
                NSMutableArray *countArr = [NSMutableArray array];
                __block BOOL isFinished = NO;

                COCompositeOperation *cOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

                [cOperation run:^(COCompositeOperation *co) {
                    [co operationWithBlock:^(COOperation *cuo) {
                        [cuo finish];
                    }];

                    [co compositeOperation:COCompositeOperationConcurrent withBlock:^(COCompositeOperation *to1) {
                        [to1 operationWithBlock:^(COOperation *tao) {
                            @synchronized(countArr) {
                                [countArr addObject:@1];
                            }
                            [tao finish];
                        }];

                        [to1 operationWithBlock:^(COOperation *tao) {
                            @synchronized(countArr) {
                                [countArr addObject:@1];
                            }
                            [tao finish];
                        }];
                    }];
                    
                    [co operationWithBlock:^(COOperation *cuo) {
                        isFinished = YES;
                    }];
                } completionHandler:nil cancellationHandler:nil];
                
                while (isFinished == NO);
                
                [[theValue(countArr.count) should] equal:@(2)];
            });
        });

        describe(@"Cancellation semantics", ^{
            it(@"#1", ^{
                __block BOOL isFinished = NO;

                COCompositeOperation *outerCompositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

                [outerCompositeOperation run:^(COCompositeOperation *outerCompositeOperation) {
                    [outerCompositeOperation compositeOperation:COCompositeOperationConcurrent withBlock:^(COCompositeOperation *to1) {

                        [to1 operationWithBlock:^(COOperation *tao) {
                            [tao cancel];
                        }];
                    }];

                    [outerCompositeOperation operationWithBlock:^(COOperation *cuo) {
                        raiseShouldNotReachHere();
                    }];
                } completionHandler:nil cancellationHandler:^(COCompositeOperation *outerCompositeOperation){
                    COCompositeOperation *innerCompositeOperation = [outerCompositeOperation.operations objectAtIndex:0];

                    for (COOperation *operation in innerCompositeOperation.operations) {
                        [[theValue(operation.isCancelled) should] beYes];
                    }

                    for (COOperation *operation in outerCompositeOperation.operations) {
                        [[theValue(operation.isCancelled) should] beYes];
                    }
                    
                    isFinished = YES;
                }];
                
                while (!isFinished);
            });

            it(@"#2", ^{
                __block BOOL isFinished = NO;
                __block BOOL cancellationHandlerWasRun = NO;

                COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

                [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                    [compositeOperation operationWithBlock:^(COOperation *o) {
                        for (COOperation *operation in compositeOperation.operations) {
                            [[theValue(operation.isCancelled) should] beNo];
                        }

                        [[theValue(compositeOperation.isCancelled) should] beNo];

                        [o cancel];

                        [[theValue(compositeOperation.isCancelled) should] beNo];

                        for (COOperation *operation in compositeOperation.operations) {
                            [[theValue(operation.isCancelled) should] beYes];
                        }

                        isFinished = YES;
                    }];

                    [compositeOperation operationWithBlock:^(COOperation *o) {
                        raiseShouldNotReachHere();
                    }];
                } completionHandler:nil cancellationHandler:^(COCompositeOperation *compositeOperation){
                    [[theValue(compositeOperation.isCancelled) should] beNo];
                    cancellationHandlerWasRun = YES;
                }];
                
                while (!isFinished || !cancellationHandlerWasRun);

                [[theValue(isFinished) should] beYes];
                [[theValue(cancellationHandlerWasRun) should] beYes];
            });
        });
    });


});

SPEC_END

