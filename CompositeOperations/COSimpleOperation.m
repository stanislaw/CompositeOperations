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

- (void)finish {
    [self finishWithResult:[NSNull null]];
}

- (void)finishWithResult:(id)result {
    NSParameterAssert(result);

    if (self.isCancelled == NO) {
        self.result = result;
    } else {
        self.error = [NSError errorWithDomain:COErrorDomain code:COOperationErrorCancelled userInfo:nil];
    }

    self.state = COOperationStateFinished;

    if (self.completion) {
        self.completion(self.result, self.error);
    }
}

- (void)reject {
    if (self.isCancelled == NO) {
        self.error = [NSError errorWithDomain:COErrorDomain code:COOperationErrorRejected userInfo:nil];
    } else {
        self.error = [NSError errorWithDomain:COErrorDomain code:COOperationErrorCancelled userInfo:nil];
    }

    self.state = COOperationStateFinished;

    if (self.completion) {
        self.completion(nil, self.error);
    }
}

- (void)rejectWithError:(NSError *)error {
    NSParameterAssert(error);

    if (self.isCancelled == NO) {
        self.error = error;
    } else {
        self.error = [NSError errorWithDomain:COErrorDomain code:COOperationErrorCancelled userInfo:nil];
    }

    self.state = COOperationStateFinished;

    if (self.completion) {
        self.completion(nil, self.error);
    }
}

@end
