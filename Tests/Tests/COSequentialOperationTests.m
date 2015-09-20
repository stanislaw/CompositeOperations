
#import "TestHelpers.h"
#import "TestOperations.h"
#import "TestCompositeOperations.h"

#import "COSequentialOperation.h"

SPEC_BEGIN(COSequentialOperationSpec)

describe(@"COSequentialOperationSpec", ^{

    it(@"should run composite operation", ^{
        dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

        COSequentialOperation *sequentialOperation = [[COSequentialOperation alloc] initWithSequence:[Sequence_ThreeTrivialGreenOperations new]];

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

    describe(@"COSequentialOperationSpec - Rejection", ^{
        it(@"should run composite operation", ^{
            dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

            COSequentialOperation *sequentialOperation = [[COSequentialOperation alloc] initWithSequence:[Sequence_FirstOperationRejects new]];

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
            NSError *expectedSequentialOperationError = [NSError errorWithDomain:COErrorDomain code:COOperationErrorRejected userInfo:@{ COOperationErrorKey: expectedOperationError }];
            
            [[sequentialOperation.error should] equal:expectedSequentialOperationError];
        });
    });

    describe(@"COSequentialOperationSpec - Rejection - 3 Attempts", ^{
        it(@"should run composite operation", ^{
            dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

            COSequentialOperation *sequentialOperation = [[COSequentialOperation alloc] initWithSequence:[Sequence_FirstOperationRejects_3Attempts new]];

            sequentialOperation.completionBlock = ^{
                dispatch_semaphore_signal(waitSemaphore);
            };

            [sequentialOperation start];

            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            }

            [[theValue(sequentialOperation.isFinished) should] beYes];

            [[sequentialOperation.result should] equal:@[ @(1), @(1) ]];
        });
    });
});

SPEC_END