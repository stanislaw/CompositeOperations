//
//  COCompositeOperationInternal.h
//  TestsApp
//
//  Created by Stanislaw Pankevich on 30/11/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "COCompositeOperation.h"

@interface COCompositeOperationInternal : NSObject

@property (weak, nonatomic) COCompositeOperation *compositeOperation;
- (instancetype)initWithCompositeOperation:(COCompositeOperation *)compositeOperation;

- (void)_enqueueSuboperation:(COOperation *)subOperation;

- (void)_performCheckpointRoutine;
- (void)_performAwakeRoutine;
- (void)_performResumeRoutine;

@end
