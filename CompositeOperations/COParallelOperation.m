//
// CompositeOperations
//
// CompositeOperations/COParallelOperation.m
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COParallelOperation.h"

NSString *const COParallelOperationErrorsKey = @"COParallelOperationErrorsKey";

@interface COParallelOperation ()

@property (readonly, nonatomic) NSArray *operations;

- (void)cancelAllOperations;

@end

@implementation COParallelOperation

- (id)initWithOperations:(NSArray *)operations {
    NSParameterAssert(operations);

    self = [super init];

    if (self == nil) return nil;

    _operations = operations;

    return self;
}

- (void)main {
    dispatch_group_t group = dispatch_group_create();

    for (COOperation *operation in self.operations) {
        dispatch_group_enter(group);

        __weak COParallelOperation *weakSelf = self;
        __weak COOperation *weakOperation = operation;

        operation.completionBlock = ^{
            if (weakOperation.result == nil) {
                [weakSelf cancelAllOperations];
            }

            dispatch_group_leave(group);
        };
    }

    for (COOperation *operation in self.operations) {
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

            [self.operations enumerateObjectsUsingBlock:^(COOperation *operation, NSUInteger idx, BOOL *stop) {
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

- (NSError *)resultErrorForError:(NSError *)error code:(NSUInteger)code userInfo:(NSDictionary *)userInfo {
    NSArray *errors = [self.operations valueForKey:@"error"];

    NSError *resultError = [NSError errorWithDomain:COErrorDomain
                                               code:code
                                           userInfo:@{ COParallelOperationErrorsKey : errors }];


    return resultError;
}

- (void)cancelAllOperations {
    [self.operations makeObjectsPerformSelector:@selector(cancel)];
}

@end
