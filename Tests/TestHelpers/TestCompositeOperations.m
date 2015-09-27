//
//  TestCompositeOperations.m
//  CompositeOperations
//
//  Created by Stanislaw Pankevich on 18/11/14.
//  Copyright (c) 2014 Stanislaw Pankevich. All rights reserved.
//

#import "TestCompositeOperations.h"
#import "TestOperations.h"
#import "COSimpleOperation.h"
#import "__COSequentialOperation.h"

@implementation Sequence_ThreeTrivialGreenOperations

- (COSimpleOperation *)nextOperationAfterOperation:(COSimpleOperation *)previousOperationOrNil {

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

- (COSimpleOperation *)nextOperationAfterOperation:(COSimpleOperation *)previousOperationOrNil {
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

- (COSimpleOperation *)nextOperationAfterOperation:(COSimpleOperation *)previousOperationOrNil {
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
