//
// CompositeOperations
//
// CompositeOperations/COCompositeOperations.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COOperation.h"
#import "COOperation_Private.h"

@implementation COOperation

@synthesize state     = _state,
            cancelled = _cancelled,
            result    = _result,
            error     = _error;

- (id)init {
    self = [super init];

    if (self == nil) return nil;

    _state     = COOperationStateReady;
    _cancelled = NO;

    return self;
}

- (COOperationState)state {
    COOperationState state;
    @synchronized(self) {
        state = _state;
    }
    return state;
}

- (void)setState:(COOperationState)state {
    if (COStateTransitionIsValid(self.state, state) == NO) {
        NSString *errMessage = [NSString stringWithFormat:@"%@: transition from %@ to %@ is invalid", self, COKeyPathFromOperationState(self.state), COKeyPathFromOperationState(state)];

        @throw [NSException exceptionWithName:NSGenericException reason:errMessage userInfo:nil];
    }

    @synchronized(self) {
        if (COStateTransitionIsValid(self.state, state) == NO) {
            NSString *errMessage = [NSString stringWithFormat:@"%@: transition from %@ to %@ is invalid", self, COKeyPathFromOperationState(self.state), COKeyPathFromOperationState(state)];

            @throw [NSException exceptionWithName:NSGenericException reason:errMessage userInfo:nil];
        };

        NSString *oldStateKey = COKeyPathFromOperationState(self.state);
        NSString *newStateKey = COKeyPathFromOperationState(state);

        [self willChangeValueForKey:newStateKey];
        [self willChangeValueForKey:oldStateKey];
        _state = state;
        [self didChangeValueForKey:oldStateKey];
        [self didChangeValueForKey:newStateKey];
    }
}

#pragma mark - <COOperation>

- (void)finish {
    [self finishWithResult:[NSNull null]];
}

- (void)finishWithResult:(id)result {
    NSParameterAssert(result);

    self.result = result;

    self.state = COOperationStateFinished;
}

- (void)reject {
    [self cancel];
    [self finishWithResult:nil];
}

- (void)rejectWithError:(NSError *)error {
    NSParameterAssert(error);

    self.error = error;

    [self cancel];
    [self finishWithResult:nil];
}

#pragma mark - NSOperation interface (partial mirroring)

- (BOOL)isReady {
    return self.state == COOperationStateReady && super.isReady;
}

- (BOOL)isExecuting {
    return self.state == COOperationStateExecuting;
}

- (BOOL)isFinished {
    return self.state == COOperationStateFinished;
}

- (void)main {
    [self finish];
}

- (void)start {
    if (self.isReady) {
        self.state = COOperationStateExecuting;

        if (self.isCancelled) {
            [self finish];
        } else {
            [self main];
        }
    }
}

- (void)cancel {
    self.cancelled = YES;

    if (self.isReady) {
        [self finishWithResult:nil];
    }
}

#pragma mark
#pragma mark <NSObject>

- (NSString *)description {
    NSMutableArray *descriptionComponents = [NSMutableArray array];

    [descriptionComponents addObject:[NSString stringWithFormat:@"state = %@; isCancelled = %@", COKeyPathFromOperationState(self.state), self.isCancelled ? @"YES" : @"NO" ]];

    NSString *description = [NSString stringWithFormat:@"%@ (%@)", super.description, [descriptionComponents componentsJoinedByString:@"; "]];

    return description;
}

- (NSString *)debugDescription {
    return self.description;
}

@end
