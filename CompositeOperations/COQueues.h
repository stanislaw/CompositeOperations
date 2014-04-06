// CompositeOperations
//
// CompositeOperations/COQueues.h
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import <Foundation/Foundation.h>

#import "COTypedefs.h"

dispatch_queue_t CODefaultQueue();
void COSetDefaultQueue(dispatch_queue_t queue);

void CORunOperation(COOperation *operation);
