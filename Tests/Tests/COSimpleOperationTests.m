
#import "TestHelpers.h"

#import <CompositeOperations/CompositeOperations.h>

SPEC_BEGIN(COSimpleOperationTests)

describe(@"COSimpleOperation", ^{
    describe(@"NSOperation-inherited behavior", ^{
        describe(@"-finish without -start", ^{
            it(@"triggers completion block", ^{
                __block BOOL isFinished = NO;

                COSimpleOperation *operation = [COSimpleOperation new];

                operation.completionBlock = ^{
                    isFinished = YES;
                };

                [operation finishWithResult:[NSNull null]];

                while (isFinished == NO);

                [[theValue(isFinished) should] beYes];
                [[theValue(operation.isFinished) should] beYes];
            });
        });
    });

    describe(@"-cancel", ^{
        describe(@"-cancel before start", ^{
            it(@"finish operation with default cancellation error", ^{
                COSimpleOperation *operation = [COSimpleOperation new];

                [operation cancel];

                [[theValue(operation.isCancelled) should] beYes];
                [[theValue(operation.isFinished)  should] beNo];

                [operation start];

                [[theValue(operation.isCancelled) should] beYes];
                [[theValue(operation.isFinished)  should] beYes];

                [[operation.result should] beNil];
                [[operation.error should] beNil];
            });
        });
    });

    describe(@"Incorrect State Transitions", ^{
        describe(@"called two times", ^{
            describe(@"-finish", ^{
                it(@"should raise exception", ^{
                    COSimpleOperation *operation = [COSimpleOperation new];

                    [operation finishWithResult:[NSNull null]];

                    [[theBlock(^{
                        [operation finishWithResult:[NSNull null]];
                    }) should] raiseWithName:NSInternalInconsistencyException];
                });
            });

            describe(@"finish -> reject", ^{
                it(@"should raise exception", ^{
                    COSimpleOperation *operation = [COSimpleOperation new];

                    [operation finishWithResult:[NSNull null]];

                    [[theBlock(^{
                        NSError *error = [NSError errorWithDomain:@"FOO" code:0 userInfo:nil];
                        [operation rejectWithError:error];
                    }) should] raiseWithName:NSInternalInconsistencyException];
                });
            });

            describe(@"finish -> reject", ^{
                it(@"should raise exception", ^{
                    COSimpleOperation *operation = [COSimpleOperation new];

                    NSError *error = [NSError errorWithDomain:@"FOO" code:0 userInfo:nil];
                    [operation rejectWithError:error];

                    [[theBlock(^{
                        [operation finishWithResult:[NSNull null]];
                    }) should] raiseWithName:NSInternalInconsistencyException];
                });
            });
        });
    });

    describe(@"-completion", ^{
        describe(@"Success", ^{
            it(@"should call @completion block with result", ^{
                dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

                __block id expectedResult = nil;

                COSimpleOperation *operation = [OperationTriviallyReturningNull new];

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

                COSimpleOperation *operation = [[OperationRejectingItselfWithError alloc] initWithError:givenError];

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
