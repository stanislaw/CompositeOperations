
#import "TestHelpers.h"
#import "TestOperations.h"
#import "TestCompositeOperations.h"

#import <CompositeOperations/COCompositeOperation.h>

SPEC_BEGIN(COCompositeOperationSpec)

describe(@"COCompositeOperation", ^{

    it(@"should run composite operation", ^{
        dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

        COCompositeOperation *sequentialOperation = [[COCompositeOperation alloc] initWithSequentialTask:[SequenceOfThreeTrivialGreenOperations new]];

        NSAssert(sequentialOperation, nil);

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

describe(@"COCompositeOperationSpec - Rejection", ^{

    it(@"should run composite operation", ^{
        dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

        COCompositeOperation *sequentialOperation = [[COCompositeOperation alloc] initWithSequentialTask:[SequenceWithFirstOperationRejectingItself new]];

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