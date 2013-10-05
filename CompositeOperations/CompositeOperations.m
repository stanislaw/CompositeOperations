#import "CompositeOperations.h"
#import "COOperationQueue.h"

void  __attribute__((overloadable)) operation(COOperationBlock block) {
    COOperation *ao = [COOperation new];

    [ao run:block];
}

void  __attribute__((overloadable)) operation(dispatch_queue_t queue, COOperationBlock block) {
    COOperation *operation = [COOperation new];

    [operation runInQueue:queue operation:block];
}

void  __attribute__((overloadable)) operation(id queue, COOperationBlock block) {
    COOperation *operation = [COOperation new];

    operation.operationQueue = queue;

    [operation run:block];
}

void  __attribute__((overloadable)) operation(id queue, COOperationBlock block, COCompletionBlock completionHandler, COCancellationBlockForOperation cancellationHandler) {
    COOperation *operation = [COOperation new];

    operation.operationQueue = queue;

    [operation run:block completionHandler:completionHandler cancellationHandler:cancellationHandler];
}

void __attribute__((overloadable)) syncOperation(COSyncOperationBlock block) {
    COSyncOperation *so = [COSyncOperation new];

    [so run:block];
}

void __attribute__((overloadable)) syncOperation(dispatch_queue_t queue, COSyncOperationBlock block) {
    COSyncOperation *so = [COSyncOperation new];
    
    [so runInQueue:queue operation:block];
}

void __attribute__((overloadable)) cascadeOperation(COCascadeOperationBlock block, COCompletionBlock completionHandler, COCancellationBlockForCascadeOperation cancellationHandler) {
    COCascadeOperation *co = [COCascadeOperation new];

    [co run:block completionHandler:completionHandler cancellationHandler:cancellationHandler];
}

void __attribute__((overloadable)) cascadeOperation(id queue, COCascadeOperationBlock block, COCompletionBlock completionHandler, COCancellationBlockForCascadeOperation cancellationHandler) {
    COCascadeOperation *co = [COCascadeOperation new];
    co.operationQueue = queue;
    
    [co run:block completionHandler:completionHandler cancellationHandler:cancellationHandler];
}

void __attribute__((overloadable)) transactionalOperation(COTransactionalOperationBlock block, COCompletionBlock completionHandler, COCancellationBlockForTransactionalOperation cancellationHandler) {
    COTransactionalOperation *to = [COTransactionalOperation new];
    
    [to run:block completionHandler:completionHandler cancellationHandler:cancellationHandler];
}

void __attribute__((overloadable)) transactionalOperation(id queue, COTransactionalOperationBlock block, COCompletionBlock completionHandler, COCancellationBlockForTransactionalOperation cancellationHandler) {
    COTransactionalOperation *to = [COTransactionalOperation new];
    to.operationQueue = queue;

    [to run:block completionHandler:completionHandler cancellationHandler:cancellationHandler];
}
