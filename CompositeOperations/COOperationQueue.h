#import <Foundation/Foundation.h>
#import "COOperation.h"

typedef enum {
    COOperationQueueSuspendedState   = -1,
    COOperationQueueNormalState       = 1
} COOperationQueueState;

typedef enum {
    COOperationQueueFIFO = 0,
    COOperationQueueLIFO,
    COOperationQueueAggressiveLIFO
} COOperationQueueType;

@interface COOperationQueue : NSObject {
    dispatch_queue_t _queue;
}

@property dispatch_queue_t queue;
@property COOperationQueueType queueType;

@property (readonly) BOOL isSuspended;

@property (readonly) NSUInteger operationCount;
@property NSInteger maximumOperationsLimit;

@property (strong) NSMutableArray *pendingOperations;
@property (strong) NSMutableArray *runningOperations;

- (void)addOperationWithBlock:(COBlock)operationBlock;

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


@interface COOperationQueue ()

@property COOperationQueueState state;
@property (nonatomic, readonly) NSString *stateKey;

- (void)_runNextOperationIfExists;

@end
