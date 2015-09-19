//
//  TestCompositeOperations.m
//  CompositeOperations
//
//  Created by Stanislaw Pankevich on 18/11/14.
//  Copyright (c) 2014 Stanislaw Pankevich. All rights reserved.
//

#import "TestCompositeOperations.h"
#import "TestOperations.h"

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

@implementation TransactionOfThreeOperationsTriviallyReturningNull

- (NSArray *)operations {
    NSArray *operations = @[
        [OperationTriviallyReturningNull new],
        [OperationTriviallyReturningNull new],
        [OperationTriviallyReturningNull new]
    ];

    return operations;
}

@end

@implementation TransactionWithOneOperationRejectingItself

- (NSArray *)operations {
    NSArray *operations = @[
        [OperationRejectingItself new],
    ];

    return operations;
}

@end

@implementation TransactionWithOneOperationRejectingItselfWithGivenError

- (id)initWithError:(NSError *)error {
    self = [super init];
    if (self == nil) return nil;
    _error = error;
    return self;
}

- (NSArray *)operations {
    NSArray *operations = @[
        [[OperationRejectingItselfWithError alloc] initWithError:self.error],
    ];

    return operations;
}

@end

@implementation TransactionWithThreeSequentialOperationsEachWithThreeTrivialGreenOperations

- (NSArray *)operations {
    COSequentialOperation *sequentialOperation1 = [[COSequentialOperation alloc] initWithSequentialTask:[SequenceOfThreeTrivialGreenOperations new]];
    COSequentialOperation *sequentialOperation2 = [[COSequentialOperation alloc] initWithSequentialTask:[SequenceOfThreeTrivialGreenOperations new]];
    COSequentialOperation *sequentialOperation3 = [[COSequentialOperation alloc] initWithSequentialTask:[SequenceOfThreeTrivialGreenOperations new]];

    NSArray *operations = @[
        sequentialOperation1,
        sequentialOperation2,
        sequentialOperation3
    ];

    return operations;
}

@end