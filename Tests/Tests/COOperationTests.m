
#import "TestHelpers.h"

#import <CompositeOperations/CompositeOperations.h>

SPEC_BEGIN(COOperationTests)

describe(@"COOperation", ^{
    describe(@"NSOperation-inherited behavior", ^{
        describe(@"-finish without -start", ^{
            it(@"triggers completion block", ^{
                __block BOOL isFinished = NO;

                COOperation *operation = [COOperation new];

                operation.completionBlock = ^{
                    isFinished = YES;
                };

                [operation finish];

                while (isFinished == NO);

                [[theValue(isFinished) should] beYes];
                [[theValue(operation.isFinished) should] beYes];
            });
        });
    });

    describe(@"-cancel", ^{
        describe(@"-cancel before start", ^{
            it(@"finish operation with default cancellation error", ^{
                COOperation *operation = [COOperation new];

                [operation cancel];

                [[theValue(operation.isCancelled) should] beYes];
                [[theValue(operation.isFinished)  should] beNo];

                [operation start];

                [[theValue(operation.isCancelled) should] beYes];
                [[theValue(operation.isFinished)  should] beYes];

                [[operation.result should] beNil];

                NSError *expectedError = [NSError errorWithDomain:COErrorDomain code:COOperationErrorCancelled userInfo:nil];

                [[operation.error should] equal:expectedError];
            });
        });
    });

});

SPEC_END
