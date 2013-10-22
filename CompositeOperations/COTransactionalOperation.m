// CompositeOperations
//
// CompositeOperations/COTransactionalOperation.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "COTransactionalOperation.h"
#import "COQueues.h"
#import "COOperation_Private.h"

@implementation COTransactionalOperation

- (void)initPropertiesForRun {
    [super initPropertiesForRun];

    self.operationsCount = 0;
}

#pragma mark
#pragma mark Public API: Transactional operation

- (void)run:(COTransactionalOperationBlock)operationBlock completionHandler:(COCompletionBlock)completionHandler cancellationHandler:(COCancellationBlockForTransactionalOperation)cancellationHandler {
    self.operation = operationBlock;

    __weak COTransactionalOperation *weakSelf = self;
    self.completionBlock = ^{
        __strong COTransactionalOperation *strongSelf = weakSelf;

        if (strongSelf.isFinished) {
            if (completionHandler) completionHandler();

            strongSelf.completionBlock = nil;
        } else if (cancellationHandler) {
            [strongSelf _cancelSuboperations:NO];

            cancellationHandler(strongSelf);
        } else {
            [strongSelf cancel];

            strongSelf.completionBlock = nil;
        }
    };

    CORunOperation(self);
}

#pragma mark
#pragma mark <SACompositeOperation>

- (void)enqueueSuboperation:(COOperation *)subOperation {
    if (self.isFinished) [NSException raise: NSInvalidArgumentException format: @"[%@-%@] suboperation cannot be added to the finished transactional operation", NSStringFromClass(self.class), NSStringFromSelector(_cmd)];
    
    [self _registerSuboperation:subOperation];
    
    self.operationsCount++;

    if (self.isSuspended == NO) {
        NSUInteger areThereCancelledOperations = [[self.operations copy] indexOfObjectPassingTest:^BOOL(COOperation *operation, NSUInteger idx, BOOL *stop) {
            if (operation.isCancelled) {
                *stop = YES;
                return YES;
            } else {
                return NO;
            }
        }];

        if (self.isCancelled == NO && areThereCancelledOperations == NSNotFound) {
            [self _runSuboperation:subOperation];
        } else {
            [subOperation cancel];
        }
    }
}

- (void)performCheckpointRoutine {
    if (self.allSuboperationsRegistered && self.isCancelled == NO && self.operationsCount == 0) {
        [self finish];
    }
}

- (void)performAwakeRoutine {
    [[self.operations copy] enumerateObjectsUsingBlock:^(COOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isFinished == NO) {
            [operation initPropertiesForRun];
        }
    }];

    [self performResumeRoutine];
}

- (void)performResumeRoutine {
    [[self.operations copy] enumerateObjectsUsingBlock:^(COOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isReady) {
            [self _runSuboperation:operation];
        }
    }];
}

- (void)subOperationWasFinished:(COOperation *)subOperation {
    @synchronized(self) {
        self.operationsCount--;
    
        [self performCheckpointRoutine];
    }
}

@end
