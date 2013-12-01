
#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "COOperation.h"
#import "COOperationQueue.h"
#import "CompositeOperations.h"
#import "COOperation_Private.h"
#import "COQueues.h"

@interface COOperationTests : SenTestCase
@end

@implementation COOperationTests

#pragma mark
#pragma mark NSOperation's roots

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

#pragma mark
#pragma mark -[COOperation run:inQueue:]

// Ensures that -[COOperation run:inQueue:] runs its operation block in a given queue: it works for -start and -rerun also
- (void)test_run_inQueue {
    NSMutableArray *regArray = [NSMutableArray array];

    __block BOOL oOver = NO;

    operation(concurrentQueue(), ^(COOperation *o) {
        [regArray addObject:@(1)];

        STAssertEquals(currentQueue(), concurrentQueue(), nil);

        if (regArray.count == 1) {
            [o reRun];
        } else {
            oOver = YES;
            [o finish];
        }
    });

    while (!oOver) {}

    STAssertTrue(oOver, @"Expected aoOver to be YES");
}

#if !OS_OBJECT_USE_OBJC
// Ensures that -[COOperation run:inQueue:] uses NSOperation's completionBlock to retain/release dispatch_queue it runs in
- (void)test_run_inQueue_uses_completionBlock_to_retain_and_release_dispatch_queue {
    __block BOOL oOver = NO;

    COOperation *operation = [COOperation new];

    [operation runInQueue:concurrentQueue() operation:^(COOperation *o) {
        STAssertNotNil(o.completionBlock, nil);

        [o finish];

        while(operation.completionBlock != nil) {}
        STAssertNil(operation.completionBlock, nil);
        
        oOver = YES;
    }];

    while (!oOver) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);
    }

    STAssertTrue(oOver, @"Expected aoOver to be YES");
}
#endif

#pragma mark
#pragma mark -[COOperation resolveWithOperation:]

- (void)test_resolveWithOperation {
    __block BOOL isFinished = NO;

    COOperation *operation = [COOperation new];
    COOperation *anotherOperation = [COOperation new];
    anotherOperation.operation = ^(COOperation *operation){
        [operation finish];
    };

    operation.operation = ^(COOperation *operation){
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

#pragma mark


// Ensures, that -[COOperation cancel] has no effect on operations suspended when ready
- (void)test_cancel_should_not_work_on_suspended_operations {
    COOperation *operation = [COOperation new];

    operation.operation = ^(COOperation *operation){};

    STAssertTrue(operation.isReady, nil);

    [operation suspend];

    STAssertTrue(operation.isSuspended, nil);

    [operation cancel];

    STAssertFalse(operation.isCancelled, nil);
    STAssertTrue(operation.isSuspended, nil);
}

// Ensures, that -[COOperation cancel] has no effect on operations suspended when running
- (void)test_cancel_has_no_effect_on_operations_suspended_when_running {
    COOperation *operation = [COOperation new];

    STAssertTrue(operation.isReady, nil);

    operation.operation = ^(COOperation *operation){
        [operation suspend];
        STAssertTrue(operation.isSuspended, nil);

        [operation cancel];

        STAssertFalse(operation.isCancelled, nil);
        STAssertTrue(operation.isSuspended, nil);
    };
    
    [operation start];
}

// Ensures, that -[COOperation suspend] has no effect on finished operations
- (void)test_suspend_has_no_effect_on_finished_operations {
    COOperation *operation = [COOperation new];

    STAssertTrue(operation.isReady, nil);

    [operation finish];
    STAssertTrue(operation.isFinished, nil);
    
    [operation suspend];
    STAssertTrue(operation.isFinished, nil);
}

// Ensures, that -[COOperation suspend] has no effect on cancelled operations
- (void)test_suspend_has_no_effect_on_cancelled_operations {
    COOperation *operation = [COOperation new];

    STAssertTrue(operation.isReady, nil);

    [operation cancel];
    STAssertTrue(operation.isCancelled, nil);

    [operation suspend];
    STAssertTrue(operation.isCancelled, nil);
}

- (void)test_operation_reRun {
    NSMutableArray *countArr = [NSMutableArray array];

    __block BOOL oOver = NO;

    COOperation *operation = [COOperation new];

    [operation run:^(COOperation *o) {
        asynchronousJob(^{
            @synchronized(countArr) {
                [countArr addObject:@1];
            }

            if (countArr.count < 5) {
                [o reRun];
            } else {
                oOver = YES;
                [o finish];
            }
        });
    }];

    while (!oOver) {}

    STAssertEquals((int)countArr.count, 5, @"Expected count to equal 5");
}

//

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
