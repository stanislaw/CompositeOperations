//
// CompositeOperations
//
// CompositeOperations/COParallelOperation.m
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COParallelOperation.h"

#import "COAbstractOperation_Private.h"

@interface COParallelOperation ()

@property (readonly, nonatomic) NSArray *operations;

- (void)cancelAllOperations;

@end

@implementation COParallelOperation

@synthesize completion = _completion;

#pragma mark - COParallelOperation

- (id)initWithOperations:(NSArray *)operations {
    self = [super init];

    if (self == nil) return nil;

    _operations = operations;

    return self;
}

- (void)finishWithResult:(id)result {
    NSParameterAssert(result);

    if (self.isCancelled == NO) {
        self.result = result;
    } else {
        self.error = [NSError errorWithDomain:COErrorDomain code:COSimpleOperationErrorCancelled userInfo:nil];
    }

    self.state = COSimpleOperationStateFinished;

    if (self.completion) {
        self.completion(self.result, self.error);
    }
}

- (void)reject {
    if (self.isCancelled == NO) {
        NSArray *errors = [self.operations valueForKey:@"error"];

        self.error = errors;
    } else {
        self.error = [NSError errorWithDomain:COErrorDomain code:COSimpleOperationErrorCancelled userInfo:nil];
    }

    self.state = COSimpleOperationStateFinished;

    if (self.completion) {
        self.completion(nil, self.error);
    }
}

- (void)cancelAllOperations {
    [self.operations makeObjectsPerformSelector:@selector(cancel)];
}

#pragma mark - NSOperation

- (void)main {
    dispatch_group_t group = dispatch_group_create();

    for (NSOperation <COAbstractOperation> *operation in self.operations) {
        dispatch_group_enter(group);

        __weak COParallelOperation *weakSelf = self;
        __weak NSOperation <COAbstractOperation> *weakOperation = operation;

        operation.completionBlock = ^{
            if (weakOperation.result == nil) {
                [weakSelf cancelAllOperations];
            }

            dispatch_group_leave(group);
        };
    }

    for (NSOperation <COAbstractOperation> *operation in self.operations) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [operation start];
        });
    };

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (self.isCancelled) {
            [self reject];
        } else {
            NSMutableArray *results = [NSMutableArray new];

            __block BOOL allOperationsFinishedSuccessfully = YES;

            [self.operations enumerateObjectsUsingBlock:^(id <COAbstractOperation> operation, NSUInteger idx, BOOL *stop) {
                id result = operation.result;

                if (result) {
                    [results addObject:result];
                } else {
                    allOperationsFinishedSuccessfully = NO;

                    *stop = YES;
                }
            }];

            if (allOperationsFinishedSuccessfully) {
                [self finishWithResult:[results copy]];
            }

            else {
                [self reject];
            }
        }
    });
}

@end
