// CompositeOperations
//
// CompositeOperations/COCompositeOperation.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "COCompositeConcurrentOperationInternal.h"
#import "COQueues.h"

#import "COOperation_Private.h"
#import "COCompositeOperation_Private.h"

@interface COCompositeConcurrentOperationInternal ()
@end

@implementation COCompositeConcurrentOperationInternal

- (void)_enqueueSuboperation:(COOperation *)subOperation {
    if (self.compositeOperation.isFinished) [NSException raise: NSInvalidArgumentException format: @"[%@-%@] suboperation cannot be added to the finished transactional operation", NSStringFromClass(self.class), NSStringFromSelector(_cmd)];

    [self.compositeOperation _registerSuboperation:subOperation];

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
            [self.compositeOperation _runSuboperation:subOperation];
        } else {
            [subOperation cancel];
        }
    }
}

- (void)_performCheckpointRoutine {
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
