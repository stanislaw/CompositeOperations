
#import "TestHelpers.h"
#import "TestOperations.h"
#import "TestCompositeOperations.h"

#import "COSequentialCompositeOperation.h"
#import "COOperation_Private.h"

SPEC_BEGIN(COSequentialCompositeOperationSpec)

describe(@"COSequentialCompositeOperationSpec", ^{

    it(@"should run composite operation", ^{
        dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

        SequentialCompositeOperationTrivialGreen *sequentialOperation = [[SequentialCompositeOperationTrivialGreen alloc] init];

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

describe(@"COSequentialCompositeOperationSpec - Rejection", ^{

    it(@"should run composite operation", ^{
        dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

        SequentialCompositeOperationWithFirstOperationRejectingItself *sequentialOperation = [[SequentialCompositeOperationWithFirstOperationRejectingItself alloc] init];

        sequentialOperation.completionBlock = ^{
            dispatch_semaphore_signal(waitSemaphore);
        };

        [sequentialOperation start];

        while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
        }

        [[theValue(sequentialOperation.isFinished) should] beYes];

        [[sequentialOperation.result should] beNil];
    });
});

SPEC_END