
#import "TestHelpers.h"
#import "TestOperations.h"

#import "__COParallelOperation.h"

#import "TestCompositeOperations.h"

@interface ParallelCompositeOperation1 : __COParallelOperation
@property (assign, nonatomic) NSUInteger numberOfOperations;
@end

@implementation ParallelCompositeOperation1
@end

SPEC_BEGIN(__COParallelOperationSpec)

describe(@"__COParallelOperationSpec", ^{
    it(@"", ^{
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
        [[theValue(parallelOperation.isCancelled) should] beNo];

        [[parallelOperation.result should] equal:@[ [NSNull null], [NSNull null], [NSNull null] ]];
        [[parallelOperation.error should] beNil];
    });
});

describe(@"__COParallelOperationSpec - Rejection", ^{
    it(@"", ^{
        dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

        id <COOperation> rejectingOperation = [OperationRejectingItself new];

        NSArray *operations = @[
            rejectingOperation
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
        [[theValue(parallelOperation.isCancelled) should] beNo];

        [[parallelOperation.result should] beNil];
        [[parallelOperation.error should] beKindOfClass:[NSArray class]];

        NSError *parallelOperationOnlyError = parallelOperation.error.firstObject;

        NSError *expectedOperationError = rejectingOperation.error;

        [[parallelOperationOnlyError should] equal:expectedOperationError];
    });

    it(@"", ^{
        dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:nil];

        NSArray *operations = @[
            [[OperationRejectingItselfWithError alloc] initWithError:error]
        ];

        ParallelCompositeOperation1 *parallelOperation = [[ParallelCompositeOperation1 alloc] initWithOperations:operations];

        parallelOperation.completionBlock = ^{
            dispatch_semaphore_signal(waitSemaphore);
        };

        [parallelOperation start];

        while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
        }

        NSArray *parallelOperationError = parallelOperation.error;
        NSError *parallelOperationOnlyError = parallelOperation.error.firstObject;

        [[theValue(parallelOperation.isFinished) should] beYes];
        [[theValue(parallelOperation.isCancelled) should] beNo];

        [[parallelOperation.result should] beNil];

        [[parallelOperationError should] beKindOfClass:[NSArray class]];

        [[parallelOperationOnlyError should] equal:error];
    });
});

SPEC_END
