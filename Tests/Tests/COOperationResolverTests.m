
#import "TestHelpers.h"

#import "COQueues.h"
#import "CompositeOperations.h"

#import "COOperationResolver.h"

SPEC_BEGIN(COOperationResolverSpecs)
describe(@"COOperationResolver", ^{
    beforeEach(^{
        COSetDefaultQueue(concurrentQueue());
    });

    it(@"", ^{
        __block BOOL isFinished = NO;

        NSMutableString *registry = [NSMutableString string];

        COOperationResolver *operationResolver = [[COOperationResolver alloc] init];

        COOperation *operation = [COOperation new];
        operation.operationBlock = ^(COOperation *operation) {
            [registry appendString:@"1"];

            [operation cancel];

            [operationResolver resolveOperation:operation usingResolutionStrategy:nil fallbackHandler:^{
                isFinished = YES;
            }];
        };

        [operation start];

        while (isFinished == NO) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, YES);

        [[theValue(registry.length) should] equal:@(operationResolver.numberOfResolutionsPerOperation + 1)];
    });
});
SPEC_END
