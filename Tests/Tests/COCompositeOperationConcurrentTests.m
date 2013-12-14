
#import <SenTestingKit/SenTestingKit.h>
#import "TestHelpers.h"

#import "COCompositeOperation.h"
#import "COQueues.h"
#import "COOperation_Private.h"

#import "COOperationQueue.h"

SPEC_BEGIN(COCompositeOperationConcurrentSpec)

describe(@"COCompositeOperationConcurrentSpec", ^{

    it(@"", ^{
        __block BOOL isFinished = NO;

        NSMutableArray *countArr = [NSMutableArray array];

        __block NSMutableString *accResult = [NSMutableString string];
        COSetDefaultQueue(concurrentQueue());
        
        COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:COCompositeOperationConcurrent];;

        [compositeOperation run:^(COCompositeOperation *compositeOperation) {
            for (int i = 1; i <= 10; i++) {
                [compositeOperation operationInQueue:concurrentQueue() withBlock:^(COOperation *tao) {
                    @synchronized(countArr) {
                        [countArr addObject:@1];
                    }
                    NSString *ind = [NSString stringWithFormat:@"%d", i];
                    @synchronized(accResult) {
                        [accResult appendString:ind];
                    }

                    [tao finish];
                }];
            }
        } completionHandler:^(id result){
            isFinished = YES;
        } cancellationHandler:nil];

        while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);

        [[theValue(countArr.count) should] equal:@(10)];

        NSLog(@"%s: accResult is: %@", __PRETTY_FUNCTION__, accResult);
    });
});

SPEC_END
