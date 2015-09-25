
#import "TestHelpers.h"
#import "TestOperations.h"
#import "TestCompositeOperations.h"

#import "COSequentialOperation.h"

SPEC_BEGIN(COSequentialOperationSpec)

describe(@"COSequentialOperationSpec", ^{

    describe(@"-initWithSequence:", ^{
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

            NSArray *expectedResult = @[
                                        @[ @(1) ],
                                        @[ @(1), @(1) ],
                                        @[ @(1), @(1), @(1) ]
                                        ];

            [[sequentialOperation.result should] equal: expectedResult];
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

                [[sequentialOperation.error should] equal:@[ expectedOperationError ]];
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

                NSArray *expectedResult = @[
                    [NSNull null],
                    @[ @(1) ],
                    @[ @(1), @(1) ]
                ];

                [[sequentialOperation.result should] equal: expectedResult];
            });
        });
    });

    describe(@"-initWithOperations:", ^{
        describe(@"3 green operations", ^{
            it(@"should run composite operation", ^{
                dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

                NSArray *operations = @[
                                        [OperationTriviallyReturningNull new],
                                        [OperationTriviallyReturningNull new],
                                        [OperationTriviallyReturningNull new]
                                        ];

                COSequentialOperation *sequentialOperation = [[COSequentialOperation alloc] initWithOperations:operations];

                sequentialOperation.completionBlock = ^{
                    dispatch_semaphore_signal(waitSemaphore);
                };

                [sequentialOperation start];

                while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
                }

                [[theValue(sequentialOperation.isFinished) should] beYes];

                NSArray *expectedResult = @[
                                            [NSNull null],
                                            [NSNull null],
                                            [NSNull null]
                                            ];
                
                [[sequentialOperation.result should] equal: expectedResult];
            });
        });

        describe(@"COSequentialOperationSpec - Rejection (first operation produces error)", ^{
            it(@"should stop running after first operation", ^{
                dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

                NSArray *operations = @[
                    [OperationRejectingItself new],
                    [OperationTriviallyReturningNull new],
                ];

                COSequentialOperation *sequentialOperation = [[COSequentialOperation alloc] initWithOperations:operations];

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

                [[sequentialOperation.error should] equal:@[ expectedOperationError ] ];
            });
        });
    });
});

SPEC_END
