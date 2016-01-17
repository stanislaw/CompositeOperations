
#import "TestHelpers.h"
#import "TestOperations.h"
#import "TestSequences.h"

#import "__COSequentialOperation.h"

SPEC_BEGIN(__COSequentialOperationSpec)

describe(@"__COSequentialOperationSpec", ^{

    describe(@"-initWithSequence:", ^{
        it(@"should run composite operation", ^{
            __COSequentialOperation *sequentialOperation = [[__COSequentialOperation alloc] initWithSequence:[Sequence_ThreeTrivialGreenOperations new]];

            waitForCompletion(^(void(^done)(void)) {
                sequentialOperation.completionBlock = ^{
                    done();
                };

                [sequentialOperation start];
            });

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
                __COSequentialOperation *sequentialOperation = [[__COSequentialOperation alloc] initWithSequence:[Sequence_FirstOperationRejects new]];

                waitForCompletion(^(void(^done)(void)) {
                    sequentialOperation.completionBlock = ^{
                        done();
                    };

                    [sequentialOperation start];
                });

                [[theValue(sequentialOperation.isFinished) should] beYes];

                [[sequentialOperation.result should] beNil];
                [[sequentialOperation.error shouldNot] beNil];

                [[sequentialOperation.error.firstObject should] beKindOfClass:[NSError class]];
            });
        });

        describe(@"__COSequentialOperationSpec - Rejection - 3 Attempts", ^{
            it(@"should run composite operation", ^{
                __COSequentialOperation *sequentialOperation = [[__COSequentialOperation alloc] initWithSequence:[Sequence_FirstOperationRejects_3Attempts new]];

                waitForCompletion(^(void(^done)(void)) {
                    sequentialOperation.completionBlock = ^{
                        done();
                    };

                    [sequentialOperation start];
                });

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
});

SPEC_END
