#import "SACompositeOperations.h"
#import "SAOperationQueue.h"

void  __attribute__((overloadable)) operation(SAOperationBlock block) {
    SAOperation *ao = [SAOperation new];

    [ao run:block];
}

void  __attribute__((overloadable)) operation(dispatch_queue_t queue, SAOperationBlock block) {
    SAOperation *operation = [SAOperation new];

    [operation runInQueue:queue operation:block];
}

void  __attribute__((overloadable)) operation(id queue, SAOperationBlock block) {
    SAOperation *operation = [SAOperation new];

    operation.operationQueue = queue;

    [operation run:block];
}

void  __attribute__((overloadable)) operation(id queue, SAOperationBlock block, SACompletionBlock completionHandler, SACancellationBlockForOperation cancellationHandler) {
    SAOperation *operation = [SAOperation new];

    operation.operationQueue = queue;

    [operation run:block completionHandler:completionHandler cancellationHandler:cancellationHandler];
}

void __attribute__((overloadable)) syncOperation(SASyncOperationBlock block) {
    SASyncOperation *so = [SASyncOperation new];

    [so run:block];
}

void __attribute__((overloadable)) syncOperation(dispatch_queue_t queue, SASyncOperationBlock block) {
    SASyncOperation *so = [SASyncOperation new];
    
    [so runInQueue:queue operation:block];
}

void __attribute__((overloadable)) cascadeOperation(SACascadeOperationBlock block, SACompletionBlock completionHandler, SACancellationBlockForCascadeOperation cancellationHandler) {
    SACascadeOperation *co = [SACascadeOperation new];

    [co run:block completionHandler:completionHandler cancellationHandler:cancellationHandler];
}

void __attribute__((overloadable)) cascadeOperation(id queue, SACascadeOperationBlock block, SACompletionBlock completionHandler, SACancellationBlockForCascadeOperation cancellationHandler) {
    SACascadeOperation *co = [SACascadeOperation new];
    co.operationQueue = queue;
    
    [co run:block completionHandler:completionHandler cancellationHandler:cancellationHandler];
}

void __attribute__((overloadable)) transactionalOperation(SATransactionalOperationBlock block, SACompletionBlock completionHandler, SACancellationBlockForTransactionalOperation cancellationHandler) {
    SATransactionalOperation *to = [SATransactionalOperation new];
    
    [to run:block completionHandler:completionHandler cancellationHandler:cancellationHandler];
}

void __attribute__((overloadable)) transactionalOperation(id queue, SATransactionalOperationBlock block, SACompletionBlock completionHandler, SACancellationBlockForTransactionalOperation cancellationHandler) {
    SATransactionalOperation *to = [SATransactionalOperation new];
    to.operationQueue = queue;

    [to run:block completionHandler:completionHandler cancellationHandler:cancellationHandler];
}
