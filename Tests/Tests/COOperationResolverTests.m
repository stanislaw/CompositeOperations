
#import "TestHelpers.h"

#import "COOperationResolver.h"
#import "COQueues.h"
#import "COOperation_Private.h"

SPEC_BEGIN(COOperationResolver_Specs)

describe(@"COOperationResolver", ^{
    describe(@"-awakeOperation:times:eachAfterTimeInterval:fallbackHandlerIfStillNotFinished:", ^{
        it(@"should...", ^{
            COSetDefaultQueue(concurrentQueue());

            __block BOOL blockFlag = NO;

            NSMutableString *regString = [NSMutableString string];

            COOperationResolver *opResolver = [[COOperationResolver alloc] init];

            COOperation *operation = [COOperation new];
            operation.operation = ^(COOperation *operation) {
                [regString appendString:@"1"];
                
                [opResolver awakeOperation:operation times:5 eachAfterTimeInterval:0 withAwakeBlock:^(COOperation *operation) {
                    [operation awake];
                } fallbackHandler:^{
                    [[theValue([regString isEqualToString:@"11111"]) should] beYes];

                    [[theValue(operation.isExecuting) should] beYes];

                    blockFlag = YES;
                }];
            };
            
            [operation start];
            
            while(blockFlag == NO) {}
            
            [[theValue(operation.isExecuting) should] beYes];
            [[theValue(operation.numberOfRuns) should] equal:@(5)];
        });
    });
});

SPEC_END
