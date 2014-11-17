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

        [operation start];
    }
}

- (void)cancel {
    [self.operations makeObjectsPerformSelector:@selector(cancel)];

    [super cancel];
}

- (void)operationDidFinish:(NSOperation <COOperation> *)operation {
    if (operation.isCancelled) {
        [self cancel];

    }

    NSIndexSet *areThereUnfinishedOperations = [self.operations indexesOfObjectsPassingTest:^BOOL(NSOperation <COOperation> *operation, NSUInteger idx, BOOL *stop) {
        return operation.isFinished == NO;
    }];

    if (areThereUnfinishedOperations.count == 0) {
        NSMutableArray *results = [NSMutableArray new];
        NSMutableArray *errors  = [NSMutableArray new];

        __block BOOL atLeastOneErrorExists = NO;
        [self.operations enumerateObjectsUsingBlock:^(NSOperation <COOperation> *operation, NSUInteger idx, BOOL *stop) {
            if (atLeastOneErrorExists == NO && operation.result) {
                results[idx] = operation.result;
            }

            else if (operation.error) {
                atLeastOneErrorExists = YES;

                [errors addObject:operation.error];
            }
        }];

        if (atLeastOneErrorExists == NO) {
            [self finishWithResult:results];
        } else {
            NSError *error = [NSError errorWithDomain:@"com.compositeoperations.parallelcompositeoperation"
                                                 code:0
                                             userInfo:@{ @"errors": errors }];

            [self rejectWithError:error];
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
