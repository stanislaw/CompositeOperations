//
//  CascadeOperationsTests.m
//  CompositeOperationsTests
//
//  Created by Stanislaw Pankevich on 10/20/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "COCascadeOperation.h"
#import "COQueues.h"

@interface COCascadeOperation (PrivateProperties)
@property (strong) NSMutableArray *operations;
@end

@implementation COCascadeOperation (PrivateProperties)
@dynamic operations;
@end

@interface CascadeOperationsTests : SenTestCase
@end

@implementation CascadeOperationsTests

- (void)testCascadeOperation {
    __block int count = 0;
    __block BOOL isFinished = NO;
    __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

    COCascadeOperation *cOperation = [COCascadeOperation new];

    [cOperation run:^(COCascadeOperation *co) {
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
    } completionHandler:nil cancellationHandler:nil];

    while (!isFinished);

    STAssertEquals(count, 3, @"Expected count to be equal 3");
}

#pragma mark
#pragma mark COCascadeOperation: assigns NSOperation's operationBlocks to its suboperations.

#if !OS_OBJECT_USE_OBJC

// Ensures that -[COCascadeOperation cancel] does not run and remove completionBlocks of suboperations ("soft cancel") when cancellationHandler is provided.
- (void)test_cascadeOperation_cancel_does_not_run_suboperations_completionBlocks_if_cancellation_handler_is_provided {
    __block BOOL isFinished = NO;

    COCascadeOperation *cOperation = [COCascadeOperation new];

    [cOperation run:^(COCascadeOperation *co) {
        [co operation:^(COOperation *operation) {
            [operation cancel];
        }];

        [co operation:^(COOperation *operation) {
            raiseShouldNotReachHere();
        }];
    } completionHandler:^{
        raiseShouldNotReachHere();
    } cancellationHandler:^(COCascadeOperation *cascadeOperation) {
        for (COOperation *operation in cascadeOperation.operations) {
            STAssertNotNil(operation.completionBlock, nil);
        }
        isFinished = YES;
    }];

    while (!isFinished);
}

// Ensures that -[COCascadeOperation cancel] DOES run and remove completionBlocks of suboperations ("soft cancel") when cancellationHandler is not provided.
- (void)test_cascadeOperation_cancel_does_run_suboperations_completionBlocks_if_cancellation_handler_is_not_provided {
    __block BOOL isFinished = NO;

    COCascadeOperation *cOperation = [COCascadeOperation new];
    
    [cOperation run:^(COCascadeOperation *co) {
        [co operation:^(COOperation *operation) {
            [co cancel];

            isFinished = YES;
        }];

        [co operation:^(COOperation *operation) {
            raiseShouldNotReachHere();
        }];
    } completionHandler:^{
        raiseShouldNotReachHere();
    } cancellationHandler:nil];
    
    while (!isFinished);

    for (COOperation *operation in cOperation.operations) {
        STAssertNil(operation.completionBlock, nil);
    }
}

#endif

#pragma mark
#pragma mark Suspend / Resume

// Ensures that -[COCascadeOperation suspend] suspends self and inner operations.

- (void)testCascadeOperation_suspend_suspends_self_and_inner_operations {
    __block BOOL isFinished = NO;

    COCascadeOperation *cOperation = [COCascadeOperation new];

    [cOperation run:^(COCascadeOperation *cascade) {
        [cascade operation:^(COOperation *operation) {
            STAssertFalse(cascade.isCancelled, nil);

            [cascade suspend]; // Suspends cascade and all suboperations
            
            STAssertTrue(cascade.isSuspended, nil);

            [cascade.operations enumerateObjectsUsingBlock:^(COOperation *operation, NSUInteger idx, BOOL *stop) {
                STAssertTrue(operation.isSuspended, nil);
            }];

            isFinished = YES;
        }];

        [cascade operation:^(COOperation *operation) {
            raiseShouldNotReachHere();
        }];
    } completionHandler:nil cancellationHandler:nil];
    
    while (!isFinished);
}

// Ensures that -[COCascadeOperation suspend] suspends self and inner operations so that -cancel of inner operations does hot have effect.

