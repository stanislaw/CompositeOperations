
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

    describe(@"-completion", ^{
        describe(@"Success", ^{
            it(@"should call @completion block with result", ^{
                dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

                __block id expectedResult = nil;

                COOperation *operation = [OperationTriviallyReturningNull new];

                operation.completion = ^(id result, NSError *error) {
                    expectedResult = result;

                    dispatch_semaphore_signal(waitSemaphore);
                };

                [operation start];

                while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
                }

                [[expectedResult should] equal:operation.result];
            });
        });

        describe(@"Rejection", ^{
            it(@"should call @completion block with result", ^{
                dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

                __block NSError *expectedError = nil;
                __block id expectedResult = nil;

                NSError *givenError = [NSError errorWithDomain:NSInternalInconsistencyException code:200 userInfo:nil];

                COOperation *operation = [[OperationRejectingItselfWithError alloc] initWithError:givenError];

                operation.completion = ^(id result, NSError *error) {
                    expectedResult = result;
                    expectedError = error;

                    dispatch_semaphore_signal(waitSemaphore);
                };

                [operation start];

                while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
                    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
                }

                [[expectedError should] equal:givenError];
                [[expectedResult should] beNil];
            });
        });
    });

});

SPEC_END
