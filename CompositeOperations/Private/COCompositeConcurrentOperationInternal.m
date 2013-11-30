// CompositeOperations
//
// CompositeOperations/COCompositeOperation.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "COCompositeConcurrentOperationInternal.h"
#import "COQueues.h"
#import "COOperation_Private.h"

@interface COCompositeConcurrentOperationInternal ()
@end

@implementation COCompositeConcurrentOperationInternal

- (void)enqueueSuboperation:(COOperation *)subOperation {
    if (self.compositeOperation.isFinished) [NSException raise: NSInvalidArgumentException format: @"[%@-%@] suboperation cannot be added to the finished transactional operation", NSStringFromClass(self.class), NSStringFromSelector(_cmd)];

    [self _registerSuboperation:subOperation];

    if (self.compositeOperation.isSuspended == NO) {
        __block NSUInteger areThereCancelledOperations;

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
            [self _runSuboperation:subOperation];
        } else {
            [subOperation cancel];
        }
    }
}

- (void)performCheckpointRoutine {
    if (self.compositeOperation.allSuboperationsRegistered && self.compositeOperation.isCancelled == NO) {
        __block NSUInteger operationsCount;

        @synchronized(self.compositeOperation) {
            operationsCount = self.compositeOperation.operations.count;
        }
        
        if (operationsCount == 0) {
            [self.compositeOperation finish];
        }
    }
}

- (void)performAwakeRoutine {
    [[self.compositeOperation.operations copy] enumerateObjectsUsingBlock:^(COOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isFinished == NO) {
            [operation initPropertiesForRun];
        }
    }];

    [self performResumeRoutine];
}

- (void)performResumeRoutine {
    [[self.compositeOperation.operations copy] enumerateObjectsUsingBlock:^(COOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isReady) {
            [self _runSuboperation:operation];
        }
    }];
}

@end
