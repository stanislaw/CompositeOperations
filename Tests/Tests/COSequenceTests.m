
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

            dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

            __block NSArray *operationResults = nil;
            compositeOperation.completion = ^(NSArray *results, NSArray *_) {
                operationResults = results;

                dispatch_semaphore_signal(waitSemaphore);
            };

            [compositeOperation start];

            while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
            }

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

SPEC_END
