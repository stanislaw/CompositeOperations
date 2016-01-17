
#import "TestHelpers.h"
#import "TestOperations.h"
#import "TestSequences.h"
#import "__COSequentialOperation.h"
#import "__COParallelOperation.h"

SPEC_BEGIN(COSequenceSpec)

describe(@"CORetrySequence", ^{
    describe(@"Success case: first attempt succeeds", ^{
        it(@"should finish with first operation", ^{
            OperationReturningNull *operation = [OperationReturningNull new];

            CORetrySequence *sequence = [[CORetrySequence alloc] initWithOperation:operation numberOfRetries:3];

            COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithSequence:sequence];

            __block NSArray *operationResults = nil;

            waitForCompletion(^(void(^done)(void)) {
                compositeOperation.completion = ^(NSArray *results, NSArray *_) {
                    operationResults = results;

                    done();
                };

                [compositeOperation start];
            });

            [[operationResults should] equal:@[ [NSNull null] ]];
        });
    });

    describe(@"integration test", ^{
        it(@"should work as sequence for composite operation", ^{
            OperationReturningNull *operation = [OperationReturningNull new];

            CORetrySequence *sequence = [[CORetrySequence alloc] initWithOperation:operation numberOfRetries:3];

            NSOperation <COOperation> *operation1 = [sequence nextOperationAfterOperation:nil];

            [[operation1 shouldNot] beNil];

            NSOperation <COOperation> *operation2 = [sequence nextOperationAfterOperation:operation1];

            [[operation2 shouldNot] beNil];

            NSOperation <COOperation> *operation3 = [sequence nextOperationAfterOperation:operation2];

            [[operation3 shouldNot] beNil];

            NSOperation <COOperation> *operation4 = [sequence nextOperationAfterOperation:operation3];

            [[operation4 should] beNil];
        });
    });
});

describe(@"COLinearSequence", ^{
    it(@"should run composite operation", ^{
        LinearSequence_ThreeOperations_EachReturningNSNull *sequence = [[LinearSequence_ThreeOperations_EachReturningNSNull alloc] init];

        __COSequentialOperation *sequentialOperation = [[__COSequentialOperation alloc] initWithSequence:sequence];

        waitForCompletion(^(void(^done)(void)) {
            sequentialOperation.completionBlock = ^{
                done();
            };

            [sequentialOperation start];
        });

        [[theValue(sequentialOperation.isFinished) should] beYes];

        NSArray *expectedResult = @[ [NSNull null], [NSNull null], [NSNull null] ];

        [[sequentialOperation.result should] equal: expectedResult];
    });
});

SPEC_END
