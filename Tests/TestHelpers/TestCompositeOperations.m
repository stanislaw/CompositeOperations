//
//  TestCompositeOperations.m
//  CompositeOperations
//
//  Created by Stanislaw Pankevich on 18/11/14.
//  Copyright (c) 2014 Stanislaw Pankevich. All rights reserved.
//

#import "TestCompositeOperations.h"
#import "TestOperations.h"
#import "COOperation.h"
#import "COSequentialOperation.h"

@implementation SequenceOfThreeTrivialGreenOperations

- (COOperation *)nextOperationAfterOperation:(COOperation *)previousOperationOrNil {

    if (self.numberOfOperations < 3) {
        self.numberOfOperations++;

        NSArray *array = previousOperationOrNil ? previousOperationOrNil.result : @[];

        return [[OperationTakingArrayAndAdding1ToIt alloc] initWithArray:array];
    } else {
        return nil;
    }
}

@end

@implementation SequenceWithFirstOperationRejectingItself

- (COOperation *)nextOperationAfterOperation:(COOperation *)previousOperationOrNil {
    if (self.numberOfOperations == 0) {
        return [OperationRejectingItself new];
    }

    else if (self.numberOfOperations < 3) {
        self.numberOfOperations++;

        NSArray *array = previousOperationOrNil ? previousOperationOrNil.result : @[];

        return [[OperationTakingArrayAndAdding1ToIt alloc] initWithArray:array];
    }

    else {
        return nil;
    }
}

@end
