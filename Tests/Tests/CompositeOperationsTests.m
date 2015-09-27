#import "TestHelpers.h"
#import "TestOperations.h"
#import "TestCompositeOperations.h"

#import "__COParallelOperation.h"
#import "__COSequentialOperation.h"

SPEC_BEGIN(COCompositeOperationsSpec)

describe(@"Composite Operations tests", ^{
    describe(@"Parallel operation: 3 parallel operations", ^{
        it(@"should run composite operation", ^{
            dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

            __COSequentialOperation *sequentialOperation1 = [[__COSequentialOperation alloc] initWithSequence:[Sequence_ThreeTrivialGreenOperations new]];
            __COSequentialOperation *sequentialOperation2 = [[__COSequentialOperation alloc] initWithSequence:[Sequence_ThreeTrivialGreenOperations new]];
            __COSequentialOperation *sequentialOperation3 = [[__COSequentialOperation alloc] initWithSequence:[Sequence_ThreeTrivialGreenOperations new]];

            NSArray *operations = @[
                sequentialOperation1,
                sequentialOperation2,
                sequentialOperation3
            ];

            __COParallelOperation *parallelOperation = [[__COParallelOperation alloc] initWithOperations:operations];

            parallelOperation.completionBlock = ^{
                dispatch_semaphore_signal(waitSemaphore);
            };

            [parallelOperation start];

            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            }

            [[theValue(parallelOperation.isFinished) should] beYes];

            NSArray *expectedResultOfEachOperation = @[
                @[@(1)],
                @[@(1), @(1)],
                @[@(1), @(1), @(1)]
            ];

            NSArray *expectedResult = @[
                expectedResultOfEachOperation,
                expectedResultOfEachOperation,
                expectedResultOfEachOperation
            ];

            [[parallelOperation.result should] equal:expectedResult];
        });
    });
});

SPEC_END
