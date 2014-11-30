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

    if (self == nil) return nil;

    _operations = operations;

    return self;
}

- (void)main {
    dispatch_group_t group = dispatch_group_create();

    for (COOperation *operation in self.operations) {
        dispatch_group_enter(group);

        operation.completionBlock = ^{
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
            [self rejectWithError:COOperationErrorCancelled];
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
                NSArray *errors = [self.operations valueForKey:@"error"];

                NSError *error = [NSError errorWithDomain:@"com.CompositeOperations"
                                                     code:0
                                                 userInfo:@{ COParallelOperationErrorsKey : errors }];

                [self rejectWithError:error];
            }
        }
    });
}

- (void)cancel {
    [super cancel];

    [self.operations makeObjectsPerformSelector:@selector(cancel)];
}

@end
