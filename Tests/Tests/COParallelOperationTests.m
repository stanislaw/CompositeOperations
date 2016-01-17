
#import "TestHelpers.h"
#import "TestOperations.h"

#import "__COParallelOperation.h"

#import "TestSequences.h"

@interface ParallelCompositeOperation1 : __COParallelOperation
@property (assign, nonatomic) NSUInteger numberOfOperations;
@end

@implementation ParallelCompositeOperation1
@end

SPEC_BEGIN(__COParallelOperationSpec)

describe(@"__COParallelOperationSpec", ^{
    it(@"", ^{
        NSArray *operations = @[
            [OperationReturningNull new],
            [OperationReturningNull new],
            [OperationReturningNull new]
        ];

        ParallelCompositeOperation1 *parallelOperation = [[ParallelCompositeOperation1 alloc] initWithOperations:operations];

        waitForCompletion(^(void(^done)(void)) {
            parallelOperation.completionBlock = ^{
                done();
            };

            [parallelOperation start];
        });

        [[theValue(parallelOperation.isFinished) should] beYes];
        [[theValue(parallelOperation.isCancelled) should] beNo];

        [[parallelOperation.result should] equal:@[ [NSNull null], [NSNull null], [NSNull null] ]];
        [[parallelOperation.error should] beNil];
    });
});

describe(@"__COParallelOperationSpec - Rejection", ^{
    it(@"", ^{
        id <COOperation> rejectingOperation = [OperationRejectingItself new];

        NSArray *operations = @[
            rejectingOperation
        ];

        ParallelCompositeOperation1 *parallelOperation = [[ParallelCompositeOperation1 alloc] initWithOperations:operations];

        waitForCompletion(^(void(^done)(void)) {
            parallelOperation.completionBlock = ^{
                done();
            };

            [parallelOperation start];
        });

        [[theValue(parallelOperation.isFinished) should] beYes];
        [[theValue(parallelOperation.isCancelled) should] beNo];

        [[parallelOperation.result should] beNil];
        [[parallelOperation.error should] beKindOfClass:[NSArray class]];

        NSError *parallelOperationOnlyError = parallelOperation.error.firstObject;

        NSError *expectedOperationError = rejectingOperation.error;

        [[parallelOperationOnlyError should] equal:expectedOperationError];
    });

    it(@"", ^{
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:nil];

        NSArray *operations = @[
            [[OperationRejectingItselfWithError alloc] initWithError:error]
        ];

        ParallelCompositeOperation1 *parallelOperation = [[ParallelCompositeOperation1 alloc] initWithOperations:operations];

        waitForCompletion(^(void(^done)(void)) {
            parallelOperation.completionBlock = ^{
                done();
            };

            [parallelOperation start];
        });

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
