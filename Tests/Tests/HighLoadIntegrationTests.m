
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
            waitSemaphore = dispatch_semaphore_create(0);

            NSMutableArray *registry = [NSMutableArray array];

            for (int j = 1; j <= N; j++) {
                operation(concurrentQueue(), ^(COOperation *o) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [registry addObject:@1];

                        if (registry.count == N) {
                            dispatch_semaphore_signal(waitSemaphore);
                        }
                    });

                    [o finish];
                });
            }

            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            [[theValue(registry.count) should] equal:@(N)];
        });

        it(@"COCompositeOperation, COCompositeOperationConcurrent", ^{
            waitSemaphore = dispatch_semaphore_create(0);

            NSMutableArray *registry = [NSMutableArray array];

            COCompositeOperation *to = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];
            to.operationQueue = [[NSOperationQueue alloc] init];
            
            [to run:^(COCompositeOperation *to) {
                for (int j = 1; j <= N; j++) {
                    [to operationWithBlock:^(COOperation *o) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [registry addObject:@1];
                        });

                        [o finish];
                    }];
                }
            } completionHandler:^(id result){
                dispatch_semaphore_signal(waitSemaphore);
            } cancellationHandler:nil];
            
            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            [[theValue(registry.count) should] equal:@(N)];
        });

        it(@"COCompositeOperation, COCompositeOperationSerial", ^{
            for (int i = 0; i < 1; i++) {
                __block int count = 0;
                waitSemaphore = dispatch_semaphore_create(0);

                __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

                COCompositeOperation *cOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];
                cOperation.operationQueue = [[NSOperationQueue alloc] init];
                
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
                    dispatch_semaphore_signal(waitSemaphore);
                } cancellationHandler:nil];
                
                while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
                
                [[theValue(count) should] equal:@(3)];
            }
        });

        it(@"COCompositeOperation, mixed", ^{
            for (int i = 0; i < 1; i++) {
                int N = 10;

                NSMutableArray *regArray = [NSMutableArray new];

                __block BOOL isFinished = NO;

                COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];
                compositeOperation.operationQueue = [[NSOperationQueue alloc] init];
                
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
                
                while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
                
                [[theValue(regArray.count) should] equal:@(2 * N)];
            }
        });

    });

    describe(@"CompositeOperation[COCompositeOperationSerial] integration test", ^{
        it(@"should work", ^{
            __block BOOL isFinished = NO;
            __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

            NSMutableString *registry = [NSMutableString string];

            compositeOperation(COCompositeOperationSerial, nil, ^(COCompositeOperation *compositeOperation) {
                [compositeOperation operationWithBlock:^(COOperation *rao) {
                    asynchronousJob(^{
                        [registry appendString:@"c1"];

                        [[theValue(firstJobIsDone) should] beNo];
                        [[theValue(secondJobIsDone) should] beNo];
                        [[theValue(thirdJobIsDone) should] beNo];

                        firstJobIsDone = YES;
                        [rao finish];
                    });
                }];

                [compositeOperation operationWithBlock:^(COOperation *rao) {
                    asynchronousJob(^{
                        [registry appendString:@"c2"];

                        [[theValue(firstJobIsDone) should] beYes];
                        [[theValue(secondJobIsDone) should] beNo];
                        [[theValue(thirdJobIsDone) should] beNo];

                        secondJobIsDone = YES;

                        [rao finish];
                    });
                }];

                [compositeOperation operationWithBlock:^(COOperation *rao) {
                    asynchronousJob(^{
                        [registry appendString:@"c3"];

                        [[theValue(firstJobIsDone) should] beYes];
                        [[theValue(secondJobIsDone) should] beYes];
                        [[theValue(thirdJobIsDone) should] beNo];

                        [rao finish];
                    });
                }];

                [compositeOperation compositeOperation:COCompositeOperationSerial withBlock:^(COCompositeOperation *to) {
                    [to operationWithBlock:^(COOperation *tao) {
                        [registry appendString:@"t1"];
                        [tao finish];
                    }];

                    [to operationWithBlock:^(COOperation *tao) {
                        [registry appendString:@"t2"];
                        [tao finish];
                    }];

                    [to operationWithBlock:^(COOperation *tao) {
                        [registry appendString:@"t3"];
                        [tao finish];
                    }];
                }];

                [compositeOperation operationWithBlock:^(COOperation *cuo) {
                    [cuo finish];
                    isFinished = YES;
                }];
            }, nil, nil);
            
            while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);

            BOOL registryIsCorrect = [registry isEqualToString:@"c1c2c3t1t2t3"];
            [[theValue(registryIsCorrect) should] beYes];
        });
    });
}

SPEC_END
