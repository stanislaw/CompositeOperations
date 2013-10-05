#import "SAOperationResolver.h"
#import "SAOperation.h"

#import "SAQueues.h"

@implementation SAOperationResolver

- (id)init {
    if (self = [super init]) {
        self.defaultNumberOfTimesToRerunOperation = 10;
        self.defaultPauseInSecondsBeforeNextRunOfOperation = 0;
    }

    return self;
}

- (void)resolveOperation:(SAOperation *)operation {
    [self resolveOperation:operation usingResolutionStrategy:nil fallbackHandler:nil];
}

// Default implementation, should be extended in subclasses
- (void)resolveOperation:(SAOperation *)operation usingResolutionStrategy:(id)resolutionStrategy fallbackHandler:(SACompletionBlock)fallbackHandler {

    [self awakeOperation:operation times:self.defaultNumberOfTimesToRerunOperation eachAfterTimeInterval:self.defaultPauseInSecondsBeforeNextRunOfOperation withAwakeBlock:^(SAOperation *operation) {
        [operation awake];
    } fallbackHandler:^{
        if (fallbackHandler) fallbackHandler();
    }];
}

- (void)awakeOperation:(SAOperation *)operation times:(NSUInteger)times eachAfterTimeInterval:(NSTimeInterval)timeInterval withAwakeBlock:(SAOperationBlock)awakeBlock fallbackHandler:(SACompletionBlock)fallbackHandler {

    if (operation.numberOfRuns < times) {

        // Fallback handlers are registered for operations that have been run once.
        if (operation.numberOfRuns == 1) {
            __weak SAOperation *weakOperation = operation;

            // Decorate NSOperation's completionBlock, so it could run fallbackHandler():
            // It runs fallbackHandler() only if operation is still unfinished.
            operation.completionBlock = ^{
                __strong SAOperation *strongOperation = weakOperation;

                if (strongOperation.isFinished == NO && strongOperation.isCancelled == NO) {
                    if (fallbackHandler) fallbackHandler();
                } else {
                    if (strongOperation.completionBlock) {
                        strongOperation.completionBlock();
                    }
                }
            };
        }
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC));
        dispatch_after(popTime, SADefaultQueue(), ^(void){
            awakeBlock(operation);
        });
    } else {
        if (operation.completionBlock) operation.completionBlock();
    }
}

@end
