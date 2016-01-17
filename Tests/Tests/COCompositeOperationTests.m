
#import "TestHelpers.h"
#import "TestOperations.h"
#import "TestSequences.h"

#import "__COSequentialOperation.h"
#import "__COParallelOperation.h"

SPEC_BEGIN(COCompositeOperationSpec)

describe(@"COCompositeOperation", ^{
    describe(@"-init", ^{
        it(@"should raise exception", ^{
            [[theBlock(^{
                __unused COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] init];
            }) should] raiseWithName:NSGenericException];
        });
    });

    describe(@"-initWithSequence", ^{
        it(@"should be of class __COSequentialOperation", ^{
            COCompositeOperation *sequentialOperation = [[COCompositeOperation alloc] initWithSequence:[Sequence_ThreeTrivialGreenOperations new]];

            [[sequentialOperation should] beKindOfClass:[__COSequentialOperation class]];
        });

        it(@"should run composite operation", ^{
            COCompositeOperation *sequentialOperation = [[COCompositeOperation alloc] initWithSequence:[Sequence_ThreeTrivialGreenOperations new]];

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
    });

    describe(@"-initWithOperations:", ^{
        it(@"should be of class __COParallelOperation", ^{
            NSArray *operations = @[
                [OperationReturningNull new],
                [OperationReturningNull new],
                [OperationReturningNull new]
            ];

            COCompositeOperation *parallelOperation = [[COCompositeOperation alloc] initWithOperations:operations];

            [[parallelOperation should] beKindOfClass:[__COParallelOperation class]];
        });

        it(@"should run composite operation", ^{
            NSArray *operations = @[
                                    [OperationReturningNull new],
                                    [OperationReturningNull new],
                                    [OperationReturningNull new],
                                    ];

            COCompositeOperation *parallelOperation = [[COCompositeOperation alloc] initWithOperations:operations];

            NSAssert(parallelOperation, nil);

            waitForCompletion(^(void(^done)(void)) {
                parallelOperation.completionBlock = ^{
                    done();
                };

                [parallelOperation start];
            });

            [[theValue(parallelOperation.isFinished) should] beYes];
            
            [[parallelOperation.result should] equal:@[ [NSNull null], [NSNull null], [NSNull null] ]];
        });
    });
});

SPEC_END
