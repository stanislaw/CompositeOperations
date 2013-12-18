
#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "COCompositeOperation.h"
#import "COQueues.h"
#import "COOperation_Private.h"

SPEC_BEGIN(COCompositeOperationConcurrentSpec)

describe(@"COCompositeOperationConcurrentSpec", ^{

    it(@"", ^{
        waitSemaphore = dispatch_semaphore_create(0);
        int N = 10;

        NSMutableArray *checkpoints = [NSMutableArray array];

        COSetDefaultQueue(concurrentQueue());
        
        COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];;

        compositeOperation.operationQueue = [[NSOperationQueue alloc] init];

        [compositeOperation run:^(COCompositeOperation *compositeOperation) {
            [checkpoints addObject:@"Run block begins"];

            for (int i = 1; i <= N; i++) {
                [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *tao) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [checkpoints addObject:@"Operation"];
                    });

                    [tao finish];
                }];
            }
        } completionHandler:^(id result){
            [checkpoints addObject:@"Completion handler"];

            dispatch_semaphore_signal(waitSemaphore);
        } cancellationHandler:nil];

        while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
        }

        [[theValue(checkpoints.count) should] equal:@(N + 2)];

        [[checkpoints.firstObject should] equal:@"Run block begins"];
        [[checkpoints.lastObject should] equal:@"Completion handler"];
    });
});

SPEC_END
