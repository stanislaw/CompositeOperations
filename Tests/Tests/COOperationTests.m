
#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "COOperation.h"
#import "CompositeOperations.h"
#import "COOperation_Private.h"
#import "COQueues.h"

@interface COOperationTests : SenTestCase
@end

@implementation COOperationTests

// Suprisingly ensures that new COOperation instance when called with -finish, triggers its completionBlock, even when its main body is undefined.
- (void)test_NSOperationCallsCompletionBlockWhenFinished_evenWithoutActualyStartMainCalls {
    __block BOOL isFinished = NO;

    COOperation *operation = [COOperation new];

    operation.completionBlock = ^{
        isFinished = YES;
    };

    [operation finish];

    while (isFinished == NO);

    STAssertTrue(isFinished, nil);
}

- (void)test_resolveWithOperation {
    __block BOOL isFinished = NO;

    COOperation *operation = [COOperation new];
    COOperation *anotherOperation = [COOperation new];
    anotherOperation.operationBlock = ^(COOperation *operation){
        [operation finish];
    };

    operation.operationBlock = ^(COOperation *operation){
        [operation resolveWithOperation:anotherOperation];
    };

    operation.completionBlock = ^{
        isFinished = YES;
    };

    CORunOperation(operation);

    while(isFinished == NO) {}

    STAssertTrue(isFinished, nil);
    STAssertTrue(operation.isFinished, nil);
    STAssertTrue(anotherOperation.isFinished, nil);
}

- (void)test_run_completionHandler_cancellationHandler {
    __block BOOL blockFlag = NO;
    
    COOperation *operation = [COOperation new];

    [operation run:^(COOperation *operation) {
        [operation cancel];
    } completionHandler:^(id result){
        raiseShouldNotReachHere();
    } cancellationHandler:^(COOperation *operation, NSError *error) {
        STAssertTrue(operation.isCancelled, nil);

        blockFlag = YES;
    }];

    while(blockFlag == NO);

    STAssertTrue(operation.isCancelled, nil);
}

@end
