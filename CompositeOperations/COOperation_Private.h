//
//  COOperation_Private.h
//  TestsApp
//
//  Created by Stanislaw Pankevich on 10/23/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import "COOperation.h"

typedef NS_ENUM(NSInteger, COOperationState) {
    COOperationCancelledState   = -2,
    COOperationSuspendedState   = -1,
    COOperationReadyState       = 0,
    COOperationExecutingState   = 1,
    COOperationFinishedState    = 2,
};

static inline NSString * COKeyPathFromOperationState(COOperationState state) {
    switch (state) {
        case COOperationCancelledState:
            return @"isCancelled";
        case COOperationSuspendedState:
            return @"isSuspended";
        case COOperationReadyState:
            return @"isReady";
        case COOperationExecutingState:
            return @"isExecuting";
        case COOperationFinishedState:
            return @"isFinished";
        default:
            return @"state";
    }
}

@interface COOperation ()

@property (nonatomic) COOperationState state;

// Context operation
@property (strong) COOperation *contextOperation;

- (void)initPropertiesForRun;

@end
