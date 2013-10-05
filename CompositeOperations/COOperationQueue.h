#import <Foundation/Foundation.h>
#import "SAOperation.h"

typedef enum {
    SAOperationQueueSuspendedState   = -1,
    SAOperationQueueNormalState       = 1
} SAOperationQueueState;

typedef enum {
    SAOperationQueueFIFO = 0,
    SAOperationQueueLIFO,
    SAOperationQueueAggressiveLIFO
} SAOperationQueueType;

@interface SAOperationQueue : NSObject {
    dispatch_queue_t _queue;
}

@property dispatch_queue_t queue;
@property SAOperationQueueType queueType;

@property (readonly) BOOL isSuspended;

@property (readonly) NSUInteger operationCount;
@property NSInteger maximumOperationsLimit;

@property (strong) NSMutableArray *pendingOperations;
@property (strong) NSMutableArray *runningOperations;

- (void)addOperationWithBlock:(SABlock)operationBlock;

- (void)addOperation:(NSOperation *)operation;

- (void)cancelAllOperations;
- (void)removeAllPendingOperations;

// Suspend / Resume
- (void)suspend;
- (void)resume;

// NSObject
- (NSString *)description;
- (NSString *)debugDescription;

@end


@interface SAOperationQueue ()

@property SAOperationQueueState state;
@property (nonatomic, readonly) NSString *stateKey;

- (void)_runNextOperationIfExists;

@end
