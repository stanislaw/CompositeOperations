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

- (void)operationDidFinish:(NSOperation <COOperation> *)operation;

@end

@implementation COParallelCompositeOperation

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
    for (NSOperation <COOperation> *operation in self.operations) {
        [operation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:NULL];

        dispatch_async(dispatch_get_main_queue(), ^{
            [operation start];
        });
    }
}

- (void)operationDidFinish:(NSOperation <COOperation> *)operation {
    if (operation.isCancelled) {
        [self.operations makeObjectsPerformSelector:@selector(cancel)];
    }

    NSIndexSet *areThereUnfinishedOperations = [self.operations indexesOfObjectsPassingTest:^BOOL(NSOperation <COOperation> *operation, NSUInteger idx, BOOL *stop) {
        return operation.isFinished == NO;
    }];

    // TODO: work out reentrace after all operations are cancelled but still continue being finished
    if (areThereUnfinishedOperations.count == 0 && self.isFinished == NO) {
        NSMutableArray *results = [NSMutableArray new];
        NSMutableArray *errors  = [NSMutableArray new];

        __block BOOL atLeastOneNotSuccessfulOperationExists = NO;
        [self.operations enumerateObjectsUsingBlock:^(NSOperation <COOperation> *operation, NSUInteger idx, BOOL *stop) {
            if (atLeastOneNotSuccessfulOperationExists == NO && operation.result) {
                results[idx] = operation.result;
            }

            else if (operation.error) {
                atLeastOneNotSuccessfulOperationExists = YES;

                [errors addObject:operation.error];
            }

            else if (operation.isCancelled) {
                atLeastOneNotSuccessfulOperationExists = YES;
            }
        }];

        if (atLeastOneNotSuccessfulOperationExists == NO) {
            [self finishWithResult:results];
        } else {
            if (errors.count > 0) {
                NSError *error = [NSError errorWithDomain:@"com.compositeoperations.parallelcompositeoperation"
                                                     code:0
                                                 userInfo:@{ @"errors": errors }];

                [self rejectWithError:error];
            } else {
                [self reject];
            }
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    BOOL finished = [[change valueForKey:NSKeyValueChangeNewKey] boolValue];

    if (finished) {
        [self operationDidFinish:object];

        [object removeObserver:self forKeyPath:keyPath];
    }
}

@end
