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

@implementation Sequence_ThreeTrivialGreenOperations

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

@implementation Sequence_FirstOperationRejects

- (COOperation *)nextOperationAfterOperation:(COOperation *)previousOperationOrNil {
    if (previousOperationOrNil == nil) {
        self.numberOfOperations++;

        return [OperationRejectingItself new];
    }

    if (previousOperationOrNil.error) {
        return nil;
    }

    return nil;
}

@end

@implementation Sequence_FirstOperationRejects_3Attempts

- (COOperation *)nextOperationAfterOperation:(COOperation *)previousOperationOrNil {
    if (previousOperationOrNil == nil) {
        self.numberOfOperations++;

        return [OperationRejectingItself new];
    }

    else if (self.numberOfOperations < 3) {
        self.numberOfOperations++;

        NSArray *array = previousOperationOrNil.result ?: @[];

        return [[OperationTakingArrayAndAdding1ToIt alloc] initWithArray:array];
    }

    return nil;
}

@end
