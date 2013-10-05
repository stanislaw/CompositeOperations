//
//  CascadeOperationsTests.m
//  CompositeOperationsTests
//
//  Created by Stanislaw Pankevich on 10/20/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "SACompositeOperations.h"
#import "SACascadeOperation.h"

#import "SATransactionalOperation.h"
#import "SAQueues.h"

@interface HighLoadTests : SenTestCase
@end

static int const N = 10;

@implementation HighLoadTests

- (void) test_operation_high_load {
    NSMutableArray *countArr = [NSMutableArray array];

    __block BOOL isFinished = NO;

    for (int j = 1; j <= N; j++) {
        operation(concurrentQueue(), ^(SAOperation *o) {

            @synchronized(countArr) {
                [countArr addObject:@1];
            }

            if (j == N) isFinished = YES;
            [o finish];
        });
    }

    while (!isFinished || countArr.count != N) {};
    STAssertEquals((int)countArr.count, N, [NSString stringWithFormat:@"Expected count to be equal %d", N]);
}

- (void) test_transactionalOperation_high_load {
    NSMutableArray *countArr = [NSMutableArray array];

    __block BOOL isFinished = NO;

    SATransactionalOperation *to = [SATransactionalOperation new];

    [to run:^(SATransactionalOperation *to) {
        for (int j = 1; j <= N; j++) {
            [to operation:^(SAOperation *o) {
                @synchronized(countArr) {
                    [countArr addObject:@1];
                }

                [o finish];
            }];
        }
    } completionHandler:^{
        isFinished = YES;
    } cancellationHandler:nil];

    while (!isFinished || countArr.count != N) {};
    STAssertEquals((int)countArr.count, N, [NSString stringWithFormat:@"Expected count to be equal %d", N]);
}

@end
