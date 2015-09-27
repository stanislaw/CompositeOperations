
#import "TestHelpers.h"
#import "TestOperations.h"
#import "TestCompositeOperations.h"

#import "__COSequentialOperation.h"

SPEC_BEGIN(__COSequentialOperationSpec)

describe(@"__COSequentialOperationSpec", ^{

    describe(@"-initWithSequence:", ^{
        it(@"should run composite operation", ^{
            dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

            __COSequentialOperation *sequentialOperation = [[__COSequentialOperation alloc] initWithSequence:[Sequence_ThreeTrivialGreenOperations new]];

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

        describe(@"__COSequentialOperationSpec - Rejection", ^{
            it(@"should run composite operation", ^{
                dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

                __COSequentialOperation *sequentialOperation = [[__COSequentialOperation alloc] initWithSequence:[Sequence_FirstOperationRejects new]];

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

                NSError *expectedOperationError = [NSError errorWithDomain:COErrorDomain code:COSimpleOperationErrorRejected userInfo:nil];

                [[sequentialOperation.error should] equal:@[ expectedOperationError ]];
            });
        });

        describe(@"__COSequentialOperationSpec - Rejection - 3 Attempts", ^{
            it(@"should run composite operation", ^{
                dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

                __COSequentialOperation *sequentialOperation = [[__COSequentialOperation alloc] initWithSequence:[Sequence_FirstOperationRejects_3Attempts new]];

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

                __COSequentialOperation *sequentialOperation = [[__COSequentialOperation alloc] initWithOperations:operations];

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

        describe(@"__COSequentialOperationSpec - Rejection (first operation produces error)", ^{
            it(@"should stop running after first operation", ^{
                dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

                NSArray *operations = @[
                    [OperationRejectingItself new],
                    [OperationTriviallyReturningNull new],
                ];

                __COSequentialOperation *sequentialOperation = [[__COSequentialOperation alloc] initWithOperations:operations];

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

                NSError *expectedOperationError = [NSError errorWithDomain:COErrorDomain code:COSimpleOperationErrorRejected userInfo:nil];

                [[sequentialOperation.error should] equal:@[ expectedOperationError ] ];
            });
        });
    });
});

SPEC_END
