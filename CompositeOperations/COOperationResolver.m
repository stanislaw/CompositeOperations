// CompositeOperations
//
// CompositeOperations/COOperationResolver.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "COOperationResolver.h"
#import "COOperation.h"

#import "COQueues.h"

@implementation COOperationResolver

- (id)init {
    if (self = [super init]) {
        self.defaultNumberOfTimesToRerunOperation = 10;
        self.defaultPauseInSecondsBeforeNextRunOfOperation = 0;
    }

    return self;
}

- (void)resolveOperation:(COOperation *)operation {
    [self resolveOperation:operation usingResolutionStrategy:nil fallbackHandler:nil];
}

// Default implementation, should be extended in subclasses
- (void)resolveOperation:(COOperation *)operation usingResolutionStrategy:(id)resolutionStrategy fallbackHandler:(COCompletionBlock)fallbackHandler {

    [self awakeOperation:operation times:self.defaultNumberOfTimesToRerunOperation eachAfterTimeInterval:self.defaultPauseInSecondsBeforeNextRunOfOperation withAwakeBlock:^(COOperation *operation) {
        [operation awake];
    } fallbackHandler:^{
        if (fallbackHandler) fallbackHandler();
    }];
}

- (void)awakeOperation:(COOperation *)operation times:(NSUInteger)times eachAfterTimeInterval:(NSTimeInterval)timeInterval withAwakeBlock:(COOperationBlock)awakeBlock fallbackHandler:(COCompletionBlock)fallbackHandler {

    if (operation.numberOfRuns < times) {

        // Fallback handlers are registered for operations that have been run once.
        if (operation.numberOfRuns == 1) {
            __weak COOperation *weakOperation = operation;

            // Decorate NSOperation's completionBlock, so it could run fallbackHandler():
            // It runs fallbackHandler() only if operation is still unfinished.

            COBlock operationOriginalCompletionBlock = [operation.completionBlock copy];

            operation.completionBlock = ^{
                __strong COOperation *strongOperation = weakOperation;

                if (strongOperation.isFinished == NO && strongOperation.isCancelled == NO) {
                    if (fallbackHandler) fallbackHandler();
                } else {
                    if (operationOriginalCompletionBlock) {
                        operationOriginalCompletionBlock();
                    }
                }
            };
        }
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC));
        dispatch_after(popTime, CODefaultQueue(), ^(void){
            awakeBlock(operation);
        });
    } else {
        if (operation.completionBlock) operation.completionBlock();
    }
}

@end
