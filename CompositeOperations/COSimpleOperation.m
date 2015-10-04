//
// CompositeOperations
//
// CompositeOperations/COSimpleOperation.m
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import <CompositeOperations/COSimpleOperation.h>

#import "COAbstractOperation_Private.h"

@interface COSimpleOperation ()
@end

@implementation COSimpleOperation

@synthesize completion = _completion;

@dynamic result;
@dynamic error;

#pragma mark - <COSimpleOperation>

- (void)finishWithResult:(nonnull id)result {
    NSParameterAssert(result);

    if (self.isCancelled == NO) {
        self.result = result;
    }

    self.state = COOperationStateFinished;

    if (self.completion) {
        self.completion(self.result, nil);
    }
}

- (void)rejectWithError:(nonnull NSError *)error {
    NSParameterAssert(error);

    if (self.isCancelled == NO) {
        self.error = error;
    }

    self.state = COOperationStateFinished;

    if (self.completion) {
        self.completion(nil, self.error);
    }
}

@end
