// CompositeOperations
//
// CompositeOperations/COOperation_Private.h
//
// Copyright (c) 2013 Stanislaw Pankevich
// Released under the MIT license

#import "COOperation.h"

typedef NS_ENUM(NSInteger, COOperationState) {
    COOperationStateCancelled   = -2,
    COOperationStateSuspended   = -1,
    COOperationStateReady       = 0,
    COOperationStateExecuting   = 1,
    COOperationStateFinished    = 2,
};

static inline NSString * COKeyPathFromOperationState(COOperationState state) {
    switch (state) {
        case COOperationStateCancelled:
            return @"isCancelled";
        case COOperationStateSuspended:
            return @"isSuspended";
        case COOperationStateReady:
            return @"isReady";
        case COOperationStateExecuting:
            return @"isExecuting";
        case COOperationStateFinished:
            return @"isFinished";
        default:
            return @"state";
    }
}

@interface COOperation ()

@property (nonatomic) COOperationState state;

@property (strong, nonatomic) id data;

@property (strong, nonatomic) NSError *error;

// Context operation
@property (strong) COOperation *contextOperation;

- (void)initPropertiesForRun;

@property NSUInteger numberOfRuns;

@end
