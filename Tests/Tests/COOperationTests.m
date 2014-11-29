
#import "TestHelpers.h"

#import "COOperation.h"
#import "CompositeOperations.h"
#import "COOperation_Private.h"

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
                [[operation.error should] equal:COOperationErrorCancelled];
            });
        });
    });

});

SPEC_END

