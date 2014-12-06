
#import "TestHelpers.h"
#import "TestOperations.h"
#import "TestCompositeOperations.h"

#import "COSequentialOperation.h"
#import "COOperation_Private.h"

SPEC_BEGIN(COSequentialOperationSpec)

describe(@"COSequentialOperationSpec", ^{

    it(@"should run composite operation", ^{
        dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

        COSequentialOperation *sequentialOperation = [[COSequentialOperation alloc] initWithSequence:[SequenceOfThreeTrivialGreenOperations new]];

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

describe(@"COSequentialOperationSpec - Rejection", ^{

    it(@"should run composite operation", ^{
        dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

        COSequentialOperation *sequentialOperation = [[COSequentialOperation alloc] initWithSequence:[SequenceWithFirstOperationRejectingItself new]];

        sequentialOperation.completionBlock = ^{
            dispatch_semaphore_signal(waitSemaphore);
        };

        [sequentialOperation start];

        while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
        }

        [[theValue(sequentialOperation.isFinished) should] beYes];

        [[sequentialOperation.result should] beNil];
        [[sequentialOperation.error shouldNot] beNil];

        NSError *expectedOperationError = [NSError errorWithDomain:COErrorDomain code:COOperationErrorRejected userInfo:nil];
        NSError *expectedSequentialOperationError = [NSError errorWithDomain:COErrorDomain code:COOperationErrorRejected userInfo:@{ COSequentialOperationErrorKey: expectedOperationError }];

        [[sequentialOperation.error should] equal:expectedSequentialOperationError];
    });
});

SPEC_END