#import <Foundation/Foundation.h>

#import "SATypedefs.h"
#import "SAOperation.h"

@interface SASyncOperation : SAOperation

@property (copy) SASyncOperationBlock operation;

- (void)run:(SASyncOperationBlock)operationBlock;
- (void)runInQueue:(dispatch_queue_t)queue operation:(SASyncOperationBlock)operationBlock;

@end

@interface SASyncOperation ()

@property BOOL isOnMainThread;
@property dispatch_semaphore_t semaphore;

- (void)_blockThreadAndWait;
- (void)_unblockThread;

@end
