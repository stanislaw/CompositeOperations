//
//  COCompositeOperationInternal.m
//  TestsApp
//
//  Created by Stanislaw Pankevich on 30/11/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import "COCompositeOperationInternal.h"

#import "COOperation_Private.h"

#import "COQueues.h"

@implementation COCompositeOperationInternal

- (instancetype)initWithCompositeOperation:(COCompositeOperation *)compositeOperation {
    self = [self init];

    if (self == nil) return nil;

    self.compositeOperation = compositeOperation;

    return self;
}

- (void)_enqueueSuboperation:(COOperation *)subOperation {}

- (void)_performCheckpointRoutine {}
- (void)_performAwakeRoutine {}
- (void)_performResumeRoutine {}

@end
