//
//  TestHelpers.m
//  SACompositeOperationsApp
//
//  Created by Stanislaw Pankevich on 11/20/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import "TestHelpers.h"

#import "SAQueues.h"

dispatch_queue_t currentQueue() {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    dispatch_queue_t currentQueue = dispatch_get_current_queue();
#pragma clang diagnostic pop

    return currentQueue;
}

dispatch_queue_t serialQueue() {
    static dispatch_queue_t _serialQueue = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _serialQueue = dispatch_queue_create("SACompositeOperations.queue.serial", DISPATCH_QUEUE_SERIAL);
    });

    return _serialQueue;
}

dispatch_queue_t concurrentQueue() {
    static dispatch_queue_t _concurrentQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    });

    return _concurrentQueue;
}

dispatch_queue_t createQueue() {
    return dispatch_queue_create("SACompositeOperations.queue.serial.random", NULL);
}

void asynchronousJob(asyncronousBlock block) {
    dispatch_queue_t queue = createQueue();

    dispatch_async(queue, block);
}

@implementation SenTestCase (Helpers)

- (void) setUp {
    [super setUp];
    
    SASetDefaultQueue(concurrentQueue());
}

@end