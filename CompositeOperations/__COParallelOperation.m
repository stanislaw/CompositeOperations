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

@property (readonly, nonatomic) NSOperationQueue *operationQueue;
@property (readonly, nonatomic) NSArray <NSOperation <COOperation> *> *operations;

- (void)cancelAllOperations;
- (void)reject;

@end

@implementation __COParallelOperation

#pragma mark - __COParallelOperation

- (id)initWithOperations:(nonnull NSArray <NSOperation <COOperation> *> *)operations
          operationQueue:(nonnull NSOperationQueue *)operationQueue {
    NSParameterAssert(operationQueue);

    self = [super init];

    if (self == nil) return nil;

    _operationQueue = operationQueue;
    _operations = operations;

    return self;
}

- (id)initWithOperations:(nonnull NSArray <NSOperation <COOperation> *> *)operations {
    NSParameterAssert(operations);

    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    operationQueue.maxConcurrentOperationCount = 4;

    self = [self initWithOperations:operations operationQueue:operationQueue];

    if (self == nil) return nil;

    _operations = operations;

    return self;
}

- (void)finishWithResult:(nonnull id)result {
    NSParameterAssert(result);

    if (self.isCancelled == NO) {
        self.result = result;
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

        __block __COParallelOperation *weakSelf = self;
        __block NSOperation <COOperation> *weakOperation = operation;

        operation.completionBlock = ^{
            if (weakOperation.result == nil) {
                [weakSelf cancelAllOperations];
            }
            if (!weakOperation.hasLeftGroup) {
              weakOperation.hasLeftGroup = YES;
              dispatch_group_leave(group);
            }
        };
    }

    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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

    [self.operationQueue addOperations:self.operations waitUntilFinished:NO];
}

#pragma mark - NSObject

- (NSString *)debugDescription {
    NSMutableArray *descriptionComponents = [NSMutableArray array];

    [descriptionComponents addObject:[NSString stringWithFormat:@"name = %@; state = %@; isCancelled = %@; operations = %@; result = %@; error = %@", self.name, COKeyPathFromOperationState(self.state), self.isCancelled ? @"YES" : @"NO", self.operations, self.result, self.error]];

    NSString *description = [NSString stringWithFormat:@"<%@: %p (%@)>", NSStringFromClass([self class]), self, [descriptionComponents componentsJoinedByString:@"; "]];

    return description;
}

@end
