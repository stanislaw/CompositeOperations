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

#pragma mark - Basic sequences

@implementation Sequence_123

- (NSDictionary *)steps {
    return @{
        COStepInitial: ^id(id _){
            return [OperationReturning1 new];
        },

        COStep(OperationReturning1): ^id(id _){
            return [OperationReturning2 new];
        },

        COStep(OperationReturning2): ^id(id _){
            return [OperationReturning3 new];
        },

        COStep(OperationReturning3): ^id(id _){
            return COStepFinal;
        },
    };
}

@end

@implementation Sequence_2x2

- (NSDictionary *)steps {
    return @{
             COStepInitial: ^id(id _){
                 return [OperationReturning2 new];
             },

             COStep(OperationReturning2): ^id(OperationReturning2 *operation){
                 return [[OperationPower2 alloc] initWithNumber:operation.result];
             },
             
             COStep(OperationPower2): ^id(id _){
                 return COStepFinal;
             },
    };
}

@end

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
