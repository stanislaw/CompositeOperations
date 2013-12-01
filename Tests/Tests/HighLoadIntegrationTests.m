
#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "CompositeOperations.h"
#import "COCompositeOperation.h"

#import "COQueues.h"

static int const N = 1;

SPEC_BEGIN(HighLoadSpecs)

for (int i = 0; i < N; i++) {
    describe(@"", ^{
        it(@"", ^{
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
            
            while (isFinished == NO || countArr.count != N) {};
            [[theValue(countArr.count) should] equal:@(N)];
        });

        it(@"", ^{
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
            
            while (isFinished == NO || countArr.count != N) {};
            [[theValue(countArr.count) should] equal:@(N)];
        });

        it(@"", ^{
            for (int i = 0; i < 100; i++) {
                __block int count = 0;
                __block BOOL isFinished = NO;
                __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

                COCompositeOperation *cOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

                createQueue();
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

                                    isFinished = YES;
                                    [cao finish];
                                });
                                
                            });
                            
                        });
                    }];
                } completionHandler:nil cancellationHandler:nil];
                
                while (!isFinished);
                
                [[theValue(count) should] equal:@(3)];
            }
        });

        it(@"", ^{
            for (int i = 0; i < 10; i++) {
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
                
                while (isFinished == NO) {};
                
                [[theValue(regArray.count) should] equal:@(2 * N)];
            }
        });

    });
}

SPEC_END
