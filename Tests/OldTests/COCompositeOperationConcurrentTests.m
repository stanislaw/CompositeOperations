
#import "TestHelpers.h"

#import "COCompositeOperation.h"
#import "COQueues.h"
#import "COOperation_Private.h"

SPEC_BEGIN(COCompositeOperationConcurrentSpec)

describe(@"COCompositeOperationConcurrent, basic spec", ^{
    it(@"should run composite operation", ^{
        waitSemaphore = dispatch_semaphore_create(0);
        int N = 10;

        NSMutableArray *checkpoints = [NSMutableArray array];

        NSSTRING_CONSTANT(CheckpointRunBlockBegins);
        NSSTRING_CONSTANT(CheckpointOperation);
        NSSTRING_CONSTANT(CheckpointCompletionHandler);

        COSetDefaultQueue(concurrentQueue());
        
        COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];;

        compositeOperation.operationQueue = [[NSOperationQueue alloc] init];

        [compositeOperation run:^(COCompositeOperation *compositeOperation) {
            [checkpoints addObject:CheckpointRunBlockBegins];

            for (int i = 1; i <= N; i++) {
                [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *tao) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [checkpoints addObject:CheckpointOperation];
                    });

                    [tao finish];
                }];
            }
        } completionHandler:^(id result){
            [checkpoints addObject:CheckpointCompletionHandler];

            dispatch_semaphore_signal(waitSemaphore);
        } cancellationHandler:nil];

        while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
        }

        [[theValue(checkpoints.count) should] equal:@(N + 2)];

        [[[checkpoints objectAtIndex:0] should] equal:CheckpointRunBlockBegins];
        [[checkpoints.lastObject should] equal:CheckpointCompletionHandler];
    });
});

describe(@"Lazy copying", ^{
    it(@"should copy composite operation", ^{
        __block COCompositeOperation *lazyCopiedOperation;

        waitSemaphore = dispatch_semaphore_create(0);

        __block BOOL completionBlockWasRun = NO;

        NSMutableArray *checkpoints = [NSMutableArray array];

        NSSTRING_CONSTANT(CheckpointRunBlockBegins);
        NSSTRING_CONSTANT(CheckpointOperation1);
        NSSTRING_CONSTANT(CheckpointOperation1_1);
        NSSTRING_CONSTANT(CheckpointOperation1_2);

        NSSTRING_CONSTANT(CheckpointOperation2);
        NSSTRING_CONSTANT(CheckpointOperation2_1);
        NSSTRING_CONSTANT(CheckpointOperation2_2);

        NSSTRING_CONSTANT(CheckpointOperation3_1);
        NSSTRING_CONSTANT(CheckpointOperation3_2);
        NSSTRING_CONSTANT(CheckpointOperation3);

        NSSTRING_CONSTANT(CheckpointCancellationHandler);
        NSSTRING_CONSTANT(CheckpointCompletionHandler);

        NSMutableArray *registry = [NSMutableArray array];

        COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];
        compositeOperation.operationQueue = [[NSOperationQueue alloc] init];

        [compositeOperation run:^(COCompositeOperation *compositeOperation) {
            [checkpoints addObject:CheckpointRunBlockBegins];

            [compositeOperation operationWithBlock:^(COOperation *operation) {
                asynchronousJob(^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [checkpoints addObject:CheckpointOperation1];

                        NSLog(@"First operation");
                    });

                    dispatch_once_and_next_time_auto(^{
                        [checkpoints addObject:CheckpointOperation1_1];

                        [operation reject];
                    }, ^{
                        [checkpoints addObject:CheckpointOperation1_2];

                        [registry addObject:@(1)];

                        [operation finish];
                    });
                });
            }];

            [compositeOperation operationWithBlock:^(COOperation *operation) {

                asynchronousJob(^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [checkpoints addObject:CheckpointOperation2];

                        NSLog(@"Second operation");
                    });

                    dispatch_once_and_next_time_auto(^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [checkpoints addObject:CheckpointOperation2_1];
                        });

                        [operation reject];
                    }, ^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [checkpoints addObject:CheckpointOperation2_2];

                            [registry addObject:@(2)];
                        });

                        [operation finish];
                    });
                });
            }];

            [compositeOperation operationWithBlock:^(COOperation *operation) {
                asynchronousJob(^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [checkpoints addObject:CheckpointOperation3];

                        NSLog(@"Third operation");
                    });

                    dispatch_once_and_next_time_auto(^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [checkpoints addObject:CheckpointOperation3_1];
                        });

                        [operation reject];
                    }, ^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [checkpoints addObject:CheckpointOperation3_2];

                            [registry addObject:@(3)];
                        });

                        [operation finish];
                    });
                });
            }];
        } completionHandler:^(id result) {
            AssertShouldNotReachHereTwice();

            dispatch_once_and_next_time_auto(^{
                [checkpoints addObject:CheckpointCompletionHandler];
            }, ^{
                abort();
            });

            completionBlockWasRun = YES;

            dispatch_semaphore_signal(waitSemaphore);

        } cancellationHandler:^(COCompositeOperation *compositeOperation, NSError *error) {
            [checkpoints addObject:CheckpointCancellationHandler];

            AssertShouldNotReachHereTwice();

            dispatch_semaphore_signal(waitSemaphore);

            lazyCopiedOperation = [compositeOperation lazyCopy];
            [lazyCopiedOperation.operationQueue addOperation:lazyCopiedOperation];
        }];

        while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
        }

        BOOL registryIsCorrect = [registry isEqual:@[]];
        [[theValue(registryIsCorrect) should] beYes];

        while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
        }

        registryIsCorrect = registry.count == 3 &&
                            [registry containsObject:@(1)] &&
                            [registry containsObject:@(2)] &&
                            [registry containsObject:@(3)];

        NSAssert(registryIsCorrect, @"Expected registry to be correct: %@", registry);

        [[theValue(registryIsCorrect) should] beYes];
        [[theValue(completionBlockWasRun) should] beYes];

        [[[checkpoints objectAtIndex:0] should] equal:CheckpointRunBlockBegins];
        [[checkpoints.lastObject should] equal:CheckpointCompletionHandler];

        [[theValue([checkpoints countForObject:CheckpointCancellationHandler]) should] equal:@(1)];

        [[theValue([checkpoints countForObject:CheckpointOperation1]) should] equal:@(2)];
        [[theValue([checkpoints countForObject:CheckpointOperation2]) should] equal:@(2)];
        [[theValue([checkpoints countForObject:CheckpointOperation3]) should] equal:@(2)];

        [[theValue([checkpoints countForObject:CheckpointOperation1_1]) should] equal:@(1)];
        [[theValue([checkpoints countForObject:CheckpointOperation1_2]) should] equal:@(1)];
        [[theValue([checkpoints countForObject:CheckpointOperation2_1]) should] equal:@(1)];
        [[theValue([checkpoints countForObject:CheckpointOperation2_2]) should] equal:@(1)];
        [[theValue([checkpoints countForObject:CheckpointOperation3_1]) should] equal:@(1)];
        [[theValue([checkpoints countForObject:CheckpointOperation3_2]) should] equal:@(1)];

    });
});

SPEC_END
