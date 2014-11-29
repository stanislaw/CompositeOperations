//
//  TestCompositeOperations.m
//  DevelopmentApp
//
//  Created by Stanislaw Pankevich on 18/11/14.
//  Copyright (c) 2014 Stanislaw Pankevich. All rights reserved.
//

#import "TestCompositeOperations.h"
#import "TestOperations.h"

@implementation SequentialCompositeOperationTrivialGreen

- (COOperation *)sequentialOperation:(COSequentialOperation *)sequentialOperation
                       nextOperationAfterOperation:(NSOperation<COOperation> *)lastFinishedOperationOrNil {

    if (self.numberOfOperations < 3) {
        self.numberOfOperations++;

        NSArray *array = lastFinishedOperationOrNil ? lastFinishedOperationOrNil.result : @[];

        return [[OperationTakingArrayAndAdding1ToIt alloc] initWithArray:array];
    } else {
        return nil;
    }
}

@end

@implementation SequentialCompositeOperationWithFirstOperationRejectingItself

- (COOperation *)sequentialOperation:(COSequentialOperation *)sequentialOperation
                       nextOperationAfterOperation:(NSOperation<COOperation> *)lastFinishedOperationOrNil {

    if (self.numberOfOperations == 0) {
        return [OperationRejectingItself new];
    }

    else if (self.numberOfOperations < 3) {
        self.numberOfOperations++;

        NSArray *array = lastFinishedOperationOrNil ? lastFinishedOperationOrNil.result : @[];

        return [[OperationTakingArrayAndAdding1ToIt alloc] initWithArray:array];
    }

    else {
        return nil;
    }
}

@end
