
#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "CompositeOperations.h"
#import "COCompositeOperation.h"

#import "COCompositeOperation.h"
#import "COQueues.h"

#import "COOperation_Private.h"

@interface NSOperationQueueCompatibilityTests : SenTestCase
@end

@implementation NSOperationQueueCompatibilityTests

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

- (void)test_compositeOperation_in_NSOperationQueue_basic_test {
    NSOperationQueue *opQueue = [[NSOperationQueue alloc] init];
    
    __block int count = 0;
    __block BOOL isFinished = NO;
    __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

    COCompositeOperation *cOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationSerial];

    cOperation.operation = ^(COCompositeOperation *co) {
        [co operationWithBlock:^(COOperation *cao) {
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

        [co operationWithBlock:^(COOperation *cao) {
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

        [co operationWithBlock:^(COOperation *cao) {
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

- (void)test_compositeOperation_in_NSOperationQueue {
    NSOperationQueue *opQueue = [[NSOperationQueue alloc] init];

    __block int count = 0;
    __block BOOL isFinished = NO;
    __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

    compositeOperation(COCompositeOperationSerial, opQueue, ^(COCompositeOperation *co) {
        [co operationWithBlock:^(COOperation *cao) {
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

        [co operationWithBlock:^(COOperation *cao) {
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

        [co operationWithBlock:^(COOperation *cao) {
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

- (void) test_COCompositeOperationConcurrent_in_NSOperationQueue_basic_test {
    __block BOOL isFinished = NO;
    NSMutableArray *countArr = [NSMutableArray array];

    NSOperationQueue *opQueue = [[NSOperationQueue alloc] init];

    COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

    compositeOperation.operation = ^(COCompositeOperation *compositeOperation) {
        [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
        [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
        [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
    };

    compositeOperation.completionBlock = ^{
        isFinished = YES;
    };

    [opQueue addOperation:compositeOperation];
    
    while (!isFinished);

    STAssertEquals((int)countArr.count, 3, @"Expected count to be equal 3");
}

- (void) test_COCompositeOperationConcurrent_in_NSOperationQueue {
    __block BOOL isFinished = NO;
    NSMutableArray *countArr = [NSMutableArray array];

    NSOperationQueue *opQueue = [[NSOperationQueue alloc] init];

    compositeOperation(COCompositeOperationConcurrent, opQueue, ^(COCompositeOperation *to) {
        [to operationInQueue:concurrentQueue() withBlock:^(COOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
        [to operationInQueue:concurrentQueue() withBlock:^(COOperation *tao) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            [tao finish];
        }];
        [to operationInQueue:concurrentQueue() withBlock:^(COOperation *tao) {
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
