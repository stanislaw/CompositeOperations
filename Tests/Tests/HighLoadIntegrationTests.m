
#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "CompositeOperations.h"
#import "COCompositeOperation.h"

#import "COQueues.h"

static int const N = 1;

SPEC_BEGIN(HighLoadSpecs)

beforeEach(^{
    COSetDefaultQueue(concurrentQueue());
});

for (int i = 0; i < N; i++) {
    describe(@"HighLoadSpecs", ^{
        it(@"operation", ^{
            NSMutableArray *countArr = [NSMutableArray array];

            __block BOOL isFinished = NO;

            for (int j = 1; j <= N; j++) {
                operation(concurrentQueue(), ^(COOperation *o) {

                    @synchronized(countArr) {
                        [countArr addObject:@1];
                    }

                    [o finish];

                    if (j == N) isFinished = YES;
                });
            }

            while (isFinished == NO || countArr.count != N) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, NO);
            [[theValue(countArr.count) should] equal:@(N)];
        });

        it(@"COCompositeOperation, COCompositeOperationConcurrent", ^{
            NSMutableArray *countArr = [NSMutableArray array];

            __block BOOL isFinished = NO;

            COCompositeOperation *to = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

            [to run:^(COCompositeOperation *to) {
                for (int j = 1; j <= N; j++) {
                    [to operationWithBlock:^(COOperation *o) {
                        @synchronized(countArr) {
                            [countArr addObject:@1];
                        }

                        [o finish];
                    }];
                }
            } completionHandler:^(id result){
                isFinished = YES;
            } cancellationHandler:nil];
            
            while (isFinished == NO || countArr.count != N) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, NO);
            [[theValue(countArr.count) should] equal:@(N)];
        });

        it(@"COCompositeOperation, COCompositeOperationSerial", ^{
            for (int i = 0; i < 1; i++) {
                __block int count = 0;
                __block BOOL isFinished = NO;
                __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

                COCompositeOperation *cOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

                [cOperation run:^(COCompositeOperation *co) {
                    [co operationWithBlock:^(COOperation *cao) {
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

                    [co operationWithBlock:^(COOperation *cao) {
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

                    [co operationWithBlock:^(COOperation *cao) {
                        asynchronousJob(^{
                            asynchronousJob(^{
                                asynchronousJob(^{
                                    count = count + 1;

                                    [[theValue(firstJobIsDone) should] beYes];
                                    [[theValue(secondJobIsDone) should] beYes];
                                    [[theValue(thirdJobIsDone) should] beNo];


                                    [[theValue(count) should] equal:@(3)];

                                    [cao finish];
                                });
                                
                            });
                            
                        });
                    }];
                } completionHandler:^(id result){
                    isFinished = YES;
                } cancellationHandler:nil];
                
                while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, NO);
                
                [[theValue(count) should] equal:@(3)];
            }
        });

        it(@"COCompositeOperation, mixed", ^{
            for (int i = 0; i < 1; i++) {
                int N = 10;

                NSMutableArray *regArray = [NSMutableArray new];

                __block BOOL isFinished = NO;

                COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

                [compositeOperation run:^(COCompositeOperation *compositeOperation) {
                    [compositeOperation operationWithBlock:^(COOperation *cao) {
                        [cao finish];
                    }];

                    int loop = N;

                    while(loop-- > 0) {
                        [compositeOperation compositeOperation:COCompositeOperationConcurrent withBlock:^(COCompositeOperation *to1) {
                            [to1 operationWithBlock:^(COOperation *tao) {
                                @synchronized(regArray) {
                                    [regArray addObject:@1];
                                }

                                [tao finish];
                            }];

                            [to1 operationWithBlock:^(COOperation *tao) {
                                @synchronized(regArray) {
                                    [regArray addObject:@1];
                                }

                                [tao finish];
                            }];
                        }];
                    }

                    loop = 20;

                    while(loop-- > 0) {
                        [compositeOperation compositeOperation:COCompositeOperationConcurrent withBlock:^(COCompositeOperation *to1) {
                            [to1 operationWithBlock:^(COOperation *tao) {
                                @synchronized(regArray) {
                                    [regArray removeLastObject];
                                }
                                [tao finish];
                            }];

                            [to1 operationWithBlock:^(COOperation *tao) {
                                @synchronized(regArray) {
                                    [regArray addObject:@1];
                                }
                                [tao finish];
                            }];
                        }];
                    }

                    [compositeOperation operationWithBlock:^(COOperation *cao) {
                        [cao finish];
                    }];
                } completionHandler:^(id result){
                    isFinished = YES;
                } cancellationHandler:nil];
                
                while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, NO);
                
                [[theValue(regArray.count) should] equal:@(2 * N)];
            }
        });

    });

    describe(@"CompositeOperation[COCompositeOperationSerial] integration test", ^{
        it(@"should work", ^{
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

                        [[theValue(firstJobIsDone) should] beNo];
                        [[theValue(secondJobIsDone) should] beNo];
                        [[theValue(thirdJobIsDone) should] beNo];

                        [[theValue(countArr.count) should] equal:@(1)];

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

                        [[theValue(firstJobIsDone) should] beYes];
                        [[theValue(secondJobIsDone) should] beNo];
                        [[theValue(thirdJobIsDone) should] beNo];

                        [[theValue(countArr.count) should] equal:@(2)];

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

                        [[theValue(firstJobIsDone) should] beYes];
                        [[theValue(secondJobIsDone) should] beYes];
                        [[theValue(thirdJobIsDone) should] beNo];

                        [[theValue(countArr.count) should] equal:@(3)];

                        [rao finish];
                    });
                }];

                [compositeOperation compositeOperation:COCompositeOperationSerial withBlock:^(COCompositeOperation *to) {
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
            
            while (!isFinished) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);
            
            [[theValue(countArr.count) should] equal:@(6)];
            NSLog(@"%s: accResult is: %@", __PRETTY_FUNCTION__, accResult);
        });
    });
}

SPEC_END