- (void)testCascadeOperation_suspend_suspends_self_and_inner_operations_so_than_cancellation_of_inner_operation_does_not_have_effect {
    __block BOOL isFinished = NO;

    COCascadeOperation *cOperation = [COCascadeOperation new];

    [cOperation run:^(COCascadeOperation *cascade) {
        [cascade operation:^(COOperation *operation) {
            [cascade suspend]; // Suspends cascade and all suboperations

            STAssertTrue(operation.isSuspended, nil);

            [operation cancel]; // Has no effect

            STAssertTrue(operation.isSuspended, nil);

            isFinished = YES;
        }];

        [cascade operation:^(COOperation *operation) {
            raiseShouldNotReachHere();
        }];
    } completionHandler:nil cancellationHandler:nil];
    
    while (!isFinished);
}


// Ensures that -[COCascadeOperation resume] runs next operation at current index if cascade operation was suspended in the body of successful previous sub-operation

- (void)testCascadeOperation_resume_runs_next_operation_at_current_index_if_cascade_operation_was_suspended_in_th_body_of_successful_previous_sub_operation {
    __block BOOL isFinished = NO;

    COCascadeOperation *cOperation = [COCascadeOperation new];

    [cOperation run:^(COCascadeOperation *cascade) {
        [cascade operation:^(COOperation *operation) {
            [cascade suspend]; // Suspends cascade and all suboperations

            [cascade.operations enumerateObjectsUsingBlock:^(COOperation *operation, NSUInteger idx, BOOL *stop) {
                STAssertTrue(operation.isSuspended, nil);
            }];

            [operation finish];

            STAssertTrue(operation.isFinished, nil);
            
            isFinished = YES;
        }];

        [cascade operation:^(COOperation *operation) {
            STAssertTrue(operation.isExecuting, nil);

            isFinished = YES;

            [operation finish];
        }];
    } completionHandler:nil cancellationHandler:nil];
    
    while (!isFinished);

    isFinished = NO;

    [cOperation resume];

    while (!isFinished || !cOperation.isFinished) {}

    STAssertTrue(cOperation.isFinished, nil);
}

#pragma mark
#pragma mark reRun / awake

// Ensures that -[CascadeOperation awake] awakes(i.e. reruns) all unfinished operations.

- (void)test_cascadeOperation_awake {
    NSMutableString *regString = [NSMutableString new];

    __block BOOL blockFlag = NO;
    __block NSNumber *secondOperationRunTimes = @(0);

    COCascadeOperation *cOperation = [COCascadeOperation new];

    [cOperation run:^(COCascadeOperation *co) {
        [co operation:^(COOperation *o) {
            [regString appendString:@"1"];
            [o finish];
        }];

        [co operation:^(COOperation *operation) {
            STAssertTrue(cOperation.isExecuting, nil);

            secondOperationRunTimes = @(secondOperationRunTimes.intValue + 1);

            if ([secondOperationRunTimes isEqualToNumber:@(1)]) {
                [operation cancel];
            } else {
                [regString appendString:@"2"];
                [operation finish];
            }
        }];

        [co operation:^(COOperation *o) {
            STAssertTrue([regString isEqualToString:@"12"], nil);
            [regString appendString:@"3"];
            
            [o finish];
        }];
    } completionHandler:^{
        STAssertTrue(cOperation.isFinished, nil);

        STAssertTrue([regString isEqualToString:@"123"], nil);

        blockFlag = YES;
    } cancellationHandler:^(COCascadeOperation *co) {
        STAssertTrue(cOperation.isExecuting, nil);

        STAssertTrue([regString isEqualToString:@"1"], nil);
        blockFlag = YES;
    }];

    while(blockFlag == NO);

    blockFlag = NO;

    [cOperation awake];

    while(blockFlag == NO){}
}

// Ensures that -[COCascadeOperation awake] HAS effect on executing operations
- (void)test_cascadeOperation_awake_has_effect_on_executing_operations {
    __block BOOL blockFlag = NO;

    COCascadeOperation *intentionallyUnfinishableCOperation = [COCascadeOperation new];

    intentionallyUnfinishableCOperation.operation = ^(COCascadeOperation *co) {
        [co operation:^(COOperation *operation) {
            [operation finish];
            blockFlag = YES;
        }];
    };

    intentionallyUnfinishableCOperation.state = COOperationExecutingState;
    STAssertTrue(intentionallyUnfinishableCOperation.isExecuting, nil);

    [intentionallyUnfinishableCOperation awake];

    while(blockFlag == NO) {};

    STAssertTrue(intentionallyUnfinishableCOperation.isFinished, nil);
}

