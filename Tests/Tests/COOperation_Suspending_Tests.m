#import "TestHelpers.h"

#import "COOperation.h"

@interface SAOperation_Suspending_Tests : SenTestCase
@end

@implementation SAOperation_Suspending_Tests

- (void)test_suspend_whenNotRunning {
    __block BOOL isDone = NO;
    
    COOperation *operation = [COOperation new];

    operation.operation = ^(COOperation *operation) {};
    STAssertTrue(operation.isReady, nil);

    asynchronousJob(^{
        [operation suspend];
        STAssertTrue(operation.isSuspended, nil);

        isDone = YES;
    });

    while (!isDone);

    [operation resume];

    STAssertTrue(operation.isReady, nil);
}

@end
