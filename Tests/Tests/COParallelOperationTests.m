
#import "TestHelpers.h"
#import "TestOperations.h"

#import "COParallelOperation.h"

#import "TestCompositeOperations.h"

@interface ParallelCompositeOperation1 : COParallelOperation
@property (assign, nonatomic) NSUInteger numberOfOperations;
@end

@implementation ParallelCompositeOperation1
@end

SPEC_BEGIN(COParallelOperationSpec)

describe(@"COParallelOperationSpec", ^{
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

describe(@"COParallelOperationSpec - Rejection", ^{
    it(@"", ^{
        dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

        NSArray *operations = @[
            [OperationRejectingItself new],
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
        [[parallelOperation.error shouldNot] beNil];

        NSError *parallelOperationError = parallelOperation.error;

        NSError *expectedOperationError = [NSError errorWithDomain:COErrorDomain code:COOperationErrorRejected userInfo:nil];

        NSDictionary *expectedParallelOperationErrorUserInfo = @{
            COParallelOperationErrorsKey: @[ expectedOperationError ]
        };

        [[theValue(parallelOperation.isFinished) should] beYes];
        [[theValue(parallelOperation.isCancelled) should] beNo];

        [[parallelOperation.result should] beNil];

        [[parallelOperationError shouldNot] beNil];
        [[parallelOperationError.userInfo should] equal:expectedParallelOperationErrorUserInfo];
        [[theValue(parallelOperationError.code) should] equal:@(COOperationErrorRejected)];
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

        NSError *parallelOperationError = parallelOperation.error;

        NSError *expectedOperationError = [NSError errorWithDomain:COErrorDomain code:COOperationErrorRejected userInfo:@{ COOperationErrorKey: error }];

        NSDictionary *expectedParallelOperationErrorUserInfo = @{
            COParallelOperationErrorsKey: @[ expectedOperationError ]
        };

        [[theValue(parallelOperation.isFinished) should] beYes];
        [[theValue(parallelOperation.isCancelled) should] beNo];

        [[parallelOperation.result should] beNil];

        [[parallelOperationError shouldNot] beNil];
        [[parallelOperationError.userInfo should] equal:expectedParallelOperationErrorUserInfo];
        [[theValue(parallelOperationError.code) should] equal:@(COOperationErrorRejected)];
    });
});

SPEC_END
