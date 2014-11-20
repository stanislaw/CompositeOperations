//
// CompositeOperations
//
// CompositeOperations/COCompositeOperations.h
//
// Copyright (c) 2014 Stanislaw Pankevich
// Released under the MIT license
//

#import "COParallelCompositeOperation.h"
#import "COOperation_Private.h"

@interface COParallelCompositeOperation ()

@property (readonly, nonatomic) NSArray *operations;

@end

@implementation COParallelCompositeOperation

- (id)initWithOperations:(NSArray *)operations {
    NSParameterAssert(operations);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _operations         = operations;

    return self;
}

- (void)main {
    dispatch_group_t group = dispatch_group_create();

    COParallelCompositeOperation *weakSelf = self;

    for (NSOperation <COOperation> *operation in self.operations) {
        NSOperation <COOperation> *weakOperation = operation;
        operation.completionBlock = ^{
            if (weakOperation.isCancelled) {
                [weakSelf.operations makeObjectsPerformSelector:@selector(cancel)];

                [weakSelf cancel];
            }

            dispatch_group_leave(group);
        };

        dispatch_group_enter(group);

        dispatch_async(dispatch_get_main_queue(), ^{
            [operation start];
        });
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (self.isCancelled == NO) {
            NSMutableArray *results = [NSMutableArray new];

            [self.operations enumerateObjectsUsingBlock:^(NSOperation <COOperation> *operation, NSUInteger idx, BOOL *stop) {
                results[idx] = operation.result;
            }];

            [self finishWithResult:results];
        } else {
            NSMutableArray *errors  = [NSMutableArray new];

            [self.operations enumerateObjectsUsingBlock:^(NSOperation <COOperation> *operation, NSUInteger idx, BOOL *stop) {
                if (operation.error) {
                    [errors addObject:operation.error];
                }
            }];

            if (errors.count > 0) {
                NSError *error = [NSError errorWithDomain:@"com.CompositeOperations.COParallelCompositeOperation"
                                                     code:0
                                                 userInfo:@{ @"errors": errors }];
                
                [self rejectWithError:error];
            } else {
                [self reject];
            }
        }
    });
}

@end
