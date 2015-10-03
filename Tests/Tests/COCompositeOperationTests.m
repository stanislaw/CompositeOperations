
#import "TestHelpers.h"
#import "TestOperations.h"
#import "TestCompositeOperations.h"
#import "__COSequentialOperation.h"
#import "__COParallelOperation.h"

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
        it(@"should be of class __COSequentialOperation", ^{
            COCompositeOperation *sequentialOperation = [[COCompositeOperation alloc] initWithSequence:[Sequence_ThreeTrivialGreenOperations new]];

            [[sequentialOperation should] beKindOfClass:[__COSequentialOperation class]];
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

            NSArray *expectedResult = @[
                                        @[ @(1) ],
                                        @[ @(1), @(1) ],
                                        @[ @(1), @(1), @(1) ]
                                        ];

            [[sequentialOperation.result should] equal: expectedResult];
        });
    });

    describe(@"-initWithOperations:", ^{
        it(@"should be of class __COParallelOperation", ^{
            NSArray *operations = @[
                [OperationTriviallyReturningNull new],
                [OperationTriviallyReturningNull new],
                [OperationTriviallyReturningNull new]
            ];

            COCompositeOperation *parallelOperation = [[COCompositeOperation alloc] initWithOperations:operations];

            [[parallelOperation should] beKindOfClass:[__COParallelOperation class]];
        });

        it(@"should run composite operation", ^{
            dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

            NSArray *operations = @[
                                    [OperationTriviallyReturningNull new],
                                    [OperationTriviallyReturningNull new],
                                    [OperationTriviallyReturningNull new],
                                    ];

            COCompositeOperation *parallelOperation = [[COCompositeOperation alloc] initWithOperations:operations];

            NSAssert(parallelOperation, nil);

            parallelOperation.completionBlock = ^{
                dispatch_semaphore_signal(waitSemaphore);
            };

            [parallelOperation start];

            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            }
            
            [[theValue(parallelOperation.isFinished) should] beYes];
            
            [[parallelOperation.result should] equal:@[ [NSNull null], [NSNull null], [NSNull null] ]];
        });
    });
});

SPEC_END
