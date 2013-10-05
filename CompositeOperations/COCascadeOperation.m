#import "SACascadeOperation.h"
#import "SAQueues.h"

@implementation SACascadeOperation

#pragma mark
#pragma mark Public API: Cascade operation

- (void)run:(SACascadeOperationBlock)operationBlock completionHandler:(SACompletionBlock)completionHandler cancellationHandler:(SACancellationBlockForCascadeOperation)cancellationHandler {
    self.operation = operationBlock;

    __weak SACascadeOperation *weakSelf = self;
    self.completionBlock = ^{
        __strong SACascadeOperation *strongSelf = weakSelf;

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
    [self _registerSuboperation:subOperation];
}

- (void)performCheckpointRoutine {
    // TODO more conditions?
    if (self.isSuspended) return;

    NSUInteger indexOfSuboperationToRun = [self.operations indexOfObjectPassingTest:^BOOL(SAOperation *operation, NSUInteger idx, BOOL *stop) {
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
    [[self.operations copy] enumerateObjectsUsingBlock:^(SAOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isFinished == NO) {
            [operation initPropertiesForRun];
        }
    }];

    [self performCheckpointRoutine];
}

- (void)performResumeRoutine {
    NSUInteger indexOfSuboperationToRun = [[self.operations copy] indexOfObjectPassingTest:^BOOL(SAOperation *operation, NSUInteger idx, BOOL *stop) {
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

- (void)subOperationWasFinished:(SAOperation *)subOperation {
    [self performCheckpointRoutine];
}

@end
