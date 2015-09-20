
#import "TestHelpers.h"
#import "TestOperations.h"
#import "TestCompositeOperations.h"

SPEC_BEGIN(COCompositeOperationSpec)

describe(@"COCompositeOperation", ^{
    describe(@"-init", ^{
        it(@"should raise exception", ^{
            [[theBlock(^{
                __unused COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] init];
            }) should] raiseWithName:COGenericException];
        });
    });

    describe(@"-initWithSequence", ^{
        it(@"should be of class COSequentialOperation", ^{
            COCompositeOperation *sequentialOperation = [[COCompositeOperation alloc] initWithSequence:[Sequence_ThreeTrivialGreenOperations new]];

            [[sequentialOperation should] beKindOfClass:[COCompositeOperation class]];
        });

        it(@"should run composite operation", ^{
            dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

            COCompositeOperation *sequentialOperation = [[COCompositeOperation alloc] initWithSequence:[Sequence_ThreeTrivialGreenOperations new]];

            sequentialOperation.completionBlock = ^{
                dispatch_semaphore_signal(waitSemaphore);
            };

            [sequentialOperation start];

            waitUsingSemaphore(waitSemaphore);

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

            [[sequentialOperation should] beKindOfClass:[COCompositeOperation class]];
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

    describe(@"-initWithOperations:inParallel:(YES)", ^{
        it(@"should be of class COParallelOperation", ^{
            NSArray *operations = @[
                [OperationTriviallyReturningNull new],
                [OperationTriviallyReturningNull new],
                [OperationTriviallyReturningNull new]
            ];

            COCompositeOperation *parallelOperation = [[COCompositeOperation alloc] initWithOperations:operations runInParallel:YES];

            [[parallelOperation should] beKindOfClass:[COCompositeOperation class]];
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
