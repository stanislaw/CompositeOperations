//
//  TestCompositeOperations.m
//  CompositeOperations
//
//  Created by Stanislaw Pankevich on 18/11/14.
//  Copyright (c) 2014 Stanislaw Pankevich. All rights reserved.
//

#import "TestSequences.h"

#import "TestOperations.h"

#import "COSimpleOperation.h"
#import "__COSequentialOperation.h"

#pragma mark - Custom sequences

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
        return [OperationRejectingItself new];
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

@implementation LinearSequence_ThreeOperations_EachReturningNSNull

- (nonnull NSArray <COLinearSequenceStep>*)steps {
    return @[
        ^(NSOperation <COOperation> *_) {
            return [OperationReturningNull new];
        },

        ^(NSOperation <COOperation> *_) {
            return [OperationReturningNull new];
        },

        ^(NSOperation <COOperation> *_) {
            return [OperationReturningNull new];
        }
    ];
}

@end
