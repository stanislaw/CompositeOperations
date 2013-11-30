// CompositeOperations
//
// CompositeOperations/COCompositeOperation.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "COCompositeSerialOperationInternal.h"
#import "COQueues.h"
#import "COOperation_Private.h"

@implementation COCompositeSerialOperationInternal

- (void)enqueueSuboperation:(COOperation *)subOperation {
    [self _registerSuboperation:subOperation];
}

- (void)performCheckpointRoutine {
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
        [self _runSuboperationAtIndex:indexOfSuboperationToRun];
    }
}

- (void)performAwakeRoutine {            
    [[self.compositeOperation.operations copy] enumerateObjectsUsingBlock:^(COOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isFinished == NO) {
            [operation initPropertiesForRun];
        }
    }];

    [self performCheckpointRoutine];
}

- (void)performResumeRoutine {
    NSUInteger indexOfSuboperationToRun = [[self.compositeOperation.operations copy] indexOfObjectPassingTest:^BOOL(COOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isReady == YES) {
            *stop = YES;
            return YES;
        } else {
            return NO;
        }
    }];

    if (indexOfSuboperationToRun != NSNotFound) {
        [self _runSuboperationAtIndex:indexOfSuboperationToRun];
    }
}

@end
