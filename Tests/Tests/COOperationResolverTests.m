#import "TestHelpers.h"

#import "COOperationResolver.h"
#import "COQueues.h"

@interface COOperationResolverTests : SenTestCase
@end

@implementation COOperationResolverTests

// awakeOperation:times:eachAfterTimeInterval:fallbackHandlerIfStillNotFinished:
- (void)test_awakeOperation_times_eachAfterTimeInterval_fallbackHandlerIfStillNotFinished {
    __block BOOL blockFlag = NO;
    
    NSMutableString *regString = [NSMutableString string];

    COOperationResolver *opResolver = [[COOperationResolver alloc] init];

    COOperation *operation = [COOperation new];
    operation.operation = ^(COOperation *operation) {
        [regString appendString:@"1"];

        [opResolver awakeOperation:operation times:5 eachAfterTimeInterval:0 withAwakeBlock:^(COOperation *operation) {
            [operation awake];
        } fallbackHandler:^{
            STAssertTrue([regString isEqualToString:@"11111"], nil);

            STAssertTrue(operation.isExecuting, nil);

            blockFlag = YES;
        }];
    };

    [operation start];

    while(blockFlag == NO) {}

    STAssertTrue(operation.isExecuting, nil);
    STAssertEquals(operation.numberOfRuns, (NSUInteger)5, nil);
}


@end
