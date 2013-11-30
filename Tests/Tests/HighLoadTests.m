
#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "CompositeOperations.h"
#import "COCompositeOperation.h"

#import "COQueues.h"

@interface HighLoadTests : SenTestCase
@end

static int const N = 10;

@implementation HighLoadTests

- (void)test_operation_high_load {
    NSMutableArray *countArr = [NSMutableArray array];

    __block BOOL isFinished = NO;

    for (int j = 1; j <= N; j++) {
        operation(concurrentQueue(), ^(COOperation *o) {

            @synchronized(countArr) {
                [countArr addObject:@1];
            }

            [o finish];

            if (j == N) isFinished = YES;
        });
    }

    while (!isFinished || countArr.count != N) {};
    STAssertEquals((int)countArr.count, N, [NSString stringWithFormat:@"Expected count to be equal %d", N]);
}

- (void) test_transactionalOperation_high_load {
    NSMutableArray *countArr = [NSMutableArray array];

    __block BOOL isFinished = NO;

    COCompositeOperation *to = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];

    [to run:^(COCompositeOperation *to) {
        for (int j = 1; j <= N; j++) {
            [to operation:^(COOperation *o) {
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
