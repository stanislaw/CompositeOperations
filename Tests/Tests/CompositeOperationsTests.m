#import "TestHelpers.h"
#import "TestOperations.h"
#import "TestCompositeOperations.h"

#import <CompositeOperations/CompositeOperations.h>

SPEC_BEGIN(COCompositeOperationsSpec)

describe(@"Composite Operations tests", ^{

    it(@"should run composite operation", ^{
        dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

        COParallelOperation *parallelOperation = [[COParallelOperation alloc] initWithParallelTask:[TransactionWithThreeSequentialOperationsEachWithThreeTrivialGreenOperations new]];

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
