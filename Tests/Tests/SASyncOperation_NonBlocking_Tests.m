//
//  CascadeOperationsTests.m
//  CompositeOperationsTests
//
//  Created by Stanislaw Pankevich on 10/20/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "TestHelpers.h"

#import "SASyncOperation.h"
#import "SACompositeOperations.h"
#import "SAQueues.h"

@interface SyncOperations_NonBlocking_Tests : SenTestCase
@end

@implementation SyncOperations_NonBlocking_Tests

- (void)test_syncOperation_called_from_main_queue_does_not_block_main_queue {
    __block int count = 0;
    
    syncOperation(^(SASyncOperation *so1) {
        count++;
        syncOperation(^(SASyncOperation *so2) {
            count++;
            syncOperation(^(SASyncOperation *so3) {
                count++;
                [so3 finish];
            });
            [so2 finish];
        });
        [so1 finish];
    });
    STAssertEquals(count, 3, @"Expected count to be equal 3");
}

- (void)test_syncOperation_called_from_main_queue_does_not_block_dispatch_async_to_main_queue {
    __block int count = 0;

    syncOperation(^(SASyncOperation *so1) {
        count++;
        dispatch_async(dispatch_get_main_queue(), ^{
            count++;
            [so1 finish];
            count++;
        });
    });
    STAssertEquals(count, 3, @"Expected count to be equal 3");
}

- (void)test_syncOperation_in_main_queue_does_not_block_dispatch_async_to_main_queue {
    __block int count = 0;

    syncOperation(dispatch_get_main_queue(), ^(SASyncOperation *so1) {
        count++;
        dispatch_async(dispatch_get_main_queue(), ^{
            count++;
            [so1 finish];
            count++;
        });
    });
    STAssertEquals(count, 3, @"Expected count to be equal 3");
}


- (void)test_syncOperation_does_not_block_non_main_serial_queue {
    __block int count = 0;
    dispatch_queue_t queue = dispatch_queue_create("queue", 0);

    dispatch_sync(queue, ^{
        syncOperation(^(SASyncOperation *so1) {
            count++;
            syncOperation(^(SASyncOperation *so2) {
                count++;
                syncOperation(^(SASyncOperation *so3) {
                    count++;
                    [so3 finish];
                });

                [so2 finish];
            });
            [so1 finish];
        });
    });
    STAssertEquals(count, 3, @"Expected count to be equal 3");
}

@end
