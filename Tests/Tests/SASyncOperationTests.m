//
//  CascadeOperationsTests.m
//  CompositeOperationsTests
//
//  Created by Stanislaw Pankevich on 10/20/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "SASyncOperation.h"
#import "TestHelpers.h"


@interface SyncOperationsTests : SenTestCase
@end

@implementation SyncOperationsTests

- (void)setUp {
}

- (void)test_syncOperation {
    __block BOOL soOver = NO;

    SASyncOperation *syncOperation = [SASyncOperation new];

    [syncOperation run:^(SASyncOperation *so) {

        dispatch_async(dispatch_get_main_queue(), ^{
            dispatch_async(createQueue(), ^{
                soOver = YES;

                [so finish];
            });
        });
    }];

    STAssertTrue(soOver, @"Expected soOver to be YES");
}

- (void)test_syncOperation_runInQueue {
    dispatch_queue_t queue = dispatch_queue_create("some queue", NULL);
    __block BOOL soOver = NO;

    SASyncOperation *syncOperation = [SASyncOperation new];

    [syncOperation runInQueue:queue operation:^(SASyncOperation *so) {
        soOver = YES;
        [so finish];
    }];

    STAssertTrue(soOver, @"Expected soOver to be YES");
}

- (void)test_syncOperation_rough_integration {
    dispatch_queue_t queue = dispatch_queue_create("some queue", NULL);

    for (int i = 0; i < 10; i++) {
        __block BOOL soOver = NO;

        SASyncOperation *syncOperation = [SASyncOperation new];

        STAssertFalse(syncOperation.isFinished, nil);

        [syncOperation runInQueue:queue operation:^(SASyncOperation *so) {
            STAssertFalse(syncOperation.isFinished, nil);

            soOver = YES;
            [so finish];
        }];

        STAssertTrue(syncOperation.isFinished, nil);
        STAssertTrue(soOver, @"Expected soOver to be YES");
    }
}

- (void)testReRunningSyncOperation {
    __block int count = 0;

    SASyncOperation *syncOperation = [SASyncOperation new];

    [syncOperation run:^(SASyncOperation *so) {
        count = count + 1;

        if (count == 1) {
            [so reRun];
        } else
            [so finish];
    }];

    STAssertEquals(count, 2, @"Expected count to equal 2");
}

@end