// Ensures that -[COCascadeOperation awake] has no effect on finished operations
- (void)test_cascadeOperation_awake_has_no_effect_on_finished_operations {
    COCascadeOperation *intentionallyUnfinishableCOperation = [COCascadeOperation new];

    intentionallyUnfinishableCOperation.operation = ^(COCascadeOperation *co) {
        [co operation:^(COOperation *operation) {
            raiseShouldNotReachHere();
        }];
    };

    STAssertTrue(intentionallyUnfinishableCOperation.isReady, nil);
    [intentionallyUnfinishableCOperation finish];

    STAssertTrue(intentionallyUnfinishableCOperation.isFinished, nil);
    [intentionallyUnfinishableCOperation awake];
    STAssertTrue(intentionallyUnfinishableCOperation.isFinished, nil);
}

// Ensures that -[TransactionalOperation awake] has no effect on cancelled operations
- (void)test_cascadeOperation_awake_has_no_effect_on_cancelled_operations {
    COCascadeOperation *intentionallyUnfinishableCOperation = [COCascadeOperation new];

    intentionallyUnfinishableCOperation.operation = ^(COCascadeOperation *co) {
        [co operation:^(COOperation *operation) {
            raiseShouldNotReachHere();
        }];
    };

    STAssertTrue(intentionallyUnfinishableCOperation.isReady, nil);
    [intentionallyUnfinishableCOperation cancel];

    STAssertTrue(intentionallyUnfinishableCOperation.isCancelled, nil);

    [intentionallyUnfinishableCOperation awake];

    STAssertTrue(intentionallyUnfinishableCOperation.isCancelled, nil);
}

#pragma mark

- (void)testCascadeOperation_cancel_inner_operation {
    __block BOOL isFinished = NO;
    __block BOOL cancellationHandlerWasRun = NO;
    
    COCascadeOperation *cOperation = [COCascadeOperation new];

    [cOperation run:^(COCascadeOperation *co) {
        [co operation:^(COOperation *o) {
            for (COOperation *operation in co.operations) {
                STAssertFalse(operation.isCancelled, nil);
            }

            STAssertFalse(co.isCancelled, nil);

            [o cancel];

            STAssertFalse(co.isCancelled, nil);

            for (COOperation *operation in co.operations) {
                STAssertTrue(operation.isCancelled, nil);
            }

            isFinished = YES;
        }];

        [co operation:^(COOperation *o) {
            raiseShouldNotReachHere();
        }];
    } completionHandler:nil cancellationHandler:^(COCascadeOperation *co){
        STAssertFalse(co.isCancelled, nil);
        cancellationHandlerWasRun = YES;
    }];

    while (!isFinished || !cancellationHandlerWasRun);

    STAssertTrue(isFinished, nil);
    STAssertTrue(cancellationHandlerWasRun, nil);
}

- (void)test_cascadeOperationInOperationQueue {
    NSMutableArray *countArr = [NSMutableArray array];
    __block BOOL isFinished = NO;

    COOperationQueue *opQueue = [COOperationQueue new];
    opQueue.queue = createQueue();

    COCascadeOperation *cOperation = [COCascadeOperation new];
    cOperation.operationQueue = opQueue;
    STAssertEquals((int)opQueue.pendingOperations.count, 0, nil);
    STAssertEquals((int)opQueue.runningOperations.count, 0, nil);

    [cOperation run:^(COCascadeOperation *co) {
        STAssertEquals((int)opQueue.pendingOperations.count, 0, nil);
        STAssertEquals((int)opQueue.runningOperations.count, 1, nil);

        [co operation:^(COOperation *cao) {
            asynchronousJob(^{
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [cao finish];
            });
        }];
        
        [co operation:^(COOperation *cao) {
            asynchronousJob(^{
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [cao finish];
            });
        }];

        [co operation:^(COOperation *cuo) {
            @synchronized(countArr) {
                [countArr addObject:@1];
            }
            isFinished = YES;
        }];
    } completionHandler:nil cancellationHandler:nil];

    while (!isFinished);

    STAssertEquals((int)countArr.count, 3, @"Expected count to be equal 3");
}

