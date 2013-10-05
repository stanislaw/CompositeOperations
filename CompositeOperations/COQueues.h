//
//  COQueues.h
//  SACompositeOperationsApp
//
//  Created by Stanislaw Pankevich on 11/26/12.
//  Copyright (c) 2012 Stanislaw Pankevich. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "COTypedefs.h"

#import "COOperation.h"

dispatch_queue_t SADefaultQueue();
void COSetDefaultQueue(dispatch_queue_t queue);
void CORunInDefaultQueue(COBlock block);

void CORunOperation(COOperation *operation);
