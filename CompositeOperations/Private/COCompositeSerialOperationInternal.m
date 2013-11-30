// CompositeOperations
//
// CompositeOperations/COCompositeOperation.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "COCompositeSerialOperationInternal.h"

#import "COOperation_Private.h"
#import "COCompositeOperation_Private.h"

#import "COQueues.h"

@implementation COCompositeSerialOperationInternal

- (void)_enqueueSuboperation:(COOperation *)subOperation {
    [self.compositeOperation _registerSuboperation:subOperation];
}

- (void)_performCheckpointRoutine {
    // TODO more conditions?
    if (self.compositeOperation.isSuspended) return;

    NSUInteger indexOfSuboperationToRun = [[self.compositeOperation.operations copy] indexOfObjectPassingTest:^BOOL(COOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isReady == YES) {
            *stop = YES;
            return YES;
        } else {
            return NO;
        }
    }];

    if (indexOfSuboperationToRun == NSNotFound) {
        [self.compositeOperation finish];
    } else {
        [self.compositeOperation _runSuboperationAtIndex:indexOfSuboperationToRun];
    }
}

- (void)_performAwakeRoutine {
    [[self.compositeOperation.operations copy] enumerateObjectsUsingBlock:^(COOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isFinished == NO) {
            [operation initPropertiesForRun];
        }
    }];

    [self _performCheckpointRoutine];
}

- (void)_performResumeRoutine {
    NSUInteger indexOfSuboperationToRun = [[self.compositeOperation.operations copy] indexOfObjectPassingTest:^BOOL(COOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isReady == YES) {
            *stop = YES;
            return YES;
        } else {
            return NO;
        }
    }];

    if (indexOfSuboperationToRun != NSNotFound) {
        [self.compositeOperation _runSuboperationAtIndex:indexOfSuboperationToRun];
    }
}

@end
