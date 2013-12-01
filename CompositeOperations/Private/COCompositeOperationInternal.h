// CompositeOperations
//
// CompositeOperations/COCompositeOperationInternal.h
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import <Foundation/Foundation.h>

#import "COTypedefs.h"

@protocol COCompositeOperationInternal <NSObject>

- (instancetype)initWithCompositeOperation:(COCompositeOperation *)compositeOperation;

@property (weak, nonatomic) COCompositeOperation *compositeOperation;

- (void)_enqueueSuboperation:(COOperation *)subOperation;

- (void)_performCheckpointRoutineIncrementingNumberOfFinishedOperations:(BOOL)increment;
- (void)_performAwakeRoutine;
- (void)_performResumeRoutine;

@end
