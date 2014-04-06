// CompositeOperations
//
// CompositeOperations/COQueues.m
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "COQueues.h"

#import "COOperation.h"

static dispatch_queue_t defaultQueue;

dispatch_queue_t CODefaultQueue() {
    if (defaultQueue) {
        return defaultQueue;
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"COCompositeOperations: default queue should be defined by COSetDefaultQueue(), %s, %d, %s", __FILE__, __LINE__, __PRETTY_FUNCTION__] userInfo:nil];
    }
}

void COSetDefaultQueue(dispatch_queue_t queue) {
    defaultQueue = queue;
}

void CORunOperation(COOperation *operation) {
    if (operation.operationQueue == nil) {
        
        [operation start];
        
    } else if (operation.operationQueue && [operation.operationQueue respondsToSelector:@selector(addOperation:)]) {
        [operation.operationQueue performSelector:@selector(addOperation:) withObject:operation];
    }

    else {
        @throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat:@"%@, %s: operation queue should be of NSOperationQueue class or should be capable of adding operations via addOperation:", NSStringFromClass(operation.class), __PRETTY_FUNCTION__] userInfo:nil];
    }
}
