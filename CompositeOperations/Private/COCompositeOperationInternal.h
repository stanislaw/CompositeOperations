//
//  COCompositeOperationInternal.h
//  TestsApp
//
//  Created by Stanislaw Pankevich on 30/11/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "COCompositeOperation.h"

@protocol COCompositeOperation
- (NSMutableArray *)operations;
@end


@interface COCompositeOperationInternal : NSProxy <COCompositeOperation>

@property (weak, nonatomic) COCompositeOperation *compositeOperation;
- (instancetype)initWithCompositeOperation:(COCompositeOperation *)compositeOperation;

- (void)enqueueSuboperation:(COOperation *)subOperation;

- (void)performCheckpointRoutine;
- (void)performAwakeRoutine;
- (void)performResumeRoutine;

- (void)subOperationWasFinished:(COOperation *)subOperation;
- (void)subOperationWasCancelled:(COOperation *)subOperation;


- (void)_teardown;

- (void)_registerSuboperation:(COOperation *)subOperation;
- (void)_runSuboperation:(COOperation *)subOperation;
- (void)_runSuboperationAtIndex:(NSUInteger)indexOfSuboperationToRun;

- (void)_cancelSuboperations:(BOOL)runCompletionBlocks;


@end
