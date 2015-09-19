
#import "TestHelpers.h"
#import "TestOperations.h"
#import "TestCompositeOperations.h"

#import <CompositeOperations/COCompositeOperation.h>

SPEC_BEGIN(COCompositeOperationSpec)

describe(@"COCompositeOperation", ^{
    describe(@"-initWithSequentialTask", ^{
        it(@"should be of class COSequentialOperation", ^{
            COCompositeOperation *sequentialOperation = [[COCompositeOperation alloc] initWithSequentialTask:[SequenceOfThreeTrivialGreenOperations new]];

            [[sequentialOperation should] beKindOfClass:[COSequentialOperation class]];
        });

        it(@"should run composite operation", ^{
            dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

            COCompositeOperation *sequentialOperation = [[COCompositeOperation alloc] initWithSequentialTask:[SequenceOfThreeTrivialGreenOperations new]];

            sequentialOperation.completionBlock = ^{
                dispatch_semaphore_signal(waitSemaphore);
            };

            [sequentialOperation start];

            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            }

            [[theValue(sequentialOperation.isFinished) should] beYes];
            
            [[sequentialOperation.result should] equal:@[ @(1), @(1), @(1) ]];
        });
    });

    describe(@"-initWithOperations:inParallel:(NO)", ^{
        it(@"should be of class COSequentialOperation", ^{
            NSArray *operations = @[
                                    [OperationTriviallyReturningNull new],
                                    [OperationTriviallyReturningNull new],
                                    [OperationTriviallyReturningNull new],
                                    ];

            COCompositeOperation *sequentialOperation = [[COCompositeOperation alloc] initWithOperations:operations runInParallel:NO];

            [[sequentialOperation should] beKindOfClass:[COSequentialOperation class]];
        });

        it(@"should run composite operation", ^{
            dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

            NSArray *operations = @[
                [OperationTriviallyReturningNull new],
                [OperationTriviallyReturningNull new],
                [OperationTriviallyReturningNull new],
            ];

            COCompositeOperation *sequentialOperation = [[COCompositeOperation alloc] initWithOperations:operations runInParallel:NO];

            sequentialOperation.completionBlock = ^{
                dispatch_semaphore_signal(waitSemaphore);
            };

            [sequentialOperation start];

            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            }

            [[theValue(sequentialOperation.isFinished) should] beYes];

            [[sequentialOperation.result should] equal:[NSNull null]];
        });
    });

    describe(@"-initWithParallelTask:", ^{
        it(@"should be of class COParallelOperation", ^{
            COCompositeOperation *parallelOperation = [[COCompositeOperation alloc] initWithParallelTask:[TransactionOfThreeOperationsTriviallyReturningNull new]];

            [[parallelOperation should] beKindOfClass:[COParallelOperation class]];
        });

        it(@"should run composite operation", ^{
            dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

            COCompositeOperation *parallelOperation = [[COCompositeOperation alloc] initWithParallelTask:[TransactionOfThreeOperationsTriviallyReturningNull new]];

            parallelOperation.completionBlock = ^{
                dispatch_semaphore_signal(waitSemaphore);
            };

            [parallelOperation start];

            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            }

            [[theValue(parallelOperation.isFinished) should] beYes];
            [[theValue(parallelOperation.isCancelled) should] beNo];

            [[parallelOperation.result should] equal:@[ [NSNull null], [NSNull null], [NSNull null] ]];
            [[parallelOperation.error should] beNil];
        });
    });

    describe(@"-initWithOperations:inParallel:(YES)", ^{
        it(@"should be of class COParallelOperation", ^{
            COCompositeOperation *parallelOperation = [[COCompositeOperation alloc] initWithParallelTask:[TransactionOfThreeOperationsTriviallyReturningNull new]];

            [[parallelOperation should] beKindOfClass:[COParallelOperation class]];
        });

        it(@"should run composite operation", ^{
            dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

            NSArray *operations = @[
                                    [OperationTriviallyReturningNull new],
                                    [OperationTriviallyReturningNull new],
                                    [OperationTriviallyReturningNull new],
                                    ];

            COCompositeOperation *sequentialOperation = [[COCompositeOperation alloc] initWithOperations:operations runInParallel:YES];

            NSAssert(sequentialOperation, nil);

            sequentialOperation.completionBlock = ^{
                dispatch_semaphore_signal(waitSemaphore);
            };

            [sequentialOperation start];

            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            }
            
            [[theValue(sequentialOperation.isFinished) should] beYes];
            
            [[sequentialOperation.result should] equal:@[ [NSNull null], [NSNull null], [NSNull null] ]];
        });
    });
});

SPEC_END
