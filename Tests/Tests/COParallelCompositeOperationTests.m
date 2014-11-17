
#import "TestHelpers.h"

#import "COParallelCompositeOperation.h"
#import "COOperation_Private.h"

@interface Operation1 : COOperation

@end

@implementation Operation1 {
    NSArray *_array;
}

- (id)initWithArray:(NSArray *)array {
    NSParameterAssert(array);

    self = [super init];

    _array = array;

    return self;
}

- (void)main {
    id result = [_array arrayByAddingObject:@(1)];

    [self finishWithResult:result];
}

@end

@interface ParallelCompositeOperation1 : COParallelCompositeOperation
@property (assign, nonatomic) NSUInteger numberOfOperations;
@end

@implementation ParallelCompositeOperation1
@end


SPEC_BEGIN(COParallelCompositeOperationSpec)

describe(@"COParallelCompositeOperationSpec", ^{

    it(@"should run composite operation", ^{
        dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

        ParallelCompositeOperation1 *parallelOperation = [[ParallelCompositeOperation1 alloc] init];

        parallelOperation.completionBlock = ^{
            dispatch_semaphore_signal(waitSemaphore);
        };

        [parallelOperation start];

        while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
        }
        
        [[theValue(parallelOperation.isFinished) should] beYes];
        
        [[parallelOperation.result should] equal:@[ @(1), @(1), @(1) ]];
    });
});

SPEC_END
