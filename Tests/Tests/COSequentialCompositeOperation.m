
#import "TestHelpers.h"

#import "COSequentialCompositeOperation.h"
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

@interface SequentialCompositeOperation1 : COSequentialCompositeOperation
@property (assign, nonatomic) NSUInteger numberOfOperations;
@end

@implementation SequentialCompositeOperation1

- (id)nextOperationAfterOperation:(COOperation *)lastFinishedOperationOrNil {
    if (self.numberOfOperations < 3) {
        self.numberOfOperations++;

        NSArray *array = lastFinishedOperationOrNil ? lastFinishedOperationOrNil.result : @[];

        return [[Operation1 alloc] initWithArray:array];
    } else {
        return nil;
    }
}

@end


SPEC_BEGIN(COSequentialCompositeOperationSpec)

describe(@"COSequentialCompositeOperationSpec", ^{

    it(@"should run composite operation", ^{
        dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

        SequentialCompositeOperation1 *sequentialOperation = [[SequentialCompositeOperation1 alloc] init];

        sequentialOperation.completionBlock = ^{
            dispatch_semaphore_signal(waitSemaphore);
        };

        [sequentialOperation start];

        while (dispatch_semaphore_wait(waitSemaphore, DISPATCH_TIME_NOW)) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.05, YES);
        }

        [[theValue(sequentialOperation.isFinished) should] beYes];

        [[sequentialOperation.result should] equal:@[ @(1), @(1), @(1) ]];
    });
});

SPEC_END