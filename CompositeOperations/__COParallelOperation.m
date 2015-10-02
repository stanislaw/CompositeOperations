//
// CompositeOperations
//
// CompositeOperations/__COParallelOperation.m
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "__COParallelOperation.h"

#import "COAbstractOperation_Private.h"

@interface __COParallelOperation ()

@property (readonly, nonatomic) NSArray <NSOperation <COOperation> *> *operations;

- (void)cancelAllOperations;

@end

@implementation __COParallelOperation

#pragma mark - __COParallelOperation

- (id)initWithOperations:(NSArray <NSOperation <COOperation> *> *)operations {
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
        self.error = [NSError errorWithDomain:COErrorDomain code:COOperationErrorCancelled userInfo:nil];
    }

    self.state = COOperationStateFinished;

    if (self.completion) {
        self.completion(self.result, self.error);
    }
}

- (void)reject {
    if (self.isCancelled == NO) {
        NSArray *errors = [self.operations valueForKey:@"error"];

        self.error = errors;
    } else {
        self.error = [NSError errorWithDomain:COErrorDomain code:COOperationErrorCancelled userInfo:nil];
    }

    self.state = COOperationStateFinished;

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

    for (NSOperation <COOperation> *operation in self.operations) {
        dispatch_group_enter(group);

        __weak __COParallelOperation *weakSelf = self;
        __weak NSOperation <COOperation> *weakOperation = operation;

        operation.completionBlock = ^{
            if (weakOperation.result == nil) {
                [weakSelf cancelAllOperations];
            }

            dispatch_group_leave(group);
        };
    }

    for (NSOperation <COOperation> *operation in self.operations) {
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

            [self.operations enumerateObjectsUsingBlock:^(id <COOperation> operation, NSUInteger idx, BOOL *stop) {
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

#pragma mark - NSObject

- (NSString *)debugDescription {
    NSMutableArray *descriptionComponents = [NSMutableArray array];

    [descriptionComponents addObject:[NSString stringWithFormat:@"name = %@; state = %@; isCancelled = %@; operations = %@; result = %@; error = %@", self.name, COKeyPathFromOperationState(self.state), self.isCancelled ? @"YES" : @"NO", self.operations, self.result, self.error]];

    NSString *description = [NSString stringWithFormat:@"<%@: %p (%@)>", NSStringFromClass([self class]), self, [descriptionComponents componentsJoinedByString:@"; "]];

    return description;
}

@end
