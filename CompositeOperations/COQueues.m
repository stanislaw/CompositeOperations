#import "SAQueues.h"

#import "SAOperationQueue.h"

static dispatch_queue_t defaultQueue;

dispatch_queue_t SADefaultQueue() {
    if (defaultQueue)
        return defaultQueue;
    else
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"SAQueues: defaultQueue should be defined, %s, %d, %s", __FILE__, __LINE__, __PRETTY_FUNCTION__] userInfo:nil];
}

void SASetDefaultQueue(dispatch_queue_t queue) {
#if !OS_OBJECT_USE_OBJC
    if (defaultQueue) dispatch_release(defaultQueue);

    if (queue) {
        dispatch_retain(queue);
    }
#endif

    defaultQueue = queue;
}

void SARunInDefaultQueue(SABlock block) {
    dispatch_async(SADefaultQueue(), block);
}

void SARunOperation(SAOperation *operation) {
    if (operation.operationQueue == nil) {
        
        [operation start];
        
    } else if ([operation.operationQueue isKindOfClass:NSOperationQueue.class]) {
        
        NSOperationQueue *opQueue = (NSOperationQueue *)operation.operationQueue;
        [opQueue addOperation:operation];
        
    } else if ([operation.operationQueue isKindOfClass:SAOperationQueue.class]) {
        
        [operation.operationQueue addOperation:operation];
        
    } else {
        @throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat:@"%@, %s: operation queue should be of NSOperationQueue class or SAOperationQueue", NSStringFromClass(operation.class), __PRETTY_FUNCTION__] userInfo:nil];
    }
}
