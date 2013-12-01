// CompositeOperations
//
// CompositeOperations/COCompositeSerialOperationInternal.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "COCompositeSerialOperationInternal.h"

#import "COOperation_Private.h"
#import "COCompositeOperation_Private.h"

#import "COQueues.h"

@implementation COCompositeSerialOperationInternal

@synthesize compositeOperation = _compositeOperation;

- (instancetype)initWithCompositeOperation:(COCompositeOperation *)compositeOperation {
    self = [self init];

    if (self == nil) return nil;

    self.compositeOperation = compositeOperation;

    return self;
}

- (void)_enqueueSuboperation:(COOperation *)subOperation {
    [self.compositeOperation _registerSuboperation:subOperation];
}

- (void)_performCheckpointRoutineIncrementingNumberOfFinishedOperations:(BOOL)increment {
    NSUInteger indexOfSuboperationToRun = NSNotFound;

    @synchronized(self.compositeOperation) {
        if (increment) {
            self.compositeOperation.finishedOperationsCount++;
        }

        if (self.compositeOperation.allSuboperationsRegistered && (self.compositeOperation.finishedOperationsCount == self.compositeOperation.operations.count)) {
            
        } else {
            if (self.compositeOperation.isSuspended) return;

            indexOfSuboperationToRun = [self.compositeOperation.operations  indexOfObjectPassingTest:^BOOL(COOperation *operation, NSUInteger idx, BOOL *stop) {
                if (operation.isReady == YES) {
                    *stop = YES;
                    return YES;
                } else {
                    return NO;
                }
            }];
        }
    }

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

    [self _performCheckpointRoutineIncrementingNumberOfFinishedOperations:NO];
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
