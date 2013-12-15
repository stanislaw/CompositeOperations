
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
            __block int count = 0;
            __block BOOL isFinished = NO;
            __block BOOL completionBlockWasRun = NO;

            __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

            COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

            [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                [compositeOperation operationWithBlock:^(COOperation *cao) {
                    asynchronousJob(^{
                        NSLog(@"RX 1");
                        count = count + 1;

                        [[theValue(firstJobIsDone) should] beNo];
                        [[theValue(secondJobIsDone) should] beNo];
                        [[theValue(thirdJobIsDone) should] beNo];

                        [[theValue(count) should] equal:@(1)];

                        firstJobIsDone = YES;

                        [cao finish];

                        for (COOperation *op in compositeOperation.dependencies) {
                            NSLog(@"lala %@", op.dependencies);
                        }
                    });
                }];

                [compositeOperation operationWithBlock:^(COOperation *cao) {
                    asynchronousJob(^{
                        NSLog(@"RX 2");
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
                        NSLog(@"RX 3");
                        count = count + 1;

                        [[theValue(firstJobIsDone) should] beYes];
                        [[theValue(secondJobIsDone) should] beYes];
                        [[theValue(thirdJobIsDone) should] beNo];

                        [[theValue(count) should] equal:@(3)];

                        isFinished = YES;
                        [cao finish];
                    });
                }];
            } completionHandler:^(id result){
                completionBlockWasRun = YES;
            } cancellationHandler:nil];
            
            while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, NO);
            
            [[theValue(count) should] equal:@(3)];
            [[theValue(completionBlockWasRun) should] beYes];
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
            
            while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, NO);

            [[theValue(count) should] equal:@(3)];
        });
    });

    describe(@"Dispatch contexts", ^{
        describe(@"Default dispatch queue", ^{
            it(@"should run operation inside CODefaultQueue()", ^{
                __block BOOL isFinished = NO;
                COSetDefaultQueue(concurrentQueue());

                COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

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

    describe(@"Cancellation", ^{
        describe(@"First operation is cancelled (-cancel)", ^{
            it(@"should propagate cancellation on all operations", ^{
                for (int i = 0; i < 1; i++) {
                __block BOOL isFinished = NO;

                COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

                [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                    [compositeOperation operationWithBlock:^(COOperation *operation) {
                        [operation cancel];
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

                    for (COOperation *operation in compositeOperation.internalDependencies) {
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

                [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                    [compositeOperation operationWithBlock:^(COOperation *operation) {
                        [operation cancelWithError:error];
                    }];

                    [compositeOperation operationWithBlock:^(COOperation *operation) {
                        [operation finish];
                    }];

                    [compositeOperation operationWithBlock:^(COOperation *operation) {
                        [operation finish];
                    }];
                } completionHandler:^(id result){
                    raiseShouldNotReachHere();
                } cancellationHandler:^(COCompositeOperation *compositeOperation, NSError *_error) {
                    [[theValue([_error isEqual:error]) should] beYes];
                    
                    for (COOperation *operation in compositeOperation.internalDependencies) {
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
});

SPEC_END

