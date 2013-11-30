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

#import "COOperationQueue.h"

void  __attribute__((overloadable)) operation(COOperationBlock block);
void  __attribute__((overloadable)) operation(dispatch_queue_t queue, COOperationBlock block);
void  __attribute__((overloadable)) operation(id queue, COOperationBlock block);
void  __attribute__((overloadable)) operation(id queue, COOperationBlock block, COCompletionBlock completionHandler, COCancellationBlockForOperation cancellationHandler);

void __attribute__((overloadable)) compositeOperation(COCompositeOperationConcurrencyType concurrencyType, COCompositeOperationBlock block, COCompletionBlock completionHandler, COCancellationBlockForCompositeOperation cancellationHandler);
void __attribute__((overloadable)) compositeOperation(COCompositeOperationConcurrencyType concurrencyType, id queue, COCompositeOperationBlock block, COCompletionBlock completionHandler, COCancellationBlockForCompositeOperation cancellationHandler);

