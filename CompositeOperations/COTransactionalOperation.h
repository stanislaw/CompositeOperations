#import <Foundation/Foundation.h>

#import "SATypedefs.h"

#import "SACompositeOperation.h"

#import "SACascadeOperation.h"

@class SATransactionalOperation;
@class SAOperation;

@interface SATransactionalOperation : SAAbstractCompositeOperation

@property (copy) SATransactionalOperationBlock operation;

// Public API: Transactional operation
- (void)run:(SATransactionalOperationBlock)operationBlock __attribute__((unavailable("must run transactional operation with 'run:completionHandler:cancellationHandler:' instead.")));
- (void)runInQueue:(dispatch_queue_t)queue operation:(SAOperationBlock)operationBlock __attribute__((unavailable("must run transactional operation with 'run:completionHandler:cancellationHandler:' instead.")));

- (void)run:(SATransactionalOperationBlock)operationBlock completionHandler:(SACompletionBlock)completionHandler cancellationHandler:(SACancellationBlockForTransactionalOperation)cancellationHandler;

@end


@interface SATransactionalOperation ()

@property NSUInteger operationsCount;

@end
