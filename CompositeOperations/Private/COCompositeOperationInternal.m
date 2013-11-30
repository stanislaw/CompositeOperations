//
//  COCompositeOperationInternal.m
//  TestsApp
//
//  Created by Stanislaw Pankevich on 30/11/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import "COCompositeOperationInternal.h"

#import "COOperation_Private.h"

#import "COQueues.h"
@interface COCompositeOperationInternal ()
@end;

@implementation COCompositeOperationInternal

- (instancetype)initWithCompositeOperation:(COCompositeOperation *)compositeOperation {
//    self = [self init];
//
//    if (self == nil) return nil;

    self.compositeOperation = compositeOperation;

    return self;
}

- (void)enqueueSuboperation:(COOperation *)subOperation {}

- (void)performCheckpointRoutine {}
- (void)performAwakeRoutine {}
- (void)performResumeRoutine {}

- (void)subOperationWasCancelled:(COOperation *)subOperation {
    self.compositeOperation.completionBlock();
}

- (void)subOperationWasFinished:(COOperation *)subOperation {
    @synchronized(self.compositeOperation) {
        [self.compositeOperation.operations removeObject:subOperation];
    }

    [self performCheckpointRoutine];
}

#pragma mark
#pragma mark Private methods

- (void)_teardown {
    for (COOperation *operation in self.compositeOperation.operations) {
        operation.contextOperation = nil;
    }

    self.compositeOperation.operations = nil;
}

- (void)_enqueueSuboperation:(COOperation *)subOperation {
    //
}

- (BOOL)isKindOfClass:(Class)aClass;
{
    return [self.compositeOperation isKindOfClass:aClass];
}
- (BOOL)conformsToProtocol:(Protocol *)aProtocol;
{
    return [self.compositeOperation conformsToProtocol:aProtocol];
}
- (BOOL)respondsToSelector:(SEL)aSelector;
{
    return [self.compositeOperation respondsToSelector:aSelector];
}

- (void)_registerSuboperation:(COOperation *)subOperation {
    subOperation.contextOperation = self.compositeOperation;
    subOperation.operationQueue = self.compositeOperation.operationQueue;

    @synchronized(self.compositeOperation) {
        [self.compositeOperation.operations addObject:subOperation];
    }
}

- (void)_runSuboperation:(COOperation *)subOperation {
    [subOperation addObserver:self
                   forKeyPath:@"isFinished"
                      options:NSKeyValueObservingOptionNew
                      context:NULL];

    [subOperation addObserver:self
                   forKeyPath:@"isCancelled"
                      options:NSKeyValueObservingOptionNew
                      context:NULL];

    CORunOperation(subOperation);
}

- (void)_runSuboperationAtIndex:(NSUInteger)indexOfSuboperationToRun {
    COOperation *operation;

    @synchronized(self.compositeOperation) {
        operation = [self.compositeOperation.operations objectAtIndex:indexOfSuboperationToRun];
    }

    [self _runSuboperation:operation];
}

- (void)_cancelSuboperations:(BOOL)runCompletionBlocks {
    NSArray *subOperations;

    @synchronized(self.compositeOperation) {
        subOperations = [self.compositeOperation.operations copy];
    }

    [subOperations enumerateObjectsUsingBlock:^(COOperation *operation, NSUInteger idx, BOOL *stop) {
        if (operation.isCancelled == NO && operation.isFinished == NO) {
            if (operation.isReady == NO) {
                [operation removeObserver:self forKeyPath:@"isFinished"];
                [operation removeObserver:self forKeyPath:@"isCancelled"];
            }

            [operation cancel];

            if (operation.completionBlock && runCompletionBlocks) operation.completionBlock();
        }
    }];
}

#pragma mark - NSProxy

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    if ([self.compositeOperation respondsToSelector:aSelector]) {
        return [self.compositeOperation methodSignatureForSelector:aSelector];
    } else {
        return [super methodSignatureForSelector:aSelector];
    }
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL selector = [invocation selector];

    if ([self.compositeOperation respondsToSelector:selector]) {
        [invocation invokeWithTarget:self.compositeOperation];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    if ([object isEqual:self.compositeOperation]) {
        [self _teardown];
    } else {
        @synchronized(self.compositeOperation) {
            [object removeObserver:self forKeyPath:@"isFinished"];
            [object removeObserver:self forKeyPath:@"isCancelled"];
        }

        COOperation *operation = (COOperation *)object;

        if ([keyPath isEqual:@"isFinished"]) {
            [self subOperationWasFinished:operation];
        } else if ([keyPath isEqual:@"isCancelled"]) {
            [self subOperationWasCancelled:operation];
        }
    }
}


@end
