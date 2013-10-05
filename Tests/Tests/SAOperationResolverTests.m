#import "TestHelpers.h"

#import "SAOperationResolver.h"
#import "SAQueues.h"

@interface SAOperationResolverTests : SenTestCase
@end

@implementation SAOperationResolverTests

// awakeOperation:times:eachAfterTimeInterval:fallbackHandlerIfStillNotFinished:
- (void)test_awakeOperation_times_eachAfterTimeInterval_fallbackHandlerIfStillNotFinished {
    __block BOOL blockFlag = NO;
    
    NSMutableString *regString = [NSMutableString string];

    SAOperationResolver *opResolver = [[SAOperationResolver alloc] init];

    SAOperation *operation = [SAOperation new];
    operation.operation = ^(SAOperation *operation) {
        [regString appendString:@"1"];

        [opResolver awakeOperation:operation times:5 eachAfterTimeInterval:0 withAwakeBlock:^(SAOperation *operation) {
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
