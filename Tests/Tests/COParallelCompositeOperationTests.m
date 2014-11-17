
#import "TestHelpers.h"
#import "TestOperations.h"

#import "COParallelCompositeOperation.h"
#import "COOperation_Private.h"

@interface ParallelCompositeOperation1 : COParallelCompositeOperation
@property (assign, nonatomic) NSUInteger numberOfOperations;
@end

@implementation ParallelCompositeOperation1
@end


SPEC_BEGIN(COParallelCompositeOperationSpec)

describe(@"COParallelCompositeOperationSpec", ^{

    it(@"should run composite operation", ^{
        dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

        NSArray *operations = @[
            [OperationTriviallyReturningNull new],
            [OperationTriviallyReturningNull new],
            [OperationTriviallyReturningNull new]
        ];

        ParallelCompositeOperation1 *parallelOperation = [[ParallelCompositeOperation1 alloc] initWithOperations:operations];

        parallelOperation.completionBlock = ^{
            dispatch_semaphore_signal(waitSemaphore);
        };

        [parallelOperation start];

        while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
        }
        
        [[theValue(parallelOperation.isFinished) should] beYes];

        [[parallelOperation.result should] equal:@[ [NSNull null], [NSNull null], [NSNull null] ]];
    });
});

SPEC_END
