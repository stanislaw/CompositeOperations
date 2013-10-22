// CompositeOperations
//
// CompositeOperations/COQueues.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "COQueues.h"

#import "COOperationQueue.h"
#import "COOperation_Private.h"

static dispatch_queue_t defaultQueue;

dispatch_queue_t CODefaultQueue() {
    if (defaultQueue)
        return defaultQueue;
    else
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"SAQueues: defaultQueue should be defined, %s, %d, %s", __FILE__, __LINE__, __PRETTY_FUNCTION__] userInfo:nil];
}

void COSetDefaultQueue(dispatch_queue_t queue) {
#if !OS_OBJECT_USE_OBJC
    if (defaultQueue) dispatch_release(defaultQueue);

    if (queue) {
        dispatch_retain(queue);
    }
#endif

    defaultQueue = queue;
}

void SARunInDefaultQueue(COBlock block) {
    dispatch_async(CODefaultQueue(), block);
}

void CORunOperation(COOperation *operation) {
    if (operation.operationQueue == nil) {
        
        [operation start];
        
    } else if ([operation.operationQueue isKindOfClass:NSOperationQueue.class]) {
        
        NSOperationQueue *opQueue = (NSOperationQueue *)operation.operationQueue;
        [opQueue addOperation:operation];
        
    } else if ([operation.operationQueue isKindOfClass:COOperationQueue.class]) {
        
        [operation.operationQueue addOperation:operation];
        
    } else {
        @throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat:@"%@, %s: operation queue should be of NSOperationQueue class or COOperationQueue", NSStringFromClass(operation.class), __PRETTY_FUNCTION__] userInfo:nil];
    }
}
