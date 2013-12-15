
#import "COOperationResolver.h"

#import "COOperation.h"
#import "COQueues.h"

#import <objc/runtime.h>

void * COOperationResolverKey = &COOperationResolverKey;

@implementation COOperationResolver
- (id)init {
    if (self = [super init]) {
        self.numberOfResolutionsPerOperation = 10;
        self.pauseInSecondsBeforeNextRunOfOperation = 0;
    }

    return self;
}

- (void)resolveOperation:(COOperation *)operation {
    [self resolveOperation:operation usingResolutionStrategy:nil fallbackHandler:nil];
}

// Default implementation, should be extended in subclasses
- (void)resolveOperation:(COOperation *)operation usingResolutionStrategy:(id)resolutionStrategy fallbackHandler:(COBlock)fallbackHandler {
    NSAssert(operation.isCancelled, @"Expected operation to be cancelled: %@", operation);
    NSAssert(operation.isFinished, @"Expected operation to be finished: %@", operation);

    NSNumber *numberOfResolutions = objc_getAssociatedObject(operation, COOperationResolverKey);

    NSUInteger currentResolutionNumber;

    // If it is the first time the operation is cancelled
    if (numberOfResolutions == nil) {
        currentResolutionNumber = 1;
    } else {
        currentResolutionNumber = numberOfResolutions.unsignedIntegerValue + 1;
    }

    if (currentResolutionNumber <= self.numberOfResolutionsPerOperation) {
        COOperation *newOperation = [operation copy];

        objc_setAssociatedObject(newOperation, COOperationResolverKey, @(currentResolutionNumber), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        double delayInSeconds = self.pauseInSecondsBeforeNextRunOfOperation;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            CORunOperation(newOperation);
        });
    } else {
        if (fallbackHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [fallbackHandler invoke];
            });
        }
    }


}

@end
