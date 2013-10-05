//
//  CascadeOperationsTests.m
//  CompositeOperationsTests
//
//  Created by Stanislaw Pankevich on 10/20/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "SAOperation.h"
#import "SAOperationQueue.h"
#import "SACompositeOperations.h"

@interface SAOperationTests : SenTestCase
@end

@implementation SAOperationTests

#pragma mark
#pragma mark NSOperation's roots

// Suprisingly ensures that new SAOperation instance when called with -finish, triggers its completionBlock, even when its main body is undefined.
- (void)test_NSOperationCallsCompletionBlockWhenFinished_evenWithoutActualyStartMainCalls {
    __block BOOL flag = NO;

    SAOperation *operation = [SAOperation new];

    operation.completionBlock = ^{
        flag = YES;
    };

    [operation finish];

    while (flag == NO);

    STAssertTrue(flag, nil);
}

#pragma mark
#pragma mark -[SAOperation run:inQueue:]

// Ensures that -[SAOperation run:inQueue:] runs its operation block in a given queue: it works for -start and -rerun also
- (void)test_run_inQueue {
    NSMutableArray *regArray = [NSMutableArray array];

    __block BOOL oOver = NO;

    operation(concurrentQueue(), ^(SAOperation *o) {
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
// Ensures that -[SAOperation run:inQueue:] uses NSOperation's completionBlock to retain/release dispatch_queue it runs in
- (void)test_run_inQueue_uses_completionBlock_to_retain_and_release_dispatch_queue {
    __block BOOL oOver = NO;

    SAOperation *operation = [SAOperation new];

    [operation runInQueue:concurrentQueue() operation:^(SAOperation *o) {
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

// Ensures, that -[SAOperation cancel] has no effect on operations suspended when ready
- (void)test_cancel_should_not_work_on_suspended_operations {
    SAOperation *operation = [SAOperation new];

    operation.operation = ^(SAOperation *operation){};

    STAssertTrue(operation.isReady, nil);

    [operation suspend];

    STAssertTrue(operation.isSuspended, nil);

    [operation cancel];

    STAssertFalse(operation.isCancelled, nil);
    STAssertTrue(operation.isSuspended, nil);
}

// Ensures, that -[SAOperation cancel] has no effect on operations suspended when running
- (void)test_cancel_has_no_effect_on_operations_suspended_when_running {
    SAOperation *operation = [SAOperation new];

    STAssertTrue(operation.isReady, nil);

    operation.operation = ^(SAOperation *operation){
        [operation suspend];
        STAssertTrue(operation.isSuspended, nil);

        [operation cancel];

        STAssertFalse(operation.isCancelled, nil);
        STAssertTrue(operation.isSuspended, nil);
    };
    
    [operation start];
}

// Ensures, that -[SAOperation suspend] has no effect on finished operations
- (void)test_suspend_has_no_effect_on_finished_operations {
    SAOperation *operation = [SAOperation new];

    STAssertTrue(operation.isReady, nil);

    [operation finish];
    STAssertTrue(operation.isFinished, nil);
    
    [operation suspend];
    STAssertTrue(operation.isFinished, nil);
}

// Ensures, that -[SAOperation suspend] has no effect on cancelled operations
- (void)test_suspend_has_no_effect_on_cancelled_operations {
    SAOperation *operation = [SAOperation new];

    STAssertTrue(operation.isReady, nil);

    [operation cancel];
    STAssertTrue(operation.isCancelled, nil);

    [operation suspend];
    STAssertTrue(operation.isCancelled, nil);
}

- (void)test_operation_reRun {
    NSMutableArray *countArr = [NSMutableArray array];

    __block BOOL oOver = NO;

    SAOperation *operation = [SAOperation new];

    [operation run:^(SAOperation *o) {
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
    
    SAOperation *operation = [SAOperation new];

    [operation run:^(SAOperation *operation) {
        [operation cancel];
    } completionHandler:^{
        raiseShouldNotReachHere();
    } cancellationHandler:^{
        STAssertTrue(operation.isCancelled, nil);

        blockFlag = YES;
    }];

    while(blockFlag == NO);

    STAssertTrue(operation.isCancelled, nil);
}

@end