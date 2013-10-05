#import <Foundation/Foundation.h>

#import "SATypedefs.h"

#import "SAOperation.h"
#import "SASyncOperation.h"
#import "SATransactionalOperation.h"
#import "SACascadeOperation.h"

#import "SAOperationQueue.h"

void  __attribute__((overloadable)) operation(SAOperationBlock block);
void  __attribute__((overloadable)) operation(dispatch_queue_t queue, SAOperationBlock block);
void  __attribute__((overloadable)) operation(id queue, SAOperationBlock block);
void  __attribute__((overloadable)) operation(id queue, SAOperationBlock block, SACompletionBlock completionHandler, SACancellationBlockForOperation cancellationHandler);

void __attribute__((overloadable)) syncOperation(SASyncOperationBlock block);
void __attribute__((overloadable)) syncOperation(dispatch_queue_t queue, SASyncOperationBlock block);

void __attribute__((overloadable)) cascadeOperation(SACascadeOperationBlock block, SACompletionBlock completionHandler, SACancellationBlockForCascadeOperation cancellationHandler);
void __attribute__((overloadable)) cascadeOperation(id queue, SACascadeOperationBlock block, SACompletionBlock completionHandler, SACancellationBlockForCascadeOperation cancellationHandler);

void __attribute__((overloadable)) transactionalOperation(SATransactionalOperationBlock block, SACompletionBlock completionHandler, SACancellationBlockForTransactionalOperation cancellationHandler);
void __attribute__((overloadable)) transactionalOperation(id queue, SATransactionalOperationBlock block, SACompletionBlock completionHandler, SACancellationBlockForTransactionalOperation cancellationHandler);
