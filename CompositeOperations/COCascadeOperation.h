//
//  SAResursiveCascadeOperation.h
//  SACompositeOperationsApp
//
//  Created by Stanislaw Pankevich on 11/20/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SATypedefs.h"

#import "SACompositeOperation.h"
#import "SATransactionalOperation.h"

#import "SAOperationQueue.h"

@class SACascadeOperation;

@interface SACascadeOperation : SAAbstractCompositeOperation

@property (copy) SACascadeOperationBlock operation;

// Public API: Cascade operation
- (void)run:(SACascadeOperationBlock)operationBlock __attribute__((unavailable("must run cascade operation with 'run:completionHandler:cancellationHandler:' instead.")));
- (void)runInQueue:(dispatch_queue_t)queue operation:(SAOperationBlock)operationBlock __attribute__((unavailable("must run cascade operation with 'run:completionHandler:cancellationHandler:' instead.")));

- (void)run:(SACascadeOperationBlock)operationBlock completionHandler:(SACompletionBlock)completionHandler cancellationHandler:(SACancellationBlockForCascadeOperation)cancellationHandler;

@end

@interface SACascadeOperation ()
@end
