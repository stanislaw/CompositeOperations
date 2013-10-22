
#import <SenTestingKit/SenTestingKit.h>

#import "TestHelpers.h"

#import "COSyncOperation.h"
#import "CompositeOperations.h"
#import "COQueues.h"

@interface SyncOperations_NonBlocking_Tests : SenTestCase
@end

@implementation SyncOperations_NonBlocking_Tests

- (void)test_syncOperation_called_from_main_queue_does_not_block_main_queue {
    __block int count = 0;
    
    syncOperation(^(COSyncOperation *so1) {
        count++;
        syncOperation(^(COSyncOperation *so2) {
            count++;
            syncOperation(^(COSyncOperation *so3) {
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

    syncOperation(^(COSyncOperation *so1) {
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

    syncOperation(dispatch_get_main_queue(), ^(COSyncOperation *so1) {
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
        syncOperation(^(COSyncOperation *so1) {
            count++;
            syncOperation(^(COSyncOperation *so2) {
                count++;
                syncOperation(^(COSyncOperation *so3) {
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
