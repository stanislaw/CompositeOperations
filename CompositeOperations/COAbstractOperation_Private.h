//
// CompositeOperations
//
// CompositeOperations/COAbstractOperation_Private.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <CompositeOperations/COAbstractOperation.h>

typedef NS_ENUM(NSInteger, COSimpleOperationState) {
    COSimpleOperationStateReady = 0,
    COSimpleOperationStateExecuting = 1,
    COSimpleOperationStateFinished = 2
};

static inline NSString *COKeyPathFromOperationState(COSimpleOperationState state) {
    switch (state) {
        case COSimpleOperationStateReady: {
            return @"isReady";
        }

        case COSimpleOperationStateExecuting: {
            return @"isExecuting";
        }

        case COSimpleOperationStateFinished: {
            return @"isFinished";
        }

        default: {
            return @"state";
        }
    }
}

static inline int COStateTransitionIsValid(COSimpleOperationState fromState, COSimpleOperationState toState) {
    switch (fromState) {
        case COSimpleOperationStateReady: {
            return YES;
        }

        case COSimpleOperationStateExecuting: {
            if (toState == COSimpleOperationStateFinished) {
                return YES;
            } else {
                return NO;
            }
        }

        case COSimpleOperationStateFinished: {
            return NO;
        }

        default: {
            return NO;
        }
    }
}

@interface COAbstractOperation ()

@property (assign, nonatomic) COSimpleOperationState state;

@property (strong, nonatomic) id result;
@property (strong, nonatomic) id error;

@end
