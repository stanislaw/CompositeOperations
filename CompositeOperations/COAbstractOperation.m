//
// CompositeOperations
//
// CompositeOperations/COAbstractOperation.m
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COAbstractOperation_Private.h"

@implementation COAbstractOperation

@synthesize state = _state;
@synthesize result = _result;
@synthesize error = _error;

- (id)init {
    self = [super init];

    if (self == nil) return nil;

    _state = COOperationStateReady;

    return self;
}

#pragma mark - NSOperation

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
    self.result = [NSNull null];
    self.state = COOperationStateFinished;
}

- (void)start {
    if (self.isReady) {
        self.state = COOperationStateExecuting;

        if (self.isCancelled) {
            self.state = COOperationStateFinished;
        } else {
            [self main];
        }
    }
}

#pragma mark - COAbstractOperation

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

        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:errMessage userInfo:nil];
    }

    @synchronized(self) {
        if (COStateTransitionIsValid(self.state, state) == NO) {
            NSString *errMessage = [NSString stringWithFormat:@"%@: transition from %@ to %@ is invalid", self, COKeyPathFromOperationState(self.state), COKeyPathFromOperationState(state)];

            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:errMessage userInfo:nil];
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

#pragma mark - <NSObject>

- (NSString *)description {
    NSMutableArray *descriptionComponents = [NSMutableArray array];

    [descriptionComponents addObject:[NSString stringWithFormat:@"name = %@; state = %@; isCancelled = %@; result = %@; error = %@", self.name, COKeyPathFromOperationState(self.state), self.isCancelled ? @"YES" : @"NO", self.result, self.error]];

    NSString *description = [NSString stringWithFormat:@"<%@: %p (%@)>", NSStringFromClass([self class]), self, [descriptionComponents componentsJoinedByString:@"; "]];

    return description;
}

@end
