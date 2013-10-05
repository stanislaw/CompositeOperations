//
//  SAQueues.h
//  SACompositeOperationsApp
//
//  Created by Stanislaw Pankevich on 11/26/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SATypedefs.h"

#import "SAOperation.h"

dispatch_queue_t SADefaultQueue();
void SASetDefaultQueue(dispatch_queue_t queue);
void SARunInDefaultQueue(SABlock block);

void SARunOperation(SAOperation *operation);
