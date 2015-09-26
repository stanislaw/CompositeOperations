//
// CompositeOperations
//
// CompositeOperations/COAbstractOperation.m
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COAbstractOperation_Private.h"
#import <CompositeOperations/COTypedefs.h>

@implementation COAbstractOperation

@synthesize state = _state;
@synthesize result = _result;
@synthesize error = _error;

- (id)init {
    self = [super init];

    if (self == nil) return nil;

    _state = COSimpleOperationStateReady;

    return self;
}

- (COSimpleOperationState)state {
    COSimpleOperationState state;
    @synchronized(self) {
        state = _state;
    }
    return state;
}

- (void)setState:(COSimpleOperationState)state {
    if (COStateTransitionIsValid(self.state, state) == NO) {
        NSString *errMessage = [NSString stringWithFormat:@"%@: transition from %@ to %@ is invalid", self, COKeyPathFromOperationState(self.state), COKeyPathFromOperationState(state)];

        @throw [NSException exceptionWithName:COGenericException reason:errMessage userInfo:nil];
    }

    @synchronized(self) {
        if (COStateTransitionIsValid(self.state, state) == NO) {
            NSString *errMessage = [NSString stringWithFormat:@"%@: transition from %@ to %@ is invalid", self, COKeyPathFromOperationState(self.state), COKeyPathFromOperationState(state)];

            @throw [NSException exceptionWithName:COGenericException reason:errMessage userInfo:nil];
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

#pragma mark - NSOperation

- (BOOL)isReady {
    return self.state == COSimpleOperationStateReady && super.isReady;
}

- (BOOL)isExecuting {
    return self.state == COSimpleOperationStateExecuting;
}

- (BOOL)isFinished {
    return self.state == COSimpleOperationStateFinished;
}

- (void)main {
    [self finish];
}

- (void)start {
    if (self.isReady) {
        self.state = COSimpleOperationStateExecuting;

        if (self.isCancelled) {
            [self reject];
        } else {
            [self main];
        }
    }
}

#pragma mark - <COSimpleOperation>

- (void)finish {
    if (self.isCancelled == NO) {
        self.result = [NSNull null];
    } else {
        self.error = [NSError errorWithDomain:COErrorDomain code:COSimpleOperationErrorCancelled userInfo:nil];
    }

    self.state = COSimpleOperationStateFinished;
}

- (void)reject {
    if (self.isCancelled == NO) {
        self.error = [NSError errorWithDomain:COErrorDomain code:COSimpleOperationErrorRejected userInfo:nil];
    } else {
        self.error = [NSError errorWithDomain:COErrorDomain code:COSimpleOperationErrorCancelled userInfo:nil];
    }

    self.state = COSimpleOperationStateFinished;
}

#pragma mark
#pragma mark <NSObject>

- (NSString *)description {
    NSMutableArray *descriptionComponents = [NSMutableArray array];

    [descriptionComponents addObject:[NSString stringWithFormat:@"state = %@; isCancelled = %@; result = %@; error = \"%@\"", COKeyPathFromOperationState(self.state), self.isCancelled ? @"YES" : @"NO", self.result, self.error]];

    NSString *description = [NSString stringWithFormat:@"<%@: %p (%@)>", NSStringFromClass([self class]), self, [descriptionComponents componentsJoinedByString:@"; "]];

    return description;
}

@end