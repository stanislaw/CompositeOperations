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
@property (assign, nonatomic) NSUInteger finishedOperations;

- (void)operationDidFinish:(NSOperation <COOperation> *)operation;

@end

@implementation COParallelCompositeOperation

- (id)initWithOperations:(NSArray *)operations {
    NSParameterAssert(operations);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    _operations         = operations;
    _finishedOperations = 0;

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
    _finishedOperations++;

    if (operation.isCancelled) {
        [self.operations makeObjectsPerformSelector:@selector(cancel)];

        [self cancel];
    }

    if (_finishedOperations < self.operations.count) {
        return;
    }

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
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    BOOL finished = [[change valueForKey:NSKeyValueChangeNewKey] boolValue];

    if (finished) {
        [object removeObserver:self forKeyPath:keyPath];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self operationDidFinish:object];
        });
    }
}

@end
