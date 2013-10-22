#import "COCascadeOperation.h"
#import "COQueues.h"
#import "COOperation_Private.h"

@implementation COCascadeOperation

#pragma mark
#pragma mark Public API: Cascade operation

- (void)run:(COCascadeOperationBlock)operationBlock completionHandler:(COCompletionBlock)completionHandler cancellationHandler:(COCancellationBlockForCascadeOperation)cancellationHandler {
    self.operation = operationBlock;

    __weak COCascadeOperation *weakSelf = self;
    self.completionBlock = ^{
        __strong COCascadeOperation *strongSelf = weakSelf;

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
    [self _registerSuboperation:subOperation];
}

- (void)performCheckpointRoutine {
    // TODO more conditions?
    if (self.isSuspended) return;

    NSUInteger indexOfSuboperationToRun = [self.operations indexOfObjectPassingTest:^BOOL(COOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isReady == YES) {
            *stop = YES;
            return YES;
        } else {
            return NO;
        }
    }];

    if (indexOfSuboperationToRun == NSNotFound) {
        [self finish];
    } else {
        [self _runSuboperationAtIndex:indexOfSuboperationToRun];
    }
}

- (void)performAwakeRoutine {            
    [[self.operations copy] enumerateObjectsUsingBlock:^(COOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isFinished == NO) {
            [operation initPropertiesForRun];
        }
    }];

    [self performCheckpointRoutine];
}

- (void)performResumeRoutine {
    NSUInteger indexOfSuboperationToRun = [[self.operations copy] indexOfObjectPassingTest:^BOOL(COOperation *operation, NSUInteger idx, BOOL *stop) {
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

- (void)subOperationWasFinished:(COOperation *)subOperation {
    [self performCheckpointRoutine];
}

@end
