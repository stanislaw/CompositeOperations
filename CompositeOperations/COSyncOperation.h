// CompositeOperations
//
// CompositeOperations/COSyncOperation.h
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import <Foundation/Foundation.h>

#import "COTypedefs.h"
#import "COOperation.h"

@interface COSyncOperation : COOperation

@property (copy) COSyncOperationBlock operation;

- (void)run:(COSyncOperationBlock)operationBlock;
- (void)runInQueue:(dispatch_queue_t)queue operation:(COSyncOperationBlock)operationBlock;

@end

@interface COSyncOperation ()

@property BOOL isOnMainThread;
@property dispatch_semaphore_t semaphore;

- (void)_blockThreadAndWait;
- (void)_unblockThread;

@end
