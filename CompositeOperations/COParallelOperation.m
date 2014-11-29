//
// CompositeOperations
//
// CompositeOperations/COParallelOperation.m
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COParallelOperation.h"
#import "COOperation_Private.h"

NSString *const COParallelOperationErrorsKey = @"COParallelOperationErrorsKey";

@interface COParallelOperation ()

@property (readonly, nonatomic) NSArray *operations;

@end

@implementation COParallelOperation

- (id)initWithOperations:(NSArray *)operations {
    NSParameterAssert(operations);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _operations = operations;

    return self;
}

- (void)main {
    dispatch_group_t group = dispatch_group_create();

    COParallelOperation *weakSelf = self;

    for (COOperation *operation in self.operations) {
        dispatch_group_enter(group);

        COOperation *weakOperation = operation;

        operation.completionBlock = ^{
            if (weakOperation.result == nil) {
                [weakSelf cancel];
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
        if (self.isCancelled == NO) {
            NSArray *results = [self.operations valueForKey:@"result"];

            [self finishWithResult:results];
        } else {
            NSArray *errors = [self.operations valueForKey:@"error"];

            if (errors.count > 0) {
                NSError *error = [NSError errorWithDomain:@"com.CompositeOperations.COParallelOperation"
                                                     code:0
                                                 userInfo:@{ COParallelOperationErrorsKey : errors }];
                
                [self rejectWithError:error];
            } else {
                [self rejectWithError:COOperationErrorCancelled];
            }
        }
    });
}

- (void)cancel {
    [super cancel];

    [self.operations makeObjectsPerformSelector:@selector(cancel)];
}

@end