- (void)test_cascadeOperation_running_with_defaultQueue_unset {    
    __block BOOL isFinished = NO;

    COCascadeOperation *cOperation = [COCascadeOperation new];

    [cOperation run:^(COCascadeOperation *co) {
        [co operation:^(COOperation *cao) {
            STAssertEquals(dispatch_get_current_queue(), concurrentQueue(), @"Expected unit operation to be run in the same queue the test is run");

            [cao finish];
            isFinished = YES;
        }];
    } completionHandler:nil cancellationHandler:nil];

    while (!isFinished);
}

- (void)test_cascadeOperation_when_default_queue_is_set_first_operation_should_pickup_original_environment {
    COSetDefaultQueue(concurrentQueue());
    
    NSString *someVar = @"pickmeup";
    
    __block BOOL isFinished = NO;

    COCascadeOperation *cOperation = [COCascadeOperation new];

    [cOperation run:^(COCascadeOperation *co) {
        [co operation:^(COOperation *cao) {
            STAssertTrue([someVar isEqualToString:@"pickmeup"], @"Expected someVar to be picked up by first operation");
            [cao finish];
            isFinished = YES;
        }];
    } completionHandler:nil cancellationHandler:nil];

    while (!isFinished);
    COSetDefaultQueue(nil);
}

- (void)test_cascadeOperation_running_with_defaultQueue_set {
    __block BOOL isFinished = NO;

    COSetDefaultQueue(concurrentQueue());

    COCascadeOperation *cOperation = [COCascadeOperation new];

    [cOperation run:^(COCascadeOperation *co) {
        [co operation:^(COOperation *cao) {
            STAssertEquals(dispatch_get_current_queue(), concurrentQueue(), @"Expected unit operation to be run in concurrentQueue()");

            [cao finish];
            isFinished = YES;
        }];
    } completionHandler:nil cancellationHandler:nil];
    
    while (!isFinished);

    COSetDefaultQueue(nil);
}

- (void)testCascadeOperation_sharedData {
    __block BOOL isFinished = NO;

    __block NSString *data = @"1";

    COCascadeOperation *cOperation = [COCascadeOperation new];

    [cOperation run:^(COCascadeOperation *co) {
        [co operation:^(COOperation *cao) {
            co.sharedData = data;
            [cao finish];
        }];

        [co operation:^(COOperation *cao) {
            NSString *sharedData = co.sharedData;

            STAssertTrue([sharedData isEqualToString:data], @"Expected shared data to be set in the first operation and be accessible from the second operation");

            isFinished = YES;
            [cao finish];
        }];
    } completionHandler:nil cancellationHandler:nil];
    
    while (!isFinished);
}

- (void)testCascadeOperationUsingOperationInQueue {
    __block int count = 0;
    __block BOOL isFinished = NO;
    __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

    COCascadeOperation *cOperation = [COCascadeOperation new];

    [cOperation run:^(COCascadeOperation *co) {
        [co operationInQueue:concurrentQueue() operation:^(COOperation *cao) {
            count = count + 1;

            STAssertFalse(firstJobIsDone, @"Expected firstJobIsDone to be NO");
            STAssertFalse(secondJobIsDone, @"Expected secondJobIsDone to be NO");
            STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

            STAssertEquals((int)count, 1, @"Expected count to be equal 1 inside the first operation");

            firstJobIsDone = YES;
            [cao finish];
        }];

        [co operationInQueue:concurrentQueue() operation:^(COOperation *cao) {
            count = count + 1;

            STAssertTrue(firstJobIsDone, @"Expected firstJobIsDone to be YES");
            STAssertFalse(secondJobIsDone, @"Expected secondJobIsDone to be NO");
            STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

            STAssertEquals((int)count, 2, @"Expected count to be equal 2 inside the second operation");

            secondJobIsDone = YES;

            [cao finish];
        }];

        [co operationInQueue:concurrentQueue() operation:^(COOperation *cao) {
            count = count + 1;

            STAssertTrue(firstJobIsDone, @"Expected firstJobIsDone to be YES");
            STAssertTrue(secondJobIsDone, @"Expected secondJobIsDone to be YES");
            STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

            STAssertEquals((int)count, 3, @"Expected count to be equal 3 inside the third operation");

            isFinished = YES;
            [cao finish];
        }];
    } completionHandler:nil cancellationHandler:nil];
    
    while (!isFinished);

    STAssertEquals(count, 3, @"Expected count to be equal 3");
}

