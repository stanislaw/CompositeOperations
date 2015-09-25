//
//  COAbstractOperation_Private.h
//  DevelopmentApp
//
//  Created by Stanislaw Pankevich on 25/09/15.
//  Copyright © 2015 Stanislaw Pankevich. All rights reserved.
//

#import <CompositeOperations/COAbstractOperation.h>

typedef NS_ENUM(NSInteger, COOperationState) {
    COOperationStateReady = 0,
    COOperationStateExecuting = 1,
    COOperationStateFinished = 2
};

static inline NSString *COKeyPathFromOperationState(COOperationState state) {
    switch (state) {
        case COOperationStateReady: {
            return @"isReady";
        }

        case COOperationStateExecuting: {
            return @"isExecuting";
        }

        case COOperationStateFinished: {
            return @"isFinished";
        }

        default: {
            return @"state";
        }
    }
}

static inline int COStateTransitionIsValid(COOperationState fromState, COOperationState toState) {
    switch (fromState) {
        case COOperationStateReady: {
            return YES;
        }

        case COOperationStateExecuting: {
            if (toState == COOperationStateFinished) {
                return YES;
            } else {
                return NO;
            }
        }

        case COOperationStateFinished: {
            return NO;
        }

        default: {
            return NO;
        }
    }
}

@interface COAbstractOperation ()

@property (assign, nonatomic) COOperationState state;

@property (strong, nonatomic) id result;
@property (strong, nonatomic) id error;

@end
