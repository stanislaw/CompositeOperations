//
//  SATransactionalOperation.m
//  SACompositeOperations
//
//  Created by Stanislaw Pankevich on 10/20/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import "SATransactionalOperation.h"
#import "SAQueues.h"

@implementation SATransactionalOperation

- (void)initPropertiesForRun {
    [super initPropertiesForRun];

    self.operationsCount = 0;
}

#pragma mark
#pragma mark Public API: Transactional operation

- (void)run:(SATransactionalOperationBlock)operationBlock completionHandler:(SACompletionBlock)completionHandler cancellationHandler:(SACancellationBlockForTransactionalOperation)cancellationHandler {
    self.operation = operationBlock;

    __weak SATransactionalOperation *weakSelf = self;
    self.completionBlock = ^{
        __strong SATransactionalOperation *strongSelf = weakSelf;

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

    SARunOperation(self);
}

#pragma mark
#pragma mark <SACompositeOperation>

- (void)enqueueSuboperation:(SAOperation *)subOperation {
    if (self.isFinished) [NSException raise: NSInvalidArgumentException format: @"[%@-%@] suboperation cannot be added to the finished transactional operation", NSStringFromClass(self.class), NSStringFromSelector(_cmd)];
    
    [self _registerSuboperation:subOperation];
    
    self.operationsCount++;

    if (self.isSuspended == NO) {
        NSUInteger areThereCancelledOperations = [[self.operations copy] indexOfObjectPassingTest:^BOOL(SAOperation *operation, NSUInteger idx, BOOL *stop) {
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
    [[self.operations copy] enumerateObjectsUsingBlock:^(SAOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isFinished == NO) {
            [operation initPropertiesForRun];
        }
    }];

    [self performResumeRoutine];
}

- (void)performResumeRoutine {
    [[self.operations copy] enumerateObjectsUsingBlock:^(SAOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isReady) {
            [self _runSuboperation:operation];
        }
    }];
}

- (void)subOperationWasFinished:(SAOperation *)subOperation {
    @synchronized(self) {
        self.operationsCount--;
    
        [self performCheckpointRoutine];
    }
}

@end
