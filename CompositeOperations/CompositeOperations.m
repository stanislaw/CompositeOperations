// CompositeOperations
//
// CompositeOperations/COCompositeOperations.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "CompositeOperations.h"

void  __attribute__((overloadable)) operation(COOperationBlock block) {
    COOperation *ao = [COOperation new];

    [ao run:block];
}

void  __attribute__((overloadable)) operation(dispatch_queue_t queue, COOperationBlock block) {
    COOperation *operation = [COOperation new];

    [operation runInQueue:queue operation:block];
}

void  __attribute__((overloadable)) operation(NSOperationQueue *queue, COOperationBlock block) {
    COOperation *operation = [COOperation new];

    operation.operationQueue = queue;

    [operation run:block];
}

void  __attribute__((overloadable)) operation(NSOperationQueue *queue, COOperationBlock block, COOperationCompletionBlock completionHandler, COOperationCancellationBlock cancellationHandler) {
    COOperation *operation = [COOperation new];

    operation.operationQueue = queue;

    [operation run:block completionHandler:completionHandler cancellationHandler:cancellationHandler];
}

void  __attribute__((overloadable)) operation(COOperation *otherOperation, COOperationCompletionBlock completionHandler, COOperationCancellationBlock cancellationHandler) {
    COOperation *operation = [COOperation new];

    [operation run:^(COOperation *operation) {
        [operation resolveWithOperation:otherOperation];
    } completionHandler:^(id result) {
        completionHandler(result);
    } cancellationHandler:^(COOperation *operation, NSError *error) {
        cancellationHandler(operation, error);
    }];
}

void __attribute__((overloadable)) compositeOperation(COCompositeOperationConcurrencyType concurrencyType, COCompositeOperationBlock block, COCompositeOperationCompletionBlock completionHandler, COCompositeOperationCancellationBlock cancellationHandler) {
    COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:concurrencyType];

    [compositeOperation run:block completionHandler:completionHandler cancellationHandler:cancellationHandler];
}

void __attribute__((overloadable)) compositeOperation(COCompositeOperationConcurrencyType concurrencyType, id queue, COCompositeOperationBlock block, COCompositeOperationCompletionBlock completionHandler, COCompositeOperationCancellationBlock cancellationHandler) {
    COCompositeOperation *compositeOperation = [[COCompositeOperation alloc] initWithConcurrencyType:concurrencyType];
    compositeOperation.operationQueue = queue;
    
    [compositeOperation run:block completionHandler:completionHandler cancellationHandler:cancellationHandler];
}