- (void)test_transactionalOperation_inside_cascadeOperation {
    NSMutableArray *countArr = [NSMutableArray array];
    __block BOOL isFinished = NO;

    COCascadeOperation *cOperation = [COCascadeOperation new];

    [cOperation run:^(COCascadeOperation *co) {
        [co operation:^(COOperation *cuo) {
            [cuo finish];
        }];

        [co transactionalOperation:^(COTransactionalOperation *to1) {

            [to1 operation:^(COOperation *tao) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [tao finish];
            }];

            [to1 operation:^(COOperation *tao) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [tao finish];
            }];
        }];

        [co operation:^(COOperation *cuo) {
            isFinished = YES;
        }];
    } completionHandler:nil cancellationHandler:nil];

    while (!isFinished);
    
    STAssertEquals((int)countArr.count, 2, @"Expected count to be equal 2");
}

// Ensures that if suboperation of transactional operation, that in its turn is a suboperation of a cascade operation, is cancelled, then all suboperations of transactional sub-operation and transactional operation itself are cancelled.
- (void)test_transactionalOperation_inside_cascadeOperation_cancellationHandlers {
    __block BOOL isFinished = NO;

    COCascadeOperation *cOperation = [COCascadeOperation new];

    [cOperation run:^(COCascadeOperation *co) {
        [co transactionalOperation:^(COTransactionalOperation *to1) {

            [to1 operation:^(COOperation *tao) {
                [tao cancel];
            }];
        }];

        [co operation:^(COOperation *cuo) {
            raiseShouldNotReachHere();
        }];
    } completionHandler:nil cancellationHandler:^(COCascadeOperation *coperation){
        COTransactionalOperation *tOperation = [coperation.operations objectAtIndex:0];
        for (COOperation *operation in tOperation.operations) {
            STAssertTrue(operation.isCancelled, nil);
        }

        for (COOperation *operation in coperation.operations) {
            STAssertTrue(operation.isCancelled, nil);
        }
        
        isFinished = YES;
    }];

    while (!isFinished);    
}

- (void)testCascadeOperation_IntegrationTest {
    __block int count = 0;
    __block BOOL isFinished = NO;
    __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

    COCascadeOperation *cOperation = [COCascadeOperation new];

    createQueue();
    [cOperation run:^(COCascadeOperation *co) {
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
                asynchronousJob(^{
                    asynchronousJob(^{
                        count = count + 1;

                        STAssertTrue(firstJobIsDone, @"Expected firstJobIsDone to be YES");
                        STAssertTrue(secondJobIsDone, @"Expected secondJobIsDone to be YES");
                        STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

                        STAssertEquals((int)count, 3, @"Expected count to be equal 3 inside the third operation");
                        
                        isFinished = YES;
                        [cao finish];
                    });

                });

            });
        }];
    } completionHandler:nil cancellationHandler:nil];
    
    while (!isFinished);

    STAssertEquals(count, 3, @"Expected count to be equal 3");
}

- (void)testTransactionalOperationBeingInsideCascadeOperation_RoughIntegrationTest {
    NSMutableArray *regArray = [NSMutableArray new];
    
    __block BOOL isFinished = NO;
        
    COCascadeOperation *cOperation = [COCascadeOperation new];

    [cOperation run:^(COCascadeOperation *co) {
        [co operation:^(COOperation *cao) {
            [cao finish];
        }];

        int loop = 100;

        while(loop-- > 0) {
            [co transactionalOperation:^(COTransactionalOperation *to1) {
                [to1 operation:^(COOperation *tao) {
                    @synchronized(regArray) {
                        [regArray addObject:@1];
                    }

                    [tao finish];
                }];

                [to1 operation:^(COOperation *tao) {
                    @synchronized(regArray) {
                        [regArray addObject:@1];
                    }

                    [tao finish];
                }];
            }];
        }

        loop = 20;

        while(loop-- > 0) {
            [co transactionalOperation:^(COTransactionalOperation *to1) {
                [to1 operation:^(COOperation *tao) {
                    @synchronized(regArray) {
                        [regArray removeLastObject];
                    }
                    [tao finish];
                }];

                [to1 operation:^(COOperation *tao) {
                    @synchronized(regArray) {
                        [regArray addObject:@1];
                    }
                    [tao finish];
                }];
            }];
        }

        [co operation:^(COOperation *cao) {
            [cao finish];
            isFinished = YES;
        }];
    } completionHandler:nil cancellationHandler:nil];

    while (!isFinished);

    STAssertEquals((int)regArray.count, 2 * 100, nil);
}

@end
