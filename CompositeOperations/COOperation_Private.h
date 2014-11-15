//
// CompositeOperations
//
// CompositeOperations/COCompositeOperations.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

typedef NS_ENUM(NSInteger, COOperationState) {
    COOperationStateReady = 0,
    COOperationStateExecuting = 1,
    COOperationStateFinished = 2
};

static inline NSString * COKeyPathFromOperationState(COOperationState state) {
    switch (state) {
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

static inline int COStateTransitionIsValid(COOperationState fromState, COOperationState toState) {
    switch (fromState) {
        case COOperationStateReady: {
            return YES;
        }

        case COOperationStateExecuting: {
            if (toState == COOperationStateReady) {
                return NO;
            } else {
                return YES;
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

@interface COOperation ()

@property (assign, nonatomic) COOperationState state;

@property (assign, nonatomic, getter = isCancelled) BOOL cancelled;

@property (strong, nonatomic) id result;
@property (strong, nonatomic) NSError *error;


- (void)finish;
- (void)finishWithResult:(id)result;
- (void)finishWithError:(NSError *)error;

@end
