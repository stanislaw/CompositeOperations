
#import "TestHelpers.h"

#import "COOperation.h"
#import "CompositeOperations.h"
#import "COOperation_Private.h"

SPEC_BEGIN(COOperationTests)

describe(@"COOperationTests", ^{
    // Suprisingly ensures that new COOperation instance when called with -finish, triggers its completionBlock, even when its main body is undefined.
    it(@"", ^{
        __block BOOL isFinished = NO;

        COOperation *operation = [COOperation new];

        operation.completionBlock = ^{
            isFinished = YES;
        };

        [operation finish];

        while (isFinished == NO);

        [[theValue(isFinished) should] beYes];
    });

    describe(@"NSOperation roots", ^{
        describe(@"-cancel", ^{
            it(@"...", ^{
                COOperation *operation = [COOperation new];

                [operation cancel];

                [[theValue(operation.isCancelled) should] beYes];
                [[theValue(operation.isFinished)  should] beNo];

                [operation start];

                [[theValue(operation.isCancelled) should] beYes];
                [[theValue(operation.isFinished)  should] beYes];
            });
        });
    });
});

SPEC_END

