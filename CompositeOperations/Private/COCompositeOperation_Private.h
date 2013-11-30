//
//  COCompositeOperation_Private.h
//  TestsApp
//
//  Created by Stanislaw Pankevich on 30/11/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import "COCompositeOperation.h"

@interface COCompositeOperation ()

@property (strong, nonatomic) NSMutableArray *operations;
@property BOOL allSuboperationsRegistered;

- (void)_teardown;

- (void)_registerSuboperation:(COOperation *)subOperation;
- (void)_runSuboperation:(COOperation *)subOperation;
- (void)_runSuboperationAtIndex:(NSUInteger)indexOfSuboperationToRun;

- (void)_cancelSuboperations:(BOOL)runCompletionBlocks;

@end
