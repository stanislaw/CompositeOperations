
#import "TestHelpers.h"
#import "TestOperations.h"
#import "TestCompositeOperations.h"

#import "CompositeOperations.h"

SPEC_BEGIN(COCompositeOperationsSpec)

describe(@"Composite Operations tests", ^{

    it(@"should run composite operation", ^{
        dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

        NSArray *operations = @[
            [SequentialCompositeOperationTrivialGreen new],
            [SequentialCompositeOperationTrivialGreen new],
            [SequentialCompositeOperationTrivialGreen new]
        ];

        COParallelCompositeOperation *parallelOperation = [[COParallelCompositeOperation alloc] initWithOperations:operations];

        parallelOperation.completionBlock = ^{
            dispatch_semaphore_signal(waitSemaphore);
        };

        [parallelOperation start];

        while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
        }

        [[theValue(parallelOperation.isFinished) should] beYes];

        NSArray *expectedResult = @[
            @[ @(1), @(1), @(1) ],
            @[ @(1), @(1), @(1) ],
            @[ @(1), @(1), @(1) ]
        ];

        [[parallelOperation.result should] equal:expectedResult];
    });
});

SPEC_END