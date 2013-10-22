#import <Foundation/Foundation.h>
#import "COOperation.h"

typedef NS_ENUM(NSInteger, COOperationQueueState) {
    COOperationQueueSuspendedState   = -1,
    COOperationQueueNormalState       = 1
};

typedef NS_ENUM(NSUInteger, COOperationQueueType) {
    COOperationQueueFIFO = 0,
    COOperationQueueLIFO,
    COOperationQueueAggressiveLIFO
};

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

- (void)_runNextOperationIfExists;

@end
