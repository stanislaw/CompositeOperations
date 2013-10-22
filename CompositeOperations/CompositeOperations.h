// CompositeOperations
//
// CompositeOperations/COCompositeOperations.h
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import <Foundation/Foundation.h>

#import "COTypedefs.h"

#import "COOperation.h"
#import "COSyncOperation.h"
#import "COTransactionalOperation.h"
#import "COCascadeOperation.h"

#import "COOperationQueue.h"

void  __attribute__((overloadable)) operation(COOperationBlock block);
void  __attribute__((overloadable)) operation(dispatch_queue_t queue, COOperationBlock block);
void  __attribute__((overloadable)) operation(id queue, COOperationBlock block);
void  __attribute__((overloadable)) operation(id queue, COOperationBlock block, COCompletionBlock completionHandler, COCancellationBlockForOperation cancellationHandler);

void __attribute__((overloadable)) syncOperation(COSyncOperationBlock block);
void __attribute__((overloadable)) syncOperation(dispatch_queue_t queue, COSyncOperationBlock block);

void __attribute__((overloadable)) cascadeOperation(COCascadeOperationBlock block, COCompletionBlock completionHandler, COCancellationBlockForCascadeOperation cancellationHandler);
void __attribute__((overloadable)) cascadeOperation(id queue, COCascadeOperationBlock block, COCompletionBlock completionHandler, COCancellationBlockForCascadeOperation cancellationHandler);

void __attribute__((overloadable)) transactionalOperation(COTransactionalOperationBlock block, COCompletionBlock completionHandler, COCancellationBlockForTransactionalOperation cancellationHandler);
void __attribute__((overloadable)) transactionalOperation(id queue, COTransactionalOperationBlock block, COCompletionBlock completionHandler, COCancellationBlockForTransactionalOperation cancellationHandler);
