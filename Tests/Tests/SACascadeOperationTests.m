//
//  CascadeOperationsTests.m
//  CompositeOperationsTests
//
//  Created by Stanislaw Pankevich on 10/20/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "SACascadeOperation.h"
#import "SAQueues.h"

@interface SACascadeOperation (PrivateProperties)
@property (strong) NSMutableArray *operations;
@end

@implementation SACascadeOperation (PrivateProperties)
@dynamic operations;
@end

@interface CascadeOperationsTests : SenTestCase
@end

@implementation CascadeOperationsTests

- (void)testCascadeOperation {
    __block int count = 0;
    __block BOOL isFinished = NO;
    __block BOOL firstJobIsDone = NO, secondJobIsDone = NO, thirdJobIsDone = NO;

    SACascadeOperation *cOperation = [SACascadeOperation new];

    [cOperation run:^(SACascadeOperation *co) {
        [co operation:^(SAOperation *cao) {
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

        [co operation:^(SAOperation *cao) {
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

        [co operation:^(SAOperation *cao) {
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
#pragma mark SACascadeOperation: assigns NSOperation's operationBlocks to its suboperations.

#if !OS_OBJECT_USE_OBJC

// Ensures that -[SACascadeOperation cancel] does not run and remove completionBlocks of suboperations ("soft cancel") when cancellationHandler is provided.
- (void)test_cascadeOperation_cancel_does_not_run_suboperations_completionBlocks_if_cancellation_handler_is_provided {
    __block BOOL isFinished = NO;

    SACascadeOperation *cOperation = [SACascadeOperation new];

    [cOperation run:^(SACascadeOperation *co) {
        [co operation:^(SAOperation *operation) {
            [operation cancel];
        }];

        [co operation:^(SAOperation *operation) {
            raiseShouldNotReachHere();
        }];
    } completionHandler:^{
        raiseShouldNotReachHere();
    } cancellationHandler:^(SACascadeOperation *cascadeOperation) {
        for (SAOperation *operation in cascadeOperation.operations) {
            STAssertNotNil(operation.completionBlock, nil);
        }
        isFinished = YES;
    }];

    while (!isFinished);
}

// Ensures that -[SACascadeOperation cancel] DOES run and remove completionBlocks of suboperations ("soft cancel") when cancellationHandler is not provided.
- (void)test_cascadeOperation_cancel_does_run_suboperations_completionBlocks_if_cancellation_handler_is_not_provided {
    __block BOOL isFinished = NO;

    SACascadeOperation *cOperation = [SACascadeOperation new];
    
    [cOperation run:^(SACascadeOperation *co) {
        [co operation:^(SAOperation *operation) {
            [co cancel];

            isFinished = YES;
        }];

        [co operation:^(SAOperation *operation) {
            raiseShouldNotReachHere();
        }];
    } completionHandler:^{
        raiseShouldNotReachHere();
    } cancellationHandler:nil];
    
    while (!isFinished);

    for (SAOperation *operation in cOperation.operations) {
        STAssertNil(operation.completionBlock, nil);
    }
}

#endif

#pragma mark
#pragma mark Suspend / Resume

// Ensures that -[SACascadeOperation suspend] suspends self and inner operations.

- (void)testCascadeOperation_suspend_suspends_self_and_inner_operations {
    __block BOOL isFinished = NO;

    SACascadeOperation *cOperation = [SACascadeOperation new];

    [cOperation run:^(SACascadeOperation *cascade) {
        [cascade operation:^(SAOperation *operation) {
            STAssertFalse(cascade.isCancelled, nil);

            [cascade suspend]; // Suspends cascade and all suboperations
            
            STAssertTrue(cascade.isSuspended, nil);

            [cascade.operations enumerateObjectsUsingBlock:^(SAOperation *operation, NSUInteger idx, BOOL *stop) {
                STAssertTrue(operation.isSuspended, nil);
            }];

            isFinished = YES;
        }];

        [cascade operation:^(SAOperation *operation) {
            raiseShouldNotReachHere();
        }];
    } completionHandler:nil cancellationHandler:nil];
    
    while (!isFinished);
}

// Ensures that -[SACascadeOperation suspend] suspends self and inner operations so that -cancel of inner operations does hot have effect.

- (void)testCascadeOperation_suspend_suspends_self_and_inner_operations_so_than_cancellation_of_inner_operation_does_not_have_effect {
    __block BOOL isFinished = NO;

    SACascadeOperation *cOperation = [SACascadeOperation new];

    [cOperation run:^(SACascadeOperation *cascade) {
        [cascade operation:^(SAOperation *operation) {
            [cascade suspend]; // Suspends cascade and all suboperations

            STAssertTrue(operation.isSuspended, nil);

            [operation cancel]; // Has no effect

            STAssertTrue(operation.isSuspended, nil);

            isFinished = YES;
        }];

        [cascade operation:^(SAOperation *operation) {
            raiseShouldNotReachHere();
        }];
    } completionHandler:nil cancellationHandler:nil];
    
    while (!isFinished);
}


// Ensures that -[SACascadeOperation resume] runs next operation at current index if cascade operation was suspended in the body of successful previous sub-operation

- (void)testCascadeOperation_resume_runs_next_operation_at_current_index_if_cascade_operation_was_suspended_in_th_body_of_successful_previous_sub_operation {
    __block BOOL isFinished = NO;

    SACascadeOperation *cOperation = [SACascadeOperation new];

    [cOperation run:^(SACascadeOperation *cascade) {
        [cascade operation:^(SAOperation *operation) {
            [cascade suspend]; // Suspends cascade and all suboperations

            [cascade.operations enumerateObjectsUsingBlock:^(SAOperation *operation, NSUInteger idx, BOOL *stop) {
                STAssertTrue(operation.isSuspended, nil);
            }];

            [operation finish];

            STAssertTrue(operation.isFinished, nil);
            
            isFinished = YES;
        }];

        [cascade operation:^(SAOperation *operation) {
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

    SACascadeOperation *cOperation = [SACascadeOperation new];

    [cOperation run:^(SACascadeOperation *co) {
        [co operation:^(SAOperation *o) {
            [regString appendString:@"1"];
            [o finish];
        }];

        [co operation:^(SAOperation *operation) {
            STAssertTrue(cOperation.isExecuting, nil);

            secondOperationRunTimes = @(secondOperationRunTimes.intValue + 1);

            if ([secondOperationRunTimes isEqualToNumber:@(1)]) {
                [operation cancel];
            } else {
                [regString appendString:@"2"];
                [operation finish];
            }
        }];

        [co operation:^(SAOperation *o) {
            STAssertTrue([regString isEqualToString:@"12"], nil);
            [regString appendString:@"3"];
            
            [o finish];
        }];
    } completionHandler:^{
        STAssertTrue(cOperation.isFinished, nil);

        STAssertTrue([regString isEqualToString:@"123"], nil);

        blockFlag = YES;
    } cancellationHandler:^(SACascadeOperation *co) {
        STAssertTrue(cOperation.isExecuting, nil);

        STAssertTrue([regString isEqualToString:@"1"], nil);
        blockFlag = YES;
    }];

    while(blockFlag == NO);

    blockFlag = NO;

    [cOperation awake];

    while(blockFlag == NO){}
}

// Ensures that -[SACascadeOperation awake] HAS effect on executing operations
- (void)test_cascadeOperation_awake_has_effect_on_executing_operations {
    __block BOOL blockFlag = NO;

    SACascadeOperation *intentionallyUnfinishableCOperation = [SACascadeOperation new];

    intentionallyUnfinishableCOperation.operation = ^(SACascadeOperation *co) {
        [co operation:^(SAOperation *operation) {
            [operation finish];
            blockFlag = YES;
        }];
    };

    intentionallyUnfinishableCOperation.state = SAOperationExecutingState;
    STAssertTrue(intentionallyUnfinishableCOperation.isExecuting, nil);

    [intentionallyUnfinishableCOperation awake];

    while(blockFlag == NO) {};

    STAssertTrue(intentionallyUnfinishableCOperation.isFinished, nil);
}

// Ensures that -[SACascadeOperation awake] has no effect on finished operations
- (void)test_cascadeOperation_awake_has_no_effect_on_finished_operations {
    SACascadeOperation *intentionallyUnfinishableCOperation = [SACascadeOperation new];

    intentionallyUnfinishableCOperation.operation = ^(SACascadeOperation *co) {
        [co operation:^(SAOperation *operation) {
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
    SACascadeOperation *intentionallyUnfinishableCOperation = [SACascadeOperation new];

    intentionallyUnfinishableCOperation.operation = ^(SACascadeOperation *co) {
        [co operation:^(SAOperation *operation) {
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
    
    SACascadeOperation *cOperation = [SACascadeOperation new];

    [cOperation run:^(SACascadeOperation *co) {
        [co operation:^(SAOperation *o) {
            for (SAOperation *operation in co.operations) {
                STAssertFalse(operation.isCancelled, nil);
            }

            STAssertFalse(co.isCancelled, nil);

            [o cancel];

            STAssertFalse(co.isCancelled, nil);

            for (SAOperation *operation in co.operations) {
                STAssertTrue(operation.isCancelled, nil);
            }

            isFinished = YES;
        }];

        [co operation:^(SAOperation *o) {
            raiseShouldNotReachHere();
        }];
    } completionHandler:nil cancellationHandler:^(SACascadeOperation *co){
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

    SAOperationQueue *opQueue = [SAOperationQueue new];
    opQueue.queue = createQueue();

    SACascadeOperation *cOperation = [SACascadeOperation new];
    cOperation.operationQueue = opQueue;
    STAssertEquals((int)opQueue.pendingOperations.count, 0, nil);
    STAssertEquals((int)opQueue.runningOperations.count, 0, nil);

    [cOperation run:^(SACascadeOperation *co) {
        STAssertEquals((int)opQueue.pendingOperations.count, 0, nil);
        STAssertEquals((int)opQueue.runningOperations.count, 1, nil);

        [co operation:^(SAOperation *cao) {
            asynchronousJob(^{
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [cao finish];
            });
        }];
        
        [co operation:^(SAOperation *cao) {
            asynchronousJob(^{
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [cao finish];
            });
        }];

        [co operation:^(SAOperation *cuo) {
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

    SACascadeOperation *cOperation = [SACascadeOperation new];

    [cOperation run:^(SACascadeOperation *co) {
        [co operation:^(SAOperation *cao) {
            STAssertEquals(dispatch_get_current_queue(), concurrentQueue(), @"Expected unit operation to be run in the same queue the test is run");

            [cao finish];
            isFinished = YES;
        }];
    } completionHandler:nil cancellationHandler:nil];

    while (!isFinished);
}

- (void)test_cascadeOperation_when_default_queue_is_set_first_operation_should_pickup_original_environment {
    SASetDefaultQueue(concurrentQueue());
    
    NSString *someVar = @"pickmeup";
    
    __block BOOL isFinished = NO;

    SACascadeOperation *cOperation = [SACascadeOperation new];

    [cOperation run:^(SACascadeOperation *co) {
        [co operation:^(SAOperation *cao) {
            STAssertTrue([someVar isEqualToString:@"pickmeup"], @"Expected someVar to be picked up by first operation");
            [cao finish];
            isFinished = YES;
        }];
    } completionHandler:nil cancellationHandler:nil];

    while (!isFinished);
    SASetDefaultQueue(nil);
}

- (void)test_cascadeOperation_running_with_defaultQueue_set {
    __block BOOL isFinished = NO;

    SASetDefaultQueue(concurrentQueue());

    SACascadeOperation *cOperation = [SACascadeOperation new];

    [cOperation run:^(SACascadeOperation *co) {
        [co operation:^(SAOperation *cao) {
            STAssertEquals(dispatch_get_current_queue(), concurrentQueue(), @"Expected unit operation to be run in concurrentQueue()");

            [cao finish];
            isFinished = YES;
        }];
    } completionHandler:nil cancellationHandler:nil];
    
    while (!isFinished);

    SASetDefaultQueue(nil);
}

- (void)testCascadeOperation_sharedData {
    __block BOOL isFinished = NO;

    __block NSString *data = @"1";

    SACascadeOperation *cOperation = [SACascadeOperation new];

    [cOperation run:^(SACascadeOperation *co) {
        [co operation:^(SAOperation *cao) {
            co.sharedData = data;
            [cao finish];
        }];

        [co operation:^(SAOperation *cao) {
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

    SACascadeOperation *cOperation = [SACascadeOperation new];

    [cOperation run:^(SACascadeOperation *co) {
        [co operationInQueue:concurrentQueue() operation:^(SAOperation *cao) {
            count = count + 1;

            STAssertFalse(firstJobIsDone, @"Expected firstJobIsDone to be NO");
            STAssertFalse(secondJobIsDone, @"Expected secondJobIsDone to be NO");
            STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

            STAssertEquals((int)count, 1, @"Expected count to be equal 1 inside the first operation");

            firstJobIsDone = YES;
            [cao finish];
        }];

        [co operationInQueue:concurrentQueue() operation:^(SAOperation *cao) {
            count = count + 1;

            STAssertTrue(firstJobIsDone, @"Expected firstJobIsDone to be YES");
            STAssertFalse(secondJobIsDone, @"Expected secondJobIsDone to be NO");
            STAssertFalse(thirdJobIsDone, @"Expected thirdJobIsDone to be NO");

            STAssertEquals((int)count, 2, @"Expected count to be equal 2 inside the second operation");

            secondJobIsDone = YES;

            [cao finish];
        }];

        [co operationInQueue:concurrentQueue() operation:^(SAOperation *cao) {
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

    SACascadeOperation *cOperation = [SACascadeOperation new];

    [cOperation run:^(SACascadeOperation *co) {
        [co operation:^(SAOperation *cuo) {
            [cuo finish];
        }];

        [co transactionalOperation:^(SATransactionalOperation *to1) {

            [to1 operation:^(SAOperation *tao) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [tao finish];
            }];

            [to1 operation:^(SAOperation *tao) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }
                [tao finish];
            }];
        }];

        [co operation:^(SAOperation *cuo) {
            isFinished = YES;
        }];
    } completionHandler:nil cancellationHandler:nil];

    while (!isFinished);
    
    STAssertEquals((int)countArr.count, 2, @"Expected count to be equal 2");
}

// Ensures that if suboperation of transactional operation, that in its turn is a suboperation of a cascade operation, is cancelled, then all suboperations of transactional sub-operation and transactional operation itself are cancelled.
- (void)test_transactionalOperation_inside_cascadeOperation_cancellationHandlers {
    __block BOOL isFinished = NO;

    SACascadeOperation *cOperation = [SACascadeOperation new];

    [cOperation run:^(SACascadeOperation *co) {
        [co transactionalOperation:^(SATransactionalOperation *to1) {

            [to1 operation:^(SAOperation *tao) {
                [tao cancel];
            }];
        }];

        [co operation:^(SAOperation *cuo) {
            raiseShouldNotReachHere();
        }];
    } completionHandler:nil cancellationHandler:^(SACascadeOperation *coperation){
        SATransactionalOperation *tOperation = [coperation.operations objectAtIndex:0];
        for (SAOperation *operation in tOperation.operations) {
            STAssertTrue(operation.isCancelled, nil);
        }

        for (SAOperation *operation in coperation.operations) {
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

    SACascadeOperation *cOperation = [SACascadeOperation new];

    createQueue();
    [cOperation run:^(SACascadeOperation *co) {
        [co operation:^(SAOperation *cao) {
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

        [co operation:^(SAOperation *cao) {
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

        [co operation:^(SAOperation *cao) {
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
        
    SACascadeOperation *cOperation = [SACascadeOperation new];

    [cOperation run:^(SACascadeOperation *co) {
        [co operation:^(SAOperation *cao) {
            [cao finish];
        }];

        int loop = 100;

        while(loop-- > 0) {
            [co transactionalOperation:^(SATransactionalOperation *to1) {
                [to1 operation:^(SAOperation *tao) {
                    @synchronized(regArray) {
                        [regArray addObject:@1];
                    }

                    [tao finish];
                }];

                [to1 operation:^(SAOperation *tao) {
                    @synchronized(regArray) {
                        [regArray addObject:@1];
                    }

                    [tao finish];
                }];
            }];
        }

        loop = 20;

        while(loop-- > 0) {
            [co transactionalOperation:^(SATransactionalOperation *to1) {
                [to1 operation:^(SAOperation *tao) {
                    @synchronized(regArray) {
                        [regArray removeLastObject];
                    }
                    [tao finish];
                }];

                [to1 operation:^(SAOperation *tao) {
                    @synchronized(regArray) {
                        [regArray addObject:@1];
                    }
                    [tao finish];
                }];
            }];
        }

        [co operation:^(SAOperation *cao) {
            [cao finish];
            isFinished = YES;
        }];
    } completionHandler:nil cancellationHandler:nil];

    while (!isFinished);

    STAssertEquals((int)regArray.count, 2 * 100, nil);
}

@end
