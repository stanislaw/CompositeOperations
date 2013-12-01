// CompositeOperations
//
// CompositeOperations/COCompositeConcurrentOperationInternal.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "COCompositeConcurrentOperationInternal.h"
#import "COQueues.h"

#import "COOperation_Private.h"
#import "COCompositeOperation_Private.h"

@implementation COCompositeConcurrentOperationInternal

@synthesize compositeOperation = _compositeOperation;

- (instancetype)initWithCompositeOperation:(COCompositeOperation *)compositeOperation {
    self = [self init];

    if (self == nil) return nil;

    self.compositeOperation = compositeOperation;

    return self;
}

- (void)_enqueueSuboperation:(COOperation *)subOperation {
    if (self.compositeOperation.isFinished) [NSException raise: NSInvalidArgumentException format: @"[%@-%@] suboperation cannot be added to the finished composite concurrent operation", NSStringFromClass(self.class), NSStringFromSelector(_cmd)];

    [self.compositeOperation _registerSuboperation:subOperation];

    if (self.compositeOperation.isSuspended == NO) {
        NSUInteger areThereCancelledOperations;

        @synchronized(self.compositeOperation) {
            areThereCancelledOperations = [self.compositeOperation.operations indexOfObjectPassingTest:^BOOL(COOperation *operation, NSUInteger idx, BOOL *stop) {
                if (operation.isCancelled) {
                    *stop = YES;
                    return YES;
                } else {
                    return NO;
                }
            }];
        }

        if (self.compositeOperation.isCancelled == NO && areThereCancelledOperations == NSNotFound) {
            [self.compositeOperation _runSuboperation:subOperation];
        } else {
            [subOperation cancel];
        }
    }
}

- (void)_performCheckpointRoutineIncrementingNumberOfFinishedOperations:(BOOL)increment {
    BOOL shouldFinish = NO;

    @synchronized(self.compositeOperation) {
        if (increment) {
            self.compositeOperation.finishedOperationsCount++;
        }

        shouldFinish = (self.compositeOperation.allSuboperationsRegistered && (self.compositeOperation.finishedOperationsCount == self.compositeOperation.operations.count));
    }

    if (shouldFinish) {
        [self.compositeOperation finish];
    }

}

- (void)_performAwakeRoutine {
    [[self.compositeOperation.operations copy] enumerateObjectsUsingBlock:^(COOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isFinished == NO) {
            [operation initPropertiesForRun];
        }
    }];

    [self _performResumeRoutine];
}

- (void)_performResumeRoutine {
    [[self.compositeOperation.operations copy] enumerateObjectsUsingBlock:^(COOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isReady) {
            [self.compositeOperation _runSuboperation:operation];
        }
    }];
}

@end
