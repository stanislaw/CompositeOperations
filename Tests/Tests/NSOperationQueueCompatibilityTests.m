#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "CompositeOperations.h"
#import "COCascadeOperation.h"

#import "COTransactionalOperation.h"
#import "COQueues.h"

@interface NSOperationQueueCompatibilityTests : SenTestCase
@end

@implementation NSOperationQueueCompatibilityTests

- (void)testSyncOperation_in_NSOperationQueue_basic_test {
    NSOperationQueue *opQueue = [[NSOperationQueue alloc] init];
    
    __block BOOL soOver = NO;

    COSyncOperation *syncOperation = [COSyncOperation new];

    syncOperation.operation = ^(COSyncOperation *so) {
        soOver = YES;

        dispatch_async(dispatch_get_main_queue(), ^{
            dispatch_async(createQueue(), ^{
                [so finish];
            });
        });
    };

    [opQueue addOperation:syncOperation];

    while(!soOver);
    
    STAssertTrue(soOver, @"Expected soOver to be YES");
}

- (void)test_operation_in_NSOperationQueue_basic_test {
    NSOperationQueue *opQueue = [[NSOperationQueue alloc] init];
    
    __block BOOL oOver = NO;

    COOperation *operation = [COOperation new];

    operation.operation = ^(COOperation *ao) {
        asynchronousJob(^{
            oOver = YES;
            [ao finish];
        });
    };

    [opQueue addOperation:operation];
    
    while (!oOver) {}

    STAssertTrue(oOver, @"Expected aoOver to be YES");
}

- (void)test_cascadeOperation_in_NSOperationQueue_basic_test {
    NSOperationQueue *opQueue = [[NSOperationQueue alloc] init];
    
    __block int count = 0;
    __block BOOL isFinished = NO;
    __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

    COCascadeOperation *cOperation = [COCascadeOperation new];

    cOperation.operation = ^(COCascadeOperation *co) {
        [co operation:^(COOperation *cao) {
            asynchronousJob(^{
                count = count + 1;

                STAssertFalse(firstJobIsDone, @"Expected firstJobIsDone to be NO");
                STAssertFalse(secondJobIsDone, @"Expected secondJobIsDone to be NO");
                STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

                STAssertEquals((int)count, 1, @"Expected count to be equal 1 inside the first operation");

                firstJobIsDone = YES;
                [cao finish];
            });
        }];

        [co operation:^(COOperation *cao) {
            asynchronousJob(^{
                count = count + 1;

                STAssertTrue(firstJobIsDone, @"Expected firstJobIsDone to be YES");
                STAssertFalse(secondJobIsDone, @"Expected secondJobIsDone to be NO");
                STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

                STAssertEquals((int)count, 2, @"Expected count to be equal 2 inside the second operation");

                secondJobIsDone = YES;

                [cao finish];
            });
        }];

        [co operation:^(COOperation *cao) {
            asynchronousJob(^{
                count = count + 1;

                STAssertTrue(firstJobIsDone, @"Expected firstJobIsDone to be YES");
                STAssertTrue(secondJobIsDone, @"Expected secondJobIsDone to be YES");
                STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

                STAssertEquals((int)count, 3, @"Expected count to be equal 3 inside the third operation");

                isFinished = YES;
                [cao finish];
            });
        }];
    };

    [opQueue addOperation:cOperation];
    
    while (!isFinished);
    
    STAssertEquals(count, 3, @"Expected count to be equal 3");
}

- (void)test_cascadeOperation_in_NSOperationQueue {
    NSOperationQueue *opQueue = [[NSOperationQueue alloc] init];

    __block int count = 0;
    __block BOOL isFinished = NO;
    __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

    cascadeOperation(opQueue, ^(COCascadeOperation *co) {
        [co operation:^(COOperation *cao) {
            asynchronousJob(^{
                count = count + 1;

                STAssertFalse(firstJobIsDone, @"Expected firstJobIsDone to be NO");
                STAssertFalse(secondJobIsDone, @"Expected secondJobIsDone to be NO");
                STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

                STAssertEquals((int)count, 1, @"Expected count to be equal 1 inside the first operation");

                firstJobIsDone = YES;
                [cao finish];
            });
        }];

        [co operation:^(COOperation *cao) {
            asynchronousJob(^{
                count = count + 1;

                STAssertTrue(firstJobIsDone, @"Expected firstJobIsDone to be YES");
                STAssertFalse(secondJobIsDone, @"Expected secondJobIsDone to be NO");
                STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

                STAssertEquals((int)count, 2, @"Expected count to be equal 2 inside the second operation");

                secondJobIsDone = YES;

                [cao finish];
            });
        }];

        [co operation:^(COOperation *cao) {
            asynchronousJob(^{
                count = count + 1;

                STAssertTrue(firstJobIsDone, @"Expected firstJobIsDone to be YES");
                STAssertTrue(secondJobIsDone, @"Expected secondJobIsDone to be YES");
                STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

                STAssertEquals((int)count, 3, @"Expected count to be equal 3 inside the third operation");

                isFinished = YES;
                [cao finish];
            });
        }];
    }, nil, nil);

    while (!isFinished);
    
    STAssertEquals(count, 3, @"Expected count to be equal 3");
}

- (void) test_transactionalOperation_in_NSOperationQueue_basic_test {
    __block BOOL isFinished = NO;
    NSMutableArray *countArr = [NSMutableArray array];

    NSOperationQueue *opQueue = [[NSOperationQueue alloc] init];

    COTransactionalOperation *to = [COTransactionalOperation new];

    to.operation = ^(COTransactionalOperation *to) {
        [to operationInQueue:concurrentQueue() operation:^(COOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
        [to operationInQueue:concurrentQueue() operation:^(COOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
        [to operationInQueue:concurrentQueue() operation:^(COOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
    };

    to.completionBlock = ^{
        isFinished = YES;
    };

    [opQueue addOperation:to];
    
    while (!isFinished);

    STAssertEquals((int)countArr.count, 3, @"Expected count to be equal 3");
}

- (void) test_transactionalOperation_in_NSOperationQueue {
    __block BOOL isFinished = NO;
    NSMutableArray *countArr = [NSMutableArray array];

    NSOperationQueue *opQueue = [[NSOperationQueue alloc] init];

    transactionalOperation(opQueue, ^(COTransactionalOperation *to) {
        [to operationInQueue:concurrentQueue() operation:^(COOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
        [to operationInQueue:concurrentQueue() operation:^(COOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
        [to operationInQueue:concurrentQueue() operation:^(COOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
    }, ^{
        isFinished = YES;
    }, nil);

    while (!isFinished);

    STAssertEquals((int)countArr.count, 3, @"Expected count to be equal 3");
}

@end
