// CompositeOperations
//
// CompositeOperations/COCompositeOperations.h
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import <Foundation/Foundation.h>

#import "COTypedefs.h"

#import "COOperation.h"
#import "COCompositeOperation.h"

void  __attribute__((overloadable)) operation(COOperationBlock block);
void  __attribute__((overloadable)) operation(dispatch_queue_t queue, COOperationBlock block);
void  __attribute__((overloadable)) operation(id queue, COOperationBlock block);
void  __attribute__((overloadable)) operation(id queue, COOperationBlock block, COOperationCompletionBlock completionHandler, COOperationCancellationBlock cancellationHandler);
void  __attribute__((overloadable)) operation(COOperation *otherOperation, COOperationCompletionBlock completionHandler, COOperationCancellationBlock cancellationHandler);


void __attribute__((overloadable)) compositeOperation(COCompositeOperationConcurrencyType concurrencyType, id queue, COCompositeOperationBlock block, COCompositeOperationCompletionBlock completionHandler, COCompositeOperationCancellationBlock cancellationHandler);

