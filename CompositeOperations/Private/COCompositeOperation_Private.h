// CompositeOperations
//
// CompositeOperations/COCompositeOperation_Private.h
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "COCompositeOperation.h"
#import "COTypedefs.h"

@interface COCompositeOperation ()

@property (strong, nonatomic) NSMutableArray *operations;

@property BOOL allSuboperationsRegistered;

- (void)_teardown;

- (void)_registerSuboperation:(COOperation *)subOperation;
- (void)_runSuboperation:(COOperation *)subOperation;
- (void)_runSuboperationAtIndex:(NSUInteger)indexOfSuboperationToRun;

- (void)_cancelOperations:(BOOL)runCompletionBlocks;

- (void)_operationWasCancelled:(COOperation *)subOperation;
- (void)_operationWasFinished:(COOperation *)subOperation;

@end
